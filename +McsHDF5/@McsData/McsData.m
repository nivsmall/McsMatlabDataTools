classdef McsData < handle
    % McsData Read and store the contents of a HDF5 file generated by MCS software.
    % Holds a cell array of the recordings present in the file.
    % Read a HDF5 file:
    %
    %     data = McsData('Name_of_HDF5_file.h5');
    %
    % Plot the individual streams contained in the file:
    %
    %     plot(data,[]);
    %
    % See help McsData.plot for more information
    %
    % (c) 2016 by Multi Channel Systems MCS GmbH

    properties (SetAccess = private)
        FileName        % (string) Name of the loaded file
        McsHdf5Version  % (scalar) Version of the Mcs HDF5 protocol that created the file
        McsHdf5Type     % (string) Type of the Mcs HDF5 file
        Data            % (struct) Information about the file
        Recording = {}; % (cell array) McsRecording objects, one for each recording in the file
    end
    
    methods
        function data = McsData(filename, varargin)
        % Reads a HDF5 file created by MCS software.
        %
        % function data = McsData(filename)
        % function data = McsData(filename, cfg)
        %
        % This command will just read the meta-information in the file, the
        % actual data will be read lazily, i.e. once it is needed (e.g.
        % when plot is called).
        %
        % Input:
        %   filename    -   (string) Name of the HDF5 file
        %   cfg     -   (optional) configuration structure, contains one or
        %               more of the following fields:
        %               'dataType': The type of the data, can be one of
        %               'double' (default), 'single' or 'raw'. For 'double'
        %               and 'single' the data is converted to meaningful
        %               units, while for 'raw' no conversion is done and
        %               the data is kept in ADC units. This uses less
        %               memory than the conversion to double, but you might
        %               have to convert the data prior to analysis, for
        %               example by using the getConvertedData function.
        %               'timeStampDataType': The type of the time stamps,
        %               can be either 'int64' (default) or 'double'. Using
        %               'double' is useful for older Matlab version without
        %               int64 arithmetic.
        %               'readUnknown': For CMOS-MEA data files, this 
        %               decides, whether data sources with unknown type are 
        %               read in. Default is false
        %
        % Output:
        %   data        -   A McsData object
            if exist('h5info')
                mode = 'h5';
            else
                mode = 'hdf5';
            end
            if strcmp(mode,'h5') 
                inf = h5info(filename);
            else 
                if ~isempty(regexp(filename, '.cmtr$','match'))
                    warning('CMOS-MEA Results files might need a newer Matlab version!');
                end
                inf = hdf5info(filename);
                inf = inf.GroupHierarchy;
            end
            data.FileName = inf.Filename;

            [validFile, type, message, version] = McsHDF5.McsData.CheckIsValidFile(inf.Attributes, mode);

            if ~validFile
                error(['This is not a valid Mcs HDF5 file: ' message ' Please see \n\n'...
                    '\thttp://www.multichannelsystems.com/software/multi-channel-datamanager \n\n' ...
                    ' for an update of the HDF5 Matlab Tools.']);
            end
            
            data.McsHdf5Version = version;
            data.McsHdf5Type = type;
            
            if isempty(varargin)
                cfg = [];
            else
                cfg = varargin{:};
            end
            
            if strcmp(type, 'DataManager')
                data = McsHDF5.McsData.ReadDataManager(data, inf, mode, cfg);
            elseif strcmp(type, 'CMOS-MEA')
                data = McsHDF5.McsData.ReadCmosMea(data, inf, mode, cfg);
            end
        end
    end
    
    methods (Static, Access = private)
        function correctOrientation = CheckDataManagerVersion(attributes, mode)
            appName = '';
            appVersion = '';
            correctOrientation = false;
            for att = 1:length(attributes)
                if strcmp(mode, 'hdf5')
                    if strcmp(attributes(att).Name,'/GeneratingApplicationName')
                        appName = attributes(att).Value.Data;
                    elseif strcmp(attributes(att).Name,'/GeneratingApplicationVersion')
                        appVersion = attributes(att).Value.Data;
                    end
                elseif strcmp(mode, 'h5')
                    if strcmp(attributes(att).Name,'GeneratingApplicationName')
                        appName = attributes(att).Value;
                    elseif strcmp(attributes(att).Name,'GeneratingApplicationVersion')
                        appVersion = attributes(att).Value;
                    end
                end
            end
            
            % DataManager versions 1.9.2 and earlier had a bug concerning the
            % orientation of the ConversionFactor array or
            % FrameDataEntities
            if strcmp(appName,'Multi Channel DataManager')
                spl = regexp(appVersion,'\.','split');
                if length(spl) == 4
                    numericVersion = str2double(spl);
                    if numericVersion(1) <= 1 && (numericVersion(2) < 9 || (numericVersion(2) == 9 && numericVersion(3) <= 2))
                        correctOrientation = true;
                    end
                end
            end
        end
        
        function [isValid, type, message, version] = CheckIsValidFile(attributes, mode)
            type = 'Invalid';
            isValid = false;
            message = 'This is not a valid MCS H5 File!';
            version = 0;
            
            for att = 1:length(attributes)
                attribute = attributes(att);
                if McsHDF5.McsH5Helper.AttributeNameEquals(attribute, 'McsHdf5ProtocolType', mode)
                    type = 'DataManager';
                    if ~McsHDF5.McsH5Helper.AttributeIsValid(attribute, @(x)(strcmp(x, 'RawData')), mode)
                        isValid = false;
                        message = 'Only the RawData protocol type is supported!';
                        break;
                    else
                        isValid = true;
                    end
                elseif McsHDF5.McsH5Helper.AttributeNameEquals(attribute, 'McsHdf5ProtocolVersion', mode)
                    type = 'DataManager';
                    if ~McsHDF5.McsH5Helper.AttributeIsValid(attribute, @(x)(x <= 3), mode)
                        isValid = false;
                        message = 'Only MCS HDF5 up to version 3 is supported!';
                        break;
                    else
                        version = attribute.Value;
                    end
                elseif McsHDF5.McsH5Helper.AttributeNameEquals(attribute, 'McsHdf5Version', mode)
                    type = 'DataManager';
                    if ~McsHDF5.McsH5Helper.AttributeIsValid(attribute, @(x)(x == 1), mode)
                        isValid = false;
                        message = 'Only MCS HDF5 up to version 3 is supported!';
                        break;
                    else
                        isValid = true;
                        version = attribute.Value;
                    end
                elseif McsHDF5.McsH5Helper.AttributeNameEquals(attribute, 'ID.Type', mode)
                    type = 'CMOS-MEA';
                    if ~McsHDF5.McsH5Helper.AttributeIsValid(attribute, @(x)(strcmp(x, 'McsData')), mode)
                        isValid = false;
                        message = 'Only the MCSData is valid as type!';
                        break;
                    else
                        isValid = true;
                    end
                elseif McsHDF5.McsH5Helper.AttributeNameEquals(attribute, 'FileVersion', mode)
                    type = 'CMOS-MEA';
                    if ~McsHDF5.McsH5Helper.AttributeIsValid(attribute, @(x)(x == 1), mode)
                        isValid = false;
                        message = 'Only MCS HDF5 up to version 1 is supported for CMOS-MEA files!';
                        break;
                    else
                        isValid = true;
                        version = attribute.Value;
                    end
                end
            end
            
            if isValid
                message = 'File is valid!';
            end
        end
        
        function data = ReadDataManager(data, inf, mode, cfg)
            % Data structure
            dataAttributes = inf.Groups.Attributes;
            for fni = 1:length(dataAttributes)
                if strcmp(mode,'h5')
                    data.Data.(dataAttributes(fni).Name) = dataAttributes(fni).Value;
                elseif strcmp(mode,'hdf5')
                    str = regexp(dataAttributes(fni).Name,'/\w+$','match');
                    if isa(dataAttributes(fni).Value,'hdf5.h5string')
                        data.Data.(str{length(str)}(2:end)) = dataAttributes(fni).Value.Data;
                    else
                        data.Data.(str{length(str)}(2:end)) = dataAttributes(fni).Value;
                    end
                end
            end

            cfg.correctConversionFactorOrientation = McsHDF5.McsData.CheckDataManagerVersion(inf.Attributes, mode);

            % Recordings
            for recs = 1:length(inf.Groups.Groups)
                if isempty(inf.Groups.Groups(recs))
                    continue
                end
                data.Recording{recs} = McsHDF5.McsRecording(data.FileName, inf.Groups.Groups(recs), cfg);
            end
        end
        
        function data = ReadCmosMea(data, inf, mode, cfg)
            % Data structure
            dataAttributes = inf.Attributes;
            for fni = 1:length(dataAttributes)
                [name, value] = McsHDF5.McsH5Helper.AttributeNameValueForStruct(dataAttributes(fni), mode);
                data.Data.(name) = value;
            end
            data.Recording{1} = McsHDF5.McsCmosRecording(data.FileName, inf, cfg);
        end
    end
    
end
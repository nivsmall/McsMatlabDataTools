classdef McsCmosFilterSource < handle
% Holds the contents of a CMOS-MEA filter source
%
% The filters in the filter pipeline are stored in the Pipeline field
%
% (c) 2017 by Multi Channel Systems MCS GmbH
    properties (SetAccess = private)
        Pipeline = {};  % (cell array) The filters in the pipeline
        Settings = [];  % (struct) The filter tool settings
        Label           % (string) The name of the filter tool
        Info = [];      % (struct) The attributes of the filter source
    end
    
    methods 
        function str = McsCmosFilterSource(filename, strStruct, varargin)
        % Constructs and reads a filter source from a CMOS-MEA file
        %
        % function str = McsCmosFilterSource(filename, strStruct, varargin)
        %
        % Input:
        %   filename        -   (string) Name of the HDF5 file
        %   strStruct       -   (struct) The HDF5 subtree of the filter
        %                       source, generated by the h5info command
            if exist('h5info')
                mode = 'h5';
            else
                mode = 'hdf5';
            end
            
            str.Label = McsHDF5.McsH5Helper.GetFromAttributes(strStruct, 'ID.Instance', mode);
            if isfield(strStruct,'Attributes')
                dataAttributes = strStruct.Attributes;
                m = metaclass(str); % need to check whether the attribute is part of the class Properties
                propNames = {m.PropertyList.Name};
                for fni = 1:length(dataAttributes)
                    [name, value] = McsHDF5.McsH5Helper.AttributeNameValueForStruct(dataAttributes(fni), mode);
                    if any(arrayfun(@(x)(strcmp(x, name)), propNames))
                        str.(name) = value;
                    else
                        str.Info.(name) = value;
                    end
                end
            end
            
            str.Pipeline = McsHDF5.McsCmosFilterSource.ReadPipeline(filename, strStruct, mode);
            str.Settings = McsHDF5.McsCmosFilterSource.ReadSettings(filename, strStruct, mode);
        end
    end
    
    methods (Static, Access = private)
        function pipe = ReadPipeline(filename, strStruct, mode)
            pipeID = 'c632506d-c961-4a9f-b22b-ac7a56ce3552';
            pipe = {};
            pipeGroup = [];
            for gi = 1:length(strStruct.Groups)
                type = McsHDF5.McsH5Helper.GetFromAttributes(strStruct.Groups(gi), 'ID.TypeID', mode);
                if strcmpi(pipeID, type)
                    pipeGroup = strStruct.Groups(gi);
                    break;
                end
            end
            if ~isempty(pipeGroup)
                for di = 1:length(pipeGroup.Datasets)
                    inf = McsHDF5.McsH5Helper.ReadCompoundDataset(filename, [pipeGroup.Name '/' pipeGroup.Datasets(di).Name], mode);
                    name = McsHDF5.McsH5Helper.GetFromAttributes(pipeGroup.Datasets(di), 'ID.Instance', mode);
                    inf.Name = name;
                    filterType = McsHDF5.McsH5Helper.GetFromAttributes(pipeGroup.Datasets(di), 'ID.Type', mode);
                    inf.Type = filterType;
                    pipe = [pipe {inf}];
                end
            end
        end
        
        function set = ReadSettings(filename, strStruct, mode)
            setID = 'b181ceed-337d-4bda-99ec-e7e624cf49d0';
            set = [];
            for di = 1:length(strStruct.Datasets)
                type = McsHDF5.McsH5Helper.GetFromAttributes(strStruct.Datasets(di), 'ID.TypeID', mode);
                if strcmpi(setID, type)
                    set = McsHDF5.McsH5Helper.ReadCompoundDataset(filename, [strStruct.Name '/' strStruct.Datasets(di).Name], mode);
                end
            end
        end
    end
end
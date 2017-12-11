classdef McsCmosSpikeSorterSource < handle
% Holds the contents of a SpikeSorter source in a CMOS-MEA file
%
% Important fields:
%   UnitEntities        -   (cell array) List of McsCmosSpikeSorterUnit
%                           objects, one for each sorted unit in the data
%                           source. Holds the details of the units
%   UnitInfos           -   (struct) Contains meta information about each
%                           unit
%   ProjectionMatrix    -   (Embedding x Units x Channels) Matrix that
%                           contains the projection from raw data to the
%                           unit source signals.
%   Settings            -   (struct) Contains the spike sorter settings
%
% (c) 2017 by Multi Channel Systems MCS GmbH
    properties (SetAccess = private)
        UnitEntities = {};  % (cell array) McsCmosSpikeSorterUnit objects, one per sorted unit
        UnitInfos           % (struct) Meta data and quality measures for each unit
        ProjectionMatrix    % Matrix describing the projection from raw data to unit source signals
        ProjectionMatrixDimensions = 'Embedding x Units x Channels'; % (string) The dimensions of the projection matrix
        Label               % (string) The name of the spike sorter
        Info                % (struct) The spike sorter attributes
        Settings = []; % (struct) Contains the spike sorter settings datasets, each as a field
    end
    
    properties (Access = private)
        StructInfo
        FileName
    end
    
    methods
        function str = McsCmosSpikeSorterSource(filename, strStruct, varargin)
        % Constructs a spike sorter data source object
        %
        % function str = McsCmosSpikeSorterSource(filename, strStruct, varargin)
        %
        % Calls the constructors for the individual McsCmosSpikeSorterUnit
        % objects. The contents from the individual McsCmosSpikeSorterUnit
        % is not read directly from the file, but only once the Unit is
        % actually accessed.
        %
        % Input:
        %   filename        -   (string) Name of the HDF5 file
        %   strStruct       -   (struct) The HDF5 tree structure of the spike
        %                       sorter source, generated by the h5info
        %                       command
        
            if exist('h5info')
                mode = 'h5';
            else
                mode = 'hdf5';
            end
            
            str.Label = McsHDF5.McsH5Helper.GetFromAttributes(strStruct, 'ID.Instance', mode);
            
            str.Info = McsHDF5.McsH5Helper.ReadInfoFromAttributes(strStruct, mode);
            str.Settings = McsHDF5.McsCmosSpikeSorterSource.ReadSettingsDatasets(filename, strStruct, mode);
            str.UnitInfos = McsHDF5.McsCmosSpikeSorterSource.ReadUnitInfos(filename, strStruct, mode);
            str.ProjectionMatrix = McsHDF5.McsCmosSpikeSorterSource.ReadProjectionMatrix(filename, strStruct, mode);
            str.UnitEntities = McsHDF5.McsCmosSpikeSorterSource.ReadUnits(filename, strStruct, mode, varargin{:});
            
            str.StructInfo = strStruct;
            str.FileName = filename;
        end
    end
    
    methods (Static, Access = private)
        function set = ReadSettingsDatasets(filename, strStruct, mode)
            
            settingsTypes = {'3533aded-b369-4529-836d-9629eb1a27a8', ...
                'f20b653e-25fb-4f7a-ae8a-f35044f46720', ...
                'c7d23018-9006-45fe-942f-c5d0f9cde284', ...
                '713a9202-87e1-4bfe-ba80-b909a000aae5', ...
                '62bc7b9f-7eea-4a88-a438-c618067d49f4'};
            set = McsHDF5.McsH5Helper.ReadDatasetsToStruct(filename, strStruct, mode, settingsTypes);
        end
        
        function unitInfos = ReadUnitInfos(filename, strStruct, mode)
            unitType = '7cffd022-c99e-42c2-b9f7-f79be7b4dfe6';
            unitInfos = [];
            for di = 1:length(strStruct.Datasets)
                type = McsHDF5.McsH5Helper.GetFromAttributes(strStruct.Datasets(di), 'ID.TypeID', mode);
                if strcmpi(type, unitType)
                    inf = McsHDF5.McsH5Helper.ReadCompoundDataset(filename, [strStruct.Name '/' strStruct.Datasets(di).Name], mode);
                
                    fn = fieldnames(inf);
                    for fni = 1:length(fn)
                        fname = strrep(fn{fni}, '0x2E', '');
                        unitInfos.(fname) = inf.(fn{fni});
                        if verLessThan('matlab','7.11') && strcmp(class(inf.(fn{fni})),'int64')
                            unitInfos.(fname) = double(unitInfos.(fname));
                        end
                    end
                end
            end
        end
        
        function projmat = ReadProjectionMatrix(filename, strStruct, mode)
            matType = '3fa908a3-fac9-4a80-96a1-310d9bcdf617';
            for di = 1:length(strStruct.Datasets)
                type = McsHDF5.McsH5Helper.GetFromAttributes(strStruct.Datasets(di), 'ID.TypeID', mode);
                if strcmpi(type, matType)
                    if strcmp(mode, 'h5')
                        projmat = h5read(filename, [strStruct.Name '/Projection Matrix']);
                    elseif strcmp(mode, 'hdf5')
                        projmat = hdf5read(filename, [strStruct.Name '/Projection Matrix']);
                    end
                    projmat = permute(projmat,[3,2,1]);
                end
            end
        end
        
        function units = ReadUnits(filename, strStruct, mode, varargin)
            units = {};
            unitType = '0e5a97df-9de0-4a22-ab8c-54845c1ff3b9';
            for gi = 1:length(strStruct.Groups)
                type = McsHDF5.McsH5Helper.GetFromAttributes(strStruct.Groups(gi), 'ID.TypeID', mode);
                if strcmpi(type, unitType)
                    unit = McsHDF5.McsCmosSpikeSorterUnit(filename, strStruct.Groups(gi), varargin{:});
                    units = [units {unit}];
                end
            end
        end
    end
end
classdef McsRecording
% Stores a single recording.
%
% The different streams present in the recording are sorted into the
% {Analog,Frame,Event,Segment}Stream fields where they are stored as cell
% arrays.
    
    properties
        RecordingID = 0
        RecordingType
        TimeStamp
        Duration
        Label
        Comment
        AnalogStream = {};
        FrameStream = {};
        EventStream = {};
        SegmentStream = {};
    end
    
    methods
        
        function rec = McsRecording(filename, recStruct, varargin)
        % Reads a single recording inside a HDF5 file.
        %
        % function rec = McsRecording(filename, recStruct)
        % function rec = McsRecording(filename, recStruct, cfg)
        %
        % Input:
        %   filename    -   (string) Name of the HDF5 file
        %   recStruct   -   The recording subtree of the structure 
        %                   generated by the h5info command
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
        %
        % Output:
        %   rec         -   A McsRecording object
        %
        
            dataAttributes = recStruct.Attributes;
            for fni = 1:length(dataAttributes)
                rec.(dataAttributes(fni).Name) = dataAttributes(fni).Value;
            end

            for gidx = 1:length(recStruct.Groups)
                groupname = recStruct.Groups(gidx).Name;
                
                if ~isempty(strfind(groupname,'AnalogStream'))
                    % read analog streams
                    for streams = 1:length(recStruct.Groups(gidx).Groups)
                        if isempty(varargin)
                            rec.AnalogStream{streams} = McsHDF5.McsAnalogStream(filename, recStruct.Groups(gidx).Groups(streams));
                        else
                            rec.AnalogStream{streams} = McsHDF5.McsAnalogStream(filename, recStruct.Groups(gidx).Groups(streams), varargin{:});
                        end
                    end
                    
                elseif ~isempty(strfind(groupname,'FrameStream'))
                    % read frame streams
                    for streams = 1:length(recStruct.Groups(gidx).Groups)
                        if isempty(varargin)
                            rec.FrameStream{streams} = McsHDF5.McsFrameStream(filename, recStruct.Groups(gidx).Groups(streams));
                        else
                            rec.FrameStream{streams} = McsHDF5.McsFrameStream(filename, recStruct.Groups(gidx).Groups(streams), varargin{:});
                        end
                    end
                    
                elseif ~isempty(strfind(groupname,'EventStream'))
                    % read event streams
                    for streams = 1:length(recStruct.Groups(gidx).Groups)
                        if isempty(varargin)
                            rec.EventStream{streams} = McsHDF5.McsEventStream(filename, recStruct.Groups(gidx).Groups(streams));
                        else
                            rec.EventStream{streams} = McsHDF5.McsEventStream(filename, recStruct.Groups(gidx).Groups(streams), varargin{:});
                        end
                    end
                    
                elseif ~isempty(strfind(groupname,'SegmentStream'))
                    % read segment streams
                    for streams = 1:length(recStruct.Groups(gidx).Groups)
                        if isempty(varargin)
                            rec.SegmentStream{streams} = McsHDF5.McsSegmentStream(filename, recStruct.Groups(gidx).Groups(streams));
                        else
                            rec.SegmentStream{streams} = McsHDF5.McsSegmentStream(filename, recStruct.Groups(gidx).Groups(streams), varargin{:});
                        end
                    end
                end 
                
            end
            
            
        end
        
    end
    
end
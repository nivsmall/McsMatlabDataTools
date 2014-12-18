function plot(md,cfg,varargin)
% Function to plot the contents of a McsData object.
%
% function plot(md,cfg,varargin)
%
% Input:
%
%   md      -   A McsData object
%
%   cfg     -   Either empty (for default parameters) or a structure with
%               (some of) the following fields:
%               'recordings': empty for all recordings, otherwise a vector
%                   with indices of recordings (default: all)
%               'conf': Configuration structure for McsRecording.plot:
%                   []: default parameters
%                   single config struct: replicated for all recordings
%                   cell array of config structs: each cell contains a
%                   config struct for a specific recording.
%                   See help McsRecording.plot for details on the config
%                   structure
%               If fields are missing, their default values are used.
%
%   Optional inputs in varargin are passed to the plot functions. Warning: 
%   might produce error if segments / frames are mixed with analog streams.
    
    cfg = McsHDF5.checkParameter(cfg, 'recordings', 1:length(data.Recording));
    [cfg,isDefault] = McsHDF5.checkParameter(cfg, 'conf', repmat({[]},1,length(cfg.recordings)));
    if ~isDefault
        if ~iscell(cfg.conf)
            cfg.conf = repmat({cfg.conf},1,length(cfg.recordings));
        end
    end
    
    for reci = 1:length(cfg.recordings)
        id = cfg.recordings(reci);
        plot(md.Recording{id},cfg.conf{id},varargin{:});
    end

end
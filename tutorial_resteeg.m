
% set path for toolboxes 
if isempty(which('eeglab'))
    addpath('C:\Users\shawn\Desktop\RESTEEG\happe\Packages\eeglab14_0_0b');
    eeglab; close
end

% required plugin:
%   data import plugin (depends on data format)
%   clean_rawdata, clean_line


%% ------------------------------------------------------------------------
%            Set up configuration of the processing pipeline
% -------------------------------------------------------------------------

CONFIG.filepath = 'C:\Users\shawn\Desktop\RESTEEG\data\Singh_Shu\R61_14';
CONFIG.filename = 'R61_14_Baseline_EO';
CONFIG.fileformat = 'bdf';

CONFIG.chan_to_rm = {'ExG 1','ExG 2','ACC0','ACC1','ACC2','Packet Counter'};
CONFIG.chanlocs = 'C:\Users\shawn\Desktop\RESTEEG\data\chanlocs\chanlocs_quick30.mat';


CONFIG.SAVESET = 0;
CONFIG.VIS_CLEAN = 1;
CONFIG.DO_INTERP_BADCHAN = 0;
CONFIG.DO_RMBADCHAN_REJCHAN = 1;        % remove bad channel using pop_rejchan
CONFIG.DO_RMBADCHAN_CLEANRAW = 1;       % remove bad channel using clean_rawdata

CONFIG.double_precision = 1;            % use double precision (e.g. avoid round-off errors in runica)
CONFIG.resample_rate = 500;             % resampling rate in Hz
CONFIG.filter_hp_cutoff = 1.0;    % Hz
CONFIG.filter_lp_cutoff = [];

CONFIG.reref_choice = 'average'; 

% bad channel removal criteria (using clean_rawdata)
CONFIG.rmchan_flatline = 5;     % Maximum tolerated flatline duration. In seconds. If a channel has a longer
                                % flatline than this, it will be considered abnormal. Default: 5
CONFIG.rmchan_mincorr = 0.85;   % Minimum channel correlation. If a channel is correlated at less than this
                                % value to a reconstruction of it based on other channels, it is considered
                                % abnormal in the given time window. This method requires that channel
                                % locations are available and roughly correct; otherwise a fallback criterion
                                % will be used. (default: 0.85)
CONFIG.rmchan_linenoise = 4;    % If a channel has more line noise relative to its signal than this value, in
                                % standard deviations based on the total channel population, it is considered
                                % abnormal. (default: 4)
                                
CONFIG.asr_stdcutoff = 20;      % Standard deviation cutoff for removal of bursts (via ASR)

                                
% run automated analysis of resting-state eeg
resteeg(CONFIG)
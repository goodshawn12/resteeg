
% required EEGLAB and EEGLAB plugins:
%   - Data Import --> Biosig (depends on data format)
%   - Data Processing --> clean_rawdata
%   - Data Processing --> clean_line
%   - Data Processing --> ICLabel
%   - Data Processing --> view_props

% define folder path
path_eeglab = 'C:\Users\shawn\Desktop\RESTEEG\happe\Packages\eeglab14_0_0b\';
path_resteeg = 'C:\Users\shawn\Desktop\RESTEEG\resteeg\';
path_datafolder = 'C:\Users\shawn\Desktop\RESTEEG\data\Singh_Shu\R61_15\';
path_chanlocs = [path_resteeg 'chanlocs\chanlocs_quick30.mat'];

file_format = 'bdf';
file_list = {};

% set path for toolboxes
if isempty(which('eeglab'))
    addpath(path_eeglab);
    eeglab; close
end

cd(path_resteeg);
addpath(genpath('./'))


%% ------------------------------------------------------------------------
%            Define data path and file name
% -------------------------------------------------------------------------

% manually select datasets if not defined
if isempty(file_list)
    if ~isempty(path_datafolder)
        [file_list,path_datafolder] = uigetfile([path_datafolder '*.', file_format],'Select One or More Files','MultiSelect', 'on');
    else
        [file_list,path_datafolder] = uigetfile(['*.', file_format],'Select One or More Files','MultiSelect', 'on');
    end
end
    
% remove file extension in the file name
CONFIG.filename_list = cell(1,length(file_list));
for file_id = 1:length(file_list)
    [~,CONFIG.filename_list{file_id},~] = fileparts(file_list{file_id});
end

CONFIG.filepath = path_datafolder;
CONFIG.fileformat = file_format;
CONFIG.chan_to_rm = {'ExG 1','ExG 2','Packet Counter','ExG 1','ExG 2', ...
    'ACC0','ACC1','ACC2','ACC30','ACC31','ACC32','ACC33','ACC34'};
CONFIG.chanlocs = path_chanlocs;
CONFIG.chanlocs_template = [];


%% ------------------------------------------------------------------------
%            Set up configuration of the processing pipeline
% -------------------------------------------------------------------------

% data import setting
CONFIG.FORCE_RUN_IMPORT = 0;                  % run data import pipeline and overwrite previous imported data
CONFIG.FORCE_RUN_PREPROC = 0;                 % run preprocessing pipeline and overwrite previous preprocessed data
CONFIG.HANDLE_SPECIAL_CASE = 0;

CONFIG.SAVESET = 1;
CONFIG.double_precision = 1;            % use double precision (e.g. avoid round-off errors in runica)

% setting: generate report        
CONFIG.EXPORT_REPORT = 1;
CONFIG.GEN_FIGURES = 1;
CONFIG.VIS_CLEAN = 0;

% basic preprocessing setting
CONFIG.resample_rate = [];             % resampling rate in Hz
CONFIG.filter_hp_cutoff = 1.0;      % Hz
CONFIG.filter_lp_cutoff = 55;       % Hz
CONFIG.DO_INTERP_BADCHAN = 1;
CONFIG.DO_RMBADCHAN_REJCHAN = 1;        % remove bad channel using pop_rejchan
CONFIG.DO_RMBADCHAN_CLEANRAW = 1;       % remove bad channel using clean_rawdata
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

% advanced cleaning setting
CONFIG.asr_stdcutoff = 20;      % Standard deviation cutoff for removal of bursts (via ASR)
CONFIG.ICrej_thres = 0.5;       % reject artifact components when ICLabel classifies them as 
                                % muscle, eye, heart, line noise, and channel noise 
                                % with probability > threshold
               
                                
%% run automated analysis of resting-state eeg

for file_id = 1:length(CONFIG.filename_list)
    
    CONFIG.filename = CONFIG.filename_list{file_id};
    CONFIG.filename_prep = [CONFIG.filename '_prep'];
    CONFIG.report.directory = [CONFIG.filepath CONFIG.filename '_report'];
    
    % run resteeg
    CONFIG = resteeg(CONFIG);
end


% %% generate cross-subjects report
% filepath = 'C:\Users\shawn\Desktop\RESTEEG\data\Singh_Shu\R61_14';
% filename = 'R61_14_EC';
% folder_list = { ...
%     'R61_14_Baseline_EC_report', ...
%     'R61_14_4week_EC_report', ...
%     'R61_14_8week_EC_report', ...
%     'R61_14_12week_EC_report', ...
%     'R61_14_16week_EC_report'};
% 
% gen_report_cross_subjects(filepath,filename,folder_list);

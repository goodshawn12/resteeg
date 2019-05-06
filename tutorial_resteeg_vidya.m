
% required EEGLAB and EEGLAB plugins:
%   - Data Import --> Biosig (depends on data format)
%   - Data Processing --> clean_rawdata
%   - Data Processing --> clean_line
%   - Data Processing --> ICLabel
%   - Data Processing --> view_props

% define folder path
path_eeglab = uigetdir(pwd, 'Please select your EEGLAB folder');
path_resteeg = uigetdir(pwd, 'Please select the RESTEEG toolbox folder');
path_chanlocs = [path_resteeg filesep 'chanlocs\chanlocs_nihonkohden.mat'];

% set path for toolboxes
if isempty(which('eeglab'))
    addpath(path_eeglab);
    eeglab; close
end

cd(path_resteeg);
addpath('functions')
addpath('chanlocs')

%% ------------------------------------------------------------------------
%            Define data path and file name
% -------------------------------------------------------------------------
path_datafolder = [];
file_format = 'set';
file_list = {};

% manually select datasets if not defined
if isempty(file_list) || isempty(path_datafolder)
    [file_list,path_datafolder] = uigetfile(['*.' file_format],'Select One or More Files','MultiSelect', 'on');
end

%% ------------------------------------------------------------------------
%            User defined settings
% -------------------------------------------------------------------------

% manually define labels of (non-EEG) channels to be moved
CONFIG.chan_to_rm = {};

% manually define data segments to be processed
CONFIG.time_window = [25845,29626];  % in sec

% setting: data import 
CONFIG.FORCE_RUN_IMPORT = 0;                  % run data import pipeline and overwrite previous imported data
CONFIG.FORCE_RUN_PREPROC = 0;                 % run preprocessing pipeline and overwrite previous preprocessed data
CONFIG.HANDLE_SPECIAL_CASE = 0;

CONFIG.SAVESET = 1;
CONFIG.double_precision = 1;            % use double precision (e.g. avoid round-off errors in runica)

% setting: generate report
CONFIG.EXPORT_REPORT = 1;
CONFIG.GEN_FIGURES = 1;
CONFIG.VIS_CLEAN = 0;


%% ------------------------------------------------------------------------
%            (optional) Define parameters for processing pipeline
% -------------------------------------------------------------------------

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
CONFIG.rmchan_mincorr = 0.6;    % Minimum channel correlation. If a channel is correlated at less than this
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

%% ------------------------------------------------------------------------
%            Define parameters for generating report
% -------------------------------------------------------------------------

% compute and plot time frequency decomposition
CONFIG.report.timefreq_plot_chan = {'Fz','Cz'};
CONFIG.report.timefreq_window_len = 5;     % sec


%% ------------------------------------------------------------------------
%            Run automated analysis of resting-state eeg
% -------------------------------------------------------------------------

% handle single file situation
if ~iscell(file_list), file_list = {file_list}; end     
    
% remove file extension in the file name
CONFIG.filename_list = cell(1,length(file_list));
for file_id = 1:length(file_list)
    [~,CONFIG.filename_list{file_id},~] = fileparts(file_list{file_id});
end

CONFIG.filepath = path_datafolder;
CONFIG.fileformat = file_format;
CONFIG.chanlocs = path_chanlocs;
CONFIG.chanlocs_template = [];

% run resteeg.m 
fail_id = {};
for file_id = 1:length(CONFIG.filename_list)
    
    CONFIG.filename = CONFIG.filename_list{file_id};
    CONFIG.report.directory = [CONFIG.filepath CONFIG.filename '_report'];
    
    % run resteeg toolbox
    try
        CONFIG = resteeg(CONFIG);
    catch
        fail_id{end+1} = CONFIG.filename;
    end
    
end

disp('The following files were not processed successfully:')
disp(fail_id)

% %% generate cross-subjects report
% gen_report_cross_subjects(filepath,filename,folder_list);



%% ------------------------------------------------------------------------
%            Export desired features to Excel Sheet
% -------------------------------------------------------------------------

% select report folders to be processed
datafolder_list = uigetfile_n_dir;
[feature_out, session_name, feature_name] = export_feature(datafolder_list);

% write to Excel sheet
filename = 'Result_Baseline_Power.xlsx';
export_excel(filename, feature_out, session_name, feature_name);


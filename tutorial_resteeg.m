% required EEGLAB and EEGLAB plugins:
%   - Data Import     --> Fileio
%   - Data Processing --> clean_rawdata
%   - Data Processing --> Cleanline
%   - Data Processing --> ICLabel
%   - Data Processing --> view_props
%   - Data Processing --> Fieldtrip-lite
%   - Data Processing --> dipfit

% define folder path
if ~exist('path_eeglab'), path_eeglab = uigetdir(pwd, 'Please select your EEGLAB folder'); end
if ~exist('path_resteeg'), path_resteeg = uigetdir(pwd, 'Please select the RESTEEG toolbox folder'); end

if path_eeglab == 0, disp('EEGLAB folder is not specified'); clear path_eeglab; return; end
if path_resteeg == 0, disp('RESTEEG folder is not specified'); clear path_resteeg; return; end

path_chanlocs = [path_resteeg filesep 'chanlocs' filesep 'chanlocs_nexus32_21ch.mat'];

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
file_format = 'edf';
file_list = {};

% manually select datasets if not defined
if isempty(file_list) || isempty(path_datafolder)
    [file_list,path_datafolder] = uigetfile(['*.' file_format],'Select One or More Files','MultiSelect', 'on');
end

%% ------------------------------------------------------------------------
%            User defined settings
% -------------------------------------------------------------------------

% manually define labels of (non-EEG) channels to be moved
CONFIG.chan_to_rm = {'ExG 1','ExG 2','Packet Counter','ExG 1','ExG 2'};

% manually define data segments to be processed
CONFIG.time_window = [];  % in sec

% setting: data import 
CONFIG.FORCE_RUN_IMPORT = 0;                  % run data import pipeline and overwrite previous imported data
CONFIG.FORCE_RUN_PREPROC = 0;                 % run preprocessing pipeline and overwrite previous preprocessed data
CONFIG.HANDLE_SPECIAL_CASE = 0;

CONFIG.SAVESET = 1;                 % save as .set (EEGLAB) file
CONFIG.SAVE_EDF = 1;                % save as .edf file 
CONFIG.double_precision = 0;            % use double precision (e.g. avoid round-off errors in runica)
CONFIG.DEBUG = 1;                  % output feature in Excel sheet

% setting: generate report
CONFIG.EXPORT_REPORT = 1;
CONFIG.GEN_FIGURES = 1;
CONFIG.VIS_CLEAN = 0;

% Enable Source Localization - Dipole Fitting
CONFIG.ENABLE_DIPFIT = 1;
CONFIG.COREGISTER = [0 -15 0 0 0 -1.5800 1050 900 1000]; % manual registration required

%% ------------------------------------------------------------------------
%            (optional) Define parameters for processing pipeline
% -------------------------------------------------------------------------

% basic preprocessing setting
CONFIG.resample_rate = [];             % resampling rate in Hz
CONFIG.filter_hp_cutoff = 1.0;      % Hz
CONFIG.filter_lp_cutoff = 50;       % Hz
CONFIG.DO_INTERP_BADCHAN = 1;
CONFIG.DO_RMBADCHAN_REJCHAN = 1;        % remove bad channel using pop_rejchan
CONFIG.DO_RMBADCHAN_CLEANRAW = 1;       % remove bad channel using clean_rawdata
CONFIG.reref_choice = 'average';

% bad channel removal criteria (using clean_rawdata)
CONFIG.rmchan_flatline = 5;     % Maximum tolerated flatline duration. In seconds. If a channel has a longer
                                % flatline than this, it will be considered abnormal. Default: 5
CONFIG.rmchan_mincorr = 0.7;    % Minimum channel correlation. If a channel is correlated at less than this
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
% compute coherence
CONFIG.report.coh_chann_pair = {{'F3','F4'}}; % use cell structure to define multiple channel pairs

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
    CONFIG.filename_prep = [CONFIG.filename '_prep'];
    CONFIG.report.directory = [CONFIG.filepath CONFIG.filename '_report'];
    
    % run resteeg toolbox
    if CONFIG.DEBUG
        CONFIG = resteeg(CONFIG);
    else
        try
            CONFIG = resteeg(CONFIG);
        catch
            fail_id{end+1} = CONFIG.filename;
        end
    end
end

disp('The following files were not processed successfully:')
disp(fail_id)

% %% generate cross-subjects report
% gen_report_cross_subjects(filepath,filename,folder_list);


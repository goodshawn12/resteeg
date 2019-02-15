

% set path for toolboxes 
if isempty(which('eeglab'))
    addpath('C:\Users\shawn\Desktop\RESTEEG\happe\Packages\eeglab14_0_0b');
    eeglab; close
end


% 
CONFIG.SAVESET = 1;


CONFIG.filepath = 'C:\Users\shawn\Desktop\RESTEEG\data\Singh_Shu\R61_14';
CONFIG.filename = 'R61_14_Baseline_EO';

CONFIG.chan_to_rm = {'ExG 1','ExG 2','ACC0','ACC1','ACC2','Packet Counter'};
CONFIG.chanlocs = 'C:\Users\shawn\Desktop\RESTEEG\data\chanlocs\chanlocs_quick30.mat';



CONFIG.filter_hp_cutoff = 1.0;    % Hz
CONFIG.filter_lp_cutoff = [];

% run automated analysis of resting-state eeg
resteeg(CONFIG)
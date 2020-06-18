function [EEG, CONFIG] = prep_import(CONFIG)

%% ------------------------------------------------------------------------
%               Import Data and Obtain Dataset Info
% -------------------------------------------------------------------------

% convert data to EEGLAB (.set) format
[EEG, CONFIG] = import_data(CONFIG);
% remove user-specified (non-EEG) channels
[EEG, CONFIG] = remove_channel(EEG,CONFIG);
% handle dataset specific issues
if CONFIG.HANDLE_SPECIAL_CASE, [EEG, CONFIG] = handle_special_case(EEG, CONFIG); end
% import channel locations
[EEG, CONFIG] = import_chanlocs(EEG,CONFIG);
% select (user-defined) time frame
[EEG, CONFIG] = select_time(EEG,CONFIG);

end


function [EEG, CONFIG] = import_data(CONFIG)

% import EEG data and convert to .set format
if isempty(CONFIG.filepath) || isempty(CONFIG.filename)
    % allow user to select file
    EEG = pop_loadset();
end

if strcmp(CONFIG.fileformat,'bdf') || strcmp(CONFIG.fileformat,'edf') || strcmp(CONFIG.fileformat,'eeg')
    EEG = pop_fileio([CONFIG.filepath CONFIG.filename '.' CONFIG.fileformat]);
    EEG = eeg_checkset( EEG );
elseif strcmp(CONFIG.fileformat,'set')
    EEG = pop_loadset([CONFIG.filepath CONFIG.filename '.' CONFIG.fileformat]);
else
    try 
        EEG = pop_fileio([CONFIG.filepath CONFIG.filename '.' CONFIG.fileformat]);
        EEG = eeg_checkset( EEG );
        return
    catch
        disp('The data format not supported. Please see EEGLAB data import for more info.')
    end
end

% store basic information of raw data
CONFIG.rawinfo.nbchan = EEG.nbchan;
CONFIG.rawinfo.xmax = EEG.xmax;
CONFIG.rawinfo.srate = EEG.srate;
CONFIG.rawinfo.chanlocs_labels = {EEG.chanlocs.labels};

end


function [EEG, CONFIG] = remove_channel(EEG,CONFIG)

% remove user-specified channels
if ~isempty(CONFIG.chan_to_rm)
    EEG = pop_select(EEG,'nochannel',CONFIG.chan_to_rm);
    EEG = eeg_checkset( EEG );
end

end


function [EEG, CONFIG] = import_chanlocs(EEG,CONFIG)

% load channel location
if ~isempty(CONFIG.chanlocs)
    try
        chanlocs_file = load(CONFIG.chanlocs);
        EEG.chanlocs = chanlocs_file.chanlocs;
        EEG = eeg_checkset( EEG );
        return
    catch
        disp('Channel locations do not match with EEG channel labels: skip importing chanlocs');
    end    
else 
    % look up channel locations from tempalte file
    disp('Look up channel locations from template');
    try
        EEG = pop_chanedit(EEG, 'lookup', CONFIG.chanlocs_template);
        EEG = eeg_checkset( EEG );
    catch
        disp('Mismatch channel labels with template: skip importing chanlocs');
    end
end

end


function [EEG, CONFIG] = select_time(EEG,CONFIG)

if ~isfield(CONFIG, 'time_window')
    CONFIG.time_window = [];
end

if ~isempty(CONFIG.time_window)
    try
        EEG = pop_select(EEG,'time',CONFIG.time_window);
        EEG = eeg_checkset(EEG);
    catch
        error('Selected time frame for processing is incorrect.')
    end
else
    CONFIG.time_window = [0, EEG.xmax];
end
CONFIG.rawinfo.time_window = CONFIG.time_window;

end

%% handel special case for wearable sensing DSI24
function [EEG, CONFIG] = handle_special_case(EEG, CONFIG)

if contains(EEG.chanlocs(1).labels,'EEG')
    
    % modify channel labels to match with template
    chanlocs = EEG.chanlocs;
    for it = 1:length({EEG.chanlocs.labels})
        
        label = extractBetween(EEG.chanlocs(it).labels, 'EEG ','-Pz');
        
        if ~isempty(label)
            label = label{:};
            chanlocs(it).labels = label;
        else
            chanlocs(it) = [];
        end
    end
    EEG.chanlocs = chanlocs;
    EEG = eeg_checkset(EEG);
    
    % add back Pz
    EEG.data = [EEG.data; zeros(1,EEG.pnts)];
    EEG.chanlocs(end+1).labels = 'Pz';
    EEG = eeg_checkset(EEG);
    
    % compute average rereference to reconstruct Pz and raw data of other channels
    EEG = pop_reref(EEG, []);
    EEG = eeg_checkset(EEG);
    
elseif contains(EEG.chanlocs(1).labels,'LE')  % linked-ear setting

    % modify channel labels to match with template
    chanlocs = EEG.chanlocs;
    for it = 1:length({EEG.chanlocs.labels})
        
        label = extractBefore(EEG.chanlocs(it).labels,'-LE');
        
        if ~isempty(label)
            chanlocs(it).labels = label;
        else
            chanlocs(it) = [];
        end
    end
    EEG.chanlocs = chanlocs;
    EEG = eeg_checkset(EEG);
    
else
    error('Unseen format of channel labels');
end
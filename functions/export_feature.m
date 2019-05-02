%% Export desired features to Excel Sheet
function [feature_out, session_name, feature_name] = export_feature(datafolder_list)

select_chan = {'F3','F4'};
freq_band = {'delta','theta','alpha','beta','gamma'};
select_band = [2,5];    % theta and gamma

% iterate through folders
feature_size = length(select_band)*length(select_chan) * 2; % relative and absolute power
feature_out = zeros(feature_size, length(datafolder_list));
session_name = cell(1,length(datafolder_list));
feature_name = {};
for file_id = 1:length(datafolder_list)
    
    % store session name
    datafolder = datafolder_list{file_id};
    [~,foldername] = fileparts(datafolder);
    name_seg = strsplit(foldername,'_');
    session_name{file_id} = sprintf('S%s_%s',name_seg{2},name_seg{4});
    
    % load CONFIG (contains report)
    if exist([datafolder filesep 'CONFIG.mat'],'file')
        tmp = load([datafolder filesep 'CONFIG.mat']);
        CONFIG = tmp.CONFIG;
    end
    
    % generate feature names
    if file_id == 1
        chan_index = zeros(1,length(select_chan));
        for it = 1:length(select_chan)
            chan_index(it) = find(strcmp(CONFIG.prep.chanlocs_labels_pre,select_chan(it)));
        end
        % generate feature name
        for it = 1:length(select_band)
            band_id = select_band(it);
            for ch_id = 1:length(select_chan)
                feature_name{end+1} = sprintf('%s_%s',freq_band{band_id},select_chan{ch_id});
            end
            for ch_id = 1:length(select_chan)
                feature_name{end+1} = sprintf('rel_%s_%s',freq_band{band_id},select_chan{ch_id});
            end
        end
    end
    
    % store desired features
    feature = [];
    for it = 1:length(select_band)
        band_id = select_band(it);
        % concatenate power
        eval(sprintf('feature = [feature; CONFIG.report.power_%s(chan_index)];',freq_band{band_id}));
        % concatenate relative power
        eval(sprintf('feature = [feature; CONFIG.report.rpower_%s(chan_index)];',freq_band{band_id}));
    end
    feature_out(:,file_id) = feature;
    
end
end

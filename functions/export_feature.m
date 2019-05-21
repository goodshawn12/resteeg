%% Export desired features to Excel Sheet
function [feature_out, session_name, feature_name] = export_feature(datafolder_list)

% power measure
select_chan = {'F3','F4'};
freq_band = {'delta','theta','alpha','beta','gamma'};
select_band = [2,5];    % theta and gamma

% coherence measure to report
select_band_coh = [2,5];

% iterate through folders
% feature_size = length(select_band)*length(select_chan) * 2; % relative and absolute power
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
        % generate feature name for frequency band power
        for it = 1:length(select_band)
            band_id = select_band(it);
            for ch_id = 1:length(select_chan)
                feature_name{end+1} = sprintf('%s_%s',freq_band{band_id},select_chan{ch_id});
            end
            for ch_id = 1:length(select_chan)
                feature_name{end+1} = sprintf('rel_%s_%s',freq_band{band_id},select_chan{ch_id});
            end
        end
        % generate feature name for frequency band coherence
        if isfield(CONFIG.report,'mscohere') && isfield(CONFIG.report,'coh_chann_pair')
            for pair_id = 1:length(CONFIG.report.coh_chann_pair)
                for it = 1:length(select_band_coh)
                    feature_name{end+1} = sprintf('coh_%s_%s-%s',freq_band{select_band_coh(it)}, ...
                        CONFIG.report.coh_chann_pair{pair_id}{1},CONFIG.report.coh_chann_pair{pair_id}{2});
                end
            end
        end
        
        % initialize output variable (only done for the first time)
        feature_out = zeros(length(feature_name), length(datafolder_list));

    end
    
    % store desired features
    feature = [];
    
    % feature for frequency band power
    for it = 1:length(select_band)
        band_id = select_band(it);
        % concatenate power
        eval(sprintf('feature = [feature; CONFIG.report.power_%s(chan_index)];',freq_band{band_id}));
        % concatenate relative power
        eval(sprintf('feature = [feature; CONFIG.report.rpower_%s(chan_index)];',freq_band{band_id}));
    end
    
    % feature for frequency band coherence
    if isfield(CONFIG.report,'mscohere') && isfield(CONFIG.report,'coh_chann_pair')
        for pair_id = 1:length(CONFIG.report.coh_chann_pair)
            for band_it = 1:length(select_band_coh)
                % concatenate coherence measure
                feature = [feature; CONFIG.report.mscohere(band_it, pair_id)];
            end
        end
    end

    feature_out(:,file_id) = feature;
    
end
end

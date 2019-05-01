function [EEG, CONFIG] = prep_proc(EEG,CONFIG)

%% ------------------------------------------------------------------------
%               Preprocessing Pipeline
% -------------------------------------------------------------------------

% basic cleaning pipeline
[EEG, CONFIG] = resample_data(EEG,CONFIG);
[EEG, CONFIG] = filter_data(EEG,CONFIG);
[EEG, CONFIG] = remove_badchan(EEG,CONFIG);
[EEG, CONFIG] = interp_badchan(EEG,CONFIG);
[EEG, CONFIG] = reref_data(EEG,CONFIG);

% advance cleaning pipeline
[EEG, CONFIG] = remove_linenoise(EEG,CONFIG);
[EEG, CONFIG] = asr_autoclean(EEG,CONFIG);
[EEG, CONFIG] = ica_autoclean(EEG,CONFIG);

end


function [EEG, CONFIG] = resample_data(EEG,CONFIG)

if ~isempty(CONFIG.resample_rate)
    EEG = pop_resample(EEG,CONFIG.resample_rate);
end

end


function [EEG, CONFIG] = filter_data(EEG,CONFIG)

% [TODO] investigate filtering methods and options
% high pass filtering using FIR
plotfreqz = 0;
if ~isempty(CONFIG.filter_hp_cutoff)
    EEG = pop_eegfiltnew(EEG,[],CONFIG.filter_hp_cutoff,[],1,[],plotfreqz); % why set revfilt = 1 (invert filter)?
end

% previous command for high pass filtering
% EEG = pop_eegfilt( EEG, CONFIG.filter_hp_cutoff, 0, [], 0, 0, 0, 'fir1', 0);

% low pass filtering using FIR
if ~isempty(CONFIG.filter_lp_cutoff)
    EEG = pop_eegfiltnew(EEG,[],CONFIG.filter_lp_cutoff,[],0,[],plotfreqz);
end
EEG = eeg_checkset( EEG );

end


function [EEG, CONFIG] = remove_badchan(EEG,CONFIG)

CONFIG.prep.chanlocs_pre = EEG.chanlocs;
CONFIG.prep.chanlocs_labels_pre = {EEG.chanlocs.labels};

% option 1: using pop_rejchan
if CONFIG.DO_RMBADCHAN_REJCHAN
    low_freq = CONFIG.filter_hp_cutoff;
    high_freq = CONFIG.filter_lp_cutoff;
    
    if isempty(low_freq), low_freq = 1; end
    if isempty(high_freq), high_freq = EEG.srate / 2; end
    
    EEG = pop_rejchan(EEG, 'threshold',[-3 3],'norm','on','measure','spec','freqrange',[low_freq high_freq]);
    EEG = eeg_checkset( EEG );
    
    channel_labels_rejchan = {EEG.chanlocs.labels};
    CONFIG.prep.badchan_rejchan = setdiff(CONFIG.prep.chanlocs_labels_pre, channel_labels_rejchan);
    disp('Removed channels via pop_rejchan:')
    disp(CONFIG.prep.badchan_rejchan)
end

% option 2: usign clean_rawdata
if CONFIG.DO_RMBADCHAN_CLEANRAW
    
    % remove flat-line channels
    channel_labels_pre = {EEG.chanlocs.labels};
    EEG = clean_flatlines(EEG,CONFIG.rmchan_flatline);
    channel_labels_flatlines = {EEG.chanlocs.labels};
    CONFIG.prep.badchan_flatlines = setdiff(channel_labels_pre, channel_labels_flatlines);
    disp('Removed flat-line channels:')
    disp(CONFIG.prep.badchan_flatlines)
    
    % remove noisy channels by correlation and line-noise thresholds
    channel_crit_maxbad_time = 0.5;
    nolocs_channel_crit = 0.45;
    nolocs_channel_crit_excluded = 0.1;
    try
        EEG = clean_channels(EEG,CONFIG.rmchan_mincorr,CONFIG.rmchan_linenoise,[],channel_crit_maxbad_time);
    catch e
        if strcmp(e.identifier,'clean_channels:bad_chanlocs')
            disp('Your dataset appears to lack correct channel locations; using a location-free channel cleaning method.');
            EEG = clean_channels_nolocs(EEG,nolocs_channel_crit,nolocs_channel_crit_excluded,[],channel_crit_maxbad_time);
        else
            rethrow(e);
        end
    end
    CONFIG.prep.badchan_corrnoise = setdiff(channel_labels_flatlines, {EEG.chanlocs.labels});
    disp('Removed noisy channels by correlation and line-noise thresholds:')
    disp(CONFIG.prep.badchan_corrnoise)
    
    % EEG_clean = clean_rawdata(EEG, CONFIG.rmchan_flatline, -1, CONFIG.rmchan_mincorr, CONFIG.rmchan_linenoise, -1, -1);
    try
        if CONFIG.VIS_CLEAN
            vis_artifacts(EEG_clean,EEG);
        end
    catch
        disp('Unsuccessful attempt to call vis_artifacts for visualization');
    end
    EEG = eeg_checkset( EEG );
    
end

% option 3: eeg_detect_bad_channels from Jason's AMICA plugin
CONFIG.prep.chanlocs_post = EEG.chanlocs;
CONFIG.prep.chanlocs_labels_post = {EEG.chanlocs.labels};
CONFIG.prep.num_chan_prep = EEG.nbchan;

end


function [EEG, CONFIG] = interp_badchan(EEG,CONFIG)

% [TODO] interpolate removed bad channels
CONFIG.prep.interp_chan = [];
CONFIG.prep.num_interp_chan = 0;
if CONFIG.DO_INTERP_BADCHAN
    CONFIG.prep.interp_chan = setdiff(CONFIG.prep.chanlocs_labels_pre, CONFIG.prep.chanlocs_labels_post);
    CONFIG.prep.num_interp_chan = length(CONFIG.prep.interp_chan);
    
    EEG = pop_interp(EEG, CONFIG.prep.chanlocs_pre, 'spherical');
    EEG = eeg_checkset(EEG );
end
CONFIG.prep.num_chan_total = EEG.nbchan;

end


function [EEG, CONFIG] = reref_data(EEG,CONFIG)

if strcmpi(CONFIG.reref_choice, 'avg') || strcmpi(CONFIG.reref_choice, 'average')
    % average reference (reduce one rank)
    EEG = pop_reref(EEG, []);
    EEG = eeg_checkset(EEG);
elseif strcmpi(CONFIG.reref_choice, 'zero') || strcmpi(CONFIG.reref_choice, 'rest')
    % alternative: zero-reference
elseif strcmpi(CONFIG.reref_choice, 'csd')
    % alternative: CSD (toolbox)
elseif strcmpi(CONFIG.reref_choice, 'single')
    % alternative: signle channel reref
else
    disp('Reference choice not specified or inccorect')
end

end


function [EEG, CONFIG] = remove_linenoise(EEG,CONFIG)

% option 1: cleanline
% reduce line noise in the data (note: may not completely eliminate, re-referencing helps at the end as well)
EEG = pop_cleanline(EEG, 'bandwidth',2,'chanlist', 1:EEG.nbchan,'computepower',1,'linefreqs',...
    [60 120] ,'normSpectrum',0,'p',0.01,'pad',2,'plotfigures',0,'scanforlines',1,'sigtype',...
    'Channels','tau',100,'verb',0,'winsize',4,'winstep',1, 'ComputeSpectralPower','False');
if ~CONFIG.VIS_CLEAN
    close;
end
EEG = eeg_checkset(EEG);

% option 2: 60Hz, 120Hz notch filter


end


function [EEG, CONFIG] = asr_autoclean(EEG,CONFIG)

% call asr specific function
if ~isempty(CONFIG.asr_stdcutoff)
    EEG = clean_asr(EEG,CONFIG.asr_stdcutoff);
    EEG = eeg_checkset( EEG );
end

% [TODO] rereference again?

end


function [EEG, CONFIG] = ica_autoclean(EEG,CONFIG)

% run ICA to evaluate components this time
num_pcs = CONFIG.prep.num_chan_prep; % after bad channel rejection
if strcmpi(CONFIG.reref_choice, 'avg') || strcmpi(CONFIG.reref_choice, 'average')
    num_pcs = num_pcs - 1; % after average reference
end

% run ica
EEG = pop_runica(EEG,'icatype','runica','extended',0,'pca',num_pcs,'interupt','on');
EEG = eeg_checkset( EEG );

% run ICLabel classifier
EEG = pop_iclabel(EEG, 'default');
EEG = eeg_checkset( EEG );

% save ICA and ICALabel results
pop_viewprops( EEG, 0, [1:size(EEG.icaweights,1)], {'freqrange', [2 60]}, {}, 1, 'ICLabel' );
saveas(gcf,[CONFIG.report.directory filesep 'ICLabel'],'png'); close

% identify artifact components to be rejected
CONFIG.prep.ICrej_muscle = find(EEG.etc.ic_classification.ICLabel.classifications(:,2)>CONFIG.ICrej_thres);
CONFIG.prep.ICrej_eye = find(EEG.etc.ic_classification.ICLabel.classifications(:,3)>CONFIG.ICrej_thres);
CONFIG.prep.ICrej_heart = find(EEG.etc.ic_classification.ICLabel.classifications(:,4)>CONFIG.ICrej_thres);
CONFIG.prep.ICrej_linenoise = find(EEG.etc.ic_classification.ICLabel.classifications(:,5)>CONFIG.ICrej_thres);
CONFIG.prep.ICrej_channoise = find(EEG.etc.ic_classification.ICLabel.classifications(:,6)>CONFIG.ICrej_thres);

% reject components and remove their activity from data
EEG = pop_subcomp( EEG, [CONFIG.prep.ICrej_muscle, CONFIG.prep.ICrej_eye, CONFIG.prep.ICrej_heart, ...
    CONFIG.prep.ICrej_linenoise, CONFIG.prep.ICrej_channoise], 0);

end


function [EEG, CONFIG] = waveica_autoclean(EEG,CONFIG)

% % run wavelet-ICA (ICA first for clustering the data, then wavelet thresholding on the ICs)
% %uses a soft, global threshold for the wavelets, wavelet family is coiflet (level 5), threshold multiplier .75 to remove more high frequency noise
% %for details, see wICA.m function
%
% % run ICA using "runica" or "radical"
% ica_alg = 'runica';
% if strcmp(ica_alg,'runica')
%     [EEG, com] = pop_runica(EEG, 'extended',1,'interupt','on'); %runica for parametric, default extended for finding subgaussian distributions
%     W = EEG.icaweights*EEG.icasphere;
%     A = inv(W);
%     EEG.icaact = W * EEG.data; % added by SHH (in case MATLAB auto-compute icaact box is not checked)
%     IC=reshape(EEG.icaact, size(EEG.icaact,1), []);
%     %com = pop_export(OUTEEG,'ICactivationmatrix','ica','on','elec','off','time','off','precision',4);
%     %IC = ICactivationmatrix;
% elseif strcmp(ica_alg,'radical')
%     [IC,W] = radical(EEG.data); % radical ICA for non-parametric
%     A = inv(W);
% end
%
% % wICA
% wIC = wavelet_ICA(EEG, IC, 1);
%
% %reconstruct artifact signal as channelsxsamples format from the wavelet coefficients
% artifacts = A*wIC;
%
% %reshape EEG signal from EEGlab format to channelsxsamples format
% EEG2D=reshape(EEG.data, size(EEG.data,1), []);
%
% %subtract out wavelet artifact signal from EEG signal
% EEG.data = EEG2D - artifacts;

end

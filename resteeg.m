function CONFIG = resteeg(CONFIG)

%% ------------------------------------------------------------------------
%               Import Data and Obtain Dataset Info
% -------------------------------------------------------------------------

% load EEG dataset if already exists, otherwise convert data to EEGLAB (.set) format
if exist([CONFIG.filepath filesep CONFIG.filename '.set'],'file')
    EEG = pop_loadset([CONFIG.filepath filesep CONFIG.filename '.set']);
    tmp = load([CONFIG.report.directory filesep 'config_import.mat']);
    CONFIG.rawinfo = tmp.config_import;
else
    % convert data to EEGLAB (.set) format
    [EEG, CONFIG] = import_data(CONFIG);
    % remove user-specified (non-EEG) channels
    [EEG, CONFIG] = remove_channel(EEG,CONFIG);
    % handle dataset specific issues
    if CONFIG.HANDLE_SPECIAL_CASE, [EEG, CONFIG] = handle_special_case(EEG, CONFIG); end
    % import channel locations
    [EEG, CONFIG] = import_chanlocs(EEG,CONFIG);
    % save dataset
    [EEG, CONFIG] = save_data(EEG,CONFIG,CONFIG.filename,0);
end


%% ------------------------------------------------------------------------
%               Preprocessing Pipeline
% -------------------------------------------------------------------------

% load preprocessed EEG data if already exists, otherwise apply preprocessing pipeline
if exist([CONFIG.filepath filesep CONFIG.filename_prep '.set'],'file') && ~CONFIG.RUN_PREPROC
    EEG = pop_loadset([CONFIG.filepath filesep CONFIG.filename_prep '.set']);
    tmp = load([CONFIG.report.directory filesep 'config_prep.mat']);
    CONFIG.prep = tmp.config_prep;
else
    % basic cleaning pipeline
    [EEG, CONFIG] = resample_data(EEG,CONFIG);
    [EEG, CONFIG] = filter_data(EEG,CONFIG);
    [EEG, CONFIG] = remove_linenoise(EEG,CONFIG);
    [EEG, CONFIG] = remove_badchan(EEG,CONFIG);
    [EEG, CONFIG] = interp_badchan(EEG,CONFIG);
    [EEG, CONFIG] = reref_data(EEG,CONFIG);
    
    % advance cleaning pipeline
    [EEG, CONFIG] = asr_autoclean(EEG,CONFIG);
    [EEG, CONFIG] = ica_autoclean(EEG,CONFIG);
    % [EEG, CONFIG] = waveica_autoclean(EEG,CONFIG);
    
    % save preprocessed data
    [EEG, CONFIG] = save_data(EEG,CONFIG,CONFIG.filename_prep,1);
end


%% ------------------------------------------------------------------------
%               Statistics of Signals
% -------------------------------------------------------------------------

% report bad channel statistics



%% ------------------------------------------------------------------------
%               Reported Clinical Biomarkers
% -------------------------------------------------------------------------


%% ------------------------------------------------------------------------
%               Power-related Measures
% -------------------------------------------------------------------------

[EEG, CONFIG] = power_analysis(EEG,CONFIG);

% figure; pop_spectopo(EEG, 1, [], 'EEG' , 'freq', [[freq_to_plot]], 'freqrange',[[vis_freq_min] [vis_freq_max]],'electrodes','off');
% saveas (gcf,[filename '_processedspectrum.jpg'] );



%% ------------------------------------------------------------------------
%                   Entropy Measures
% -------------------------------------------------------------------------



%% ------------------------------------------------------------------------
%               Source-level Analysis
% -------------------------------------------------------------------------



%% ------------------------------------------------------------------------
%           Connectivity and Coherence Analysis
% -------------------------------------------------------------------------

% power-amplitude coupling
% power-phase coupling


%% ------------------------------------------------------------------------
%          Nonstationary Analysis of Brain Dynamics
% -------------------------------------------------------------------------

% HHM 
% microstate analysis
% AMICA 
% Nonlinear dynamic model / Dynamic causal modeling


%% ------------------------------------------------------------------------
%                   Generate Report
% -------------------------------------------------------------------------

[EEG, CONFIG] = gen_report_materials(EEG,CONFIG);

[EEG, CONFIG] = gen_report(EEG,CONFIG);

end


function [EEG, CONFIG] = import_data(CONFIG)

% import EEG data and convert to .set format
if isempty(CONFIG.filepath) || isempty(CONFIG.filename)
    % allow user to select file
    EEG = pop_loadset();
end

if strcmp(CONFIG.fileformat,'bdf') || strcmp(CONFIG.fileformat,'edf')
    EEG = pop_biosig([CONFIG.filepath filesep CONFIG.filename '.' CONFIG.fileformat]);
    EEG = eeg_checkset( EEG );
else
    disp('The data format not supported. Please see EEGLAB data import for more info.')
    return
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


function [EEG, CONFIG] = save_data(EEG,CONFIG,filename,ISPREP)

% convert data to double precision
if CONFIG.double_precision
    EEG.data = double(EEG.data);
    EEG = eeg_checkset( EEG );
end

if CONFIG.SAVESET
    if ~exist(CONFIG.report.directory,'file'), mkdir(CONFIG.report.directory); end
    % save EEG data
    filename = [filename '.set'];
    pop_saveset(EEG,'filepath',CONFIG.filepath,'filename',filename);
    fprintf('Saved EEG file ''%s'' under the folder ''%s''\n',filename, CONFIG.filepath);
    
    % save raw data information
    if ~ISPREP
        config_import = CONFIG.rawinfo;
        save([CONFIG.report.directory filesep 'config_import.mat'],'config_import');
    else
        config_prep = CONFIG.prep;
        save([CONFIG.report.directory filesep 'config_prep.mat'],'config_prep');
    end
end

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

EEG = pop_runica(EEG, 'extended',1,'pca',num_pcs,'interupt','on');
EEG = eeg_checkset( EEG );


% option 1: use MARA to flag artifactual IComponents automatically if artifact probability > .5
% [~,EEG,~]=processMARA ( EEG,EEG,EEG, [0, 0, pipeline_visualizations_semiautomated,...
%     pipeline_visualizations_semiautomated , pipeline_visualizations_semiautomated] );
% 
% EEG.reject.gcompreject = zeros(size(EEG.reject.gcompreject));
% EEG.reject.gcompreject(EEG.reject.MARAinfo.posterior_artefactprob > 0.5) = 1;
% EEG = eeg_checkset( EEG );
% 
% % store MARA related variables to assess ICA/data quality
% index_ICs_kept=(EEG.reject.MARAinfo.posterior_artefactprob < 0.5);
% median_artif_prob_good_ICs = median(EEG.reject.MARAinfo.posterior_artefactprob(index_ICs_kept));
% mean_artif_prob_good_ICs = mean(EEG.reject.MARAinfo.posterior_artefactprob(index_ICs_kept));
% range_artif_prob_good_ICs = range(EEG.reject.MARAinfo.posterior_artefactprob(index_ICs_kept));
% min_artif_prob_good_ICs = min(EEG.reject.MARAinfo.posterior_artefactprob(index_ICs_kept));
% max_artif_prob_good_ICs = max(EEG.reject.MARAinfo.posterior_artefactprob(index_ICs_kept));
% 
% %store IC variables and calculate variance of data that will be kept after IC rejection:
% ICs_to_keep =find(EEG.reject.gcompreject == 0);
% ICA_act = EEG.icaweights * EEG.icasphere * EEG.data;
% ICA_winv =EEG.icawinv;
% 
% %variance of wavelet-cleaned data to be kept = varianceWav:
% [projWav, varianceWav] =compvar(EEG.data, ICA_act, ICA_winv, ICs_to_keep);
% 
% % reject the ICs that MARA flagged as artifact
% artifact_ICs = find(EEG.reject.gcompreject == 1);
% EEG = pop_subcomp( EEG, artifact_ICs, 0);
% EEG = eeg_checkset( EEG );

% option 2: use IC labels

% option 3: manually select IC to reject


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


function [EEG, CONFIG] = power_analysis(EEG,CONFIG)

% compute power spectra density (PSD)
[spectra,freqs] = spectopo(EEG.data, 0, EEG.srate); close

% Set the following frequency bands: delta=1-4, theta=4-8, alpha=8-13, beta=13-30, gamma=30-80.
CONFIG.report.power_delta = mean(10.^(spectra(:, freqs>=1 & freqs<4 )/10),2);
CONFIG.report.power_theta = mean(10.^(spectra(:, freqs>=4 & freqs<8 )/10),2);
CONFIG.report.power_alpha = mean(10.^(spectra(:, freqs>=8 & freqs<13 )/10),2);
CONFIG.report.power_beta  = mean(10.^(spectra(:, freqs>=13 & freqs<30 )/10),2);
CONFIG.report.power_gamma = mean(10.^(spectra(:, freqs>=30 & freqs<80 )/10),2);

% compute relative power
total_power = sum([CONFIG.report.power_delta,CONFIG.report.power_theta,CONFIG.report.power_alpha, ...
    CONFIG.report.power_beta,CONFIG.report.power_gamma],2);
CONFIG.report.rpower_delta = CONFIG.report.power_delta ./ total_power;
CONFIG.report.rpower_theta = CONFIG.report.power_theta ./ total_power;
CONFIG.report.rpower_alpha = CONFIG.report.power_alpha ./ total_power;
CONFIG.report.rpower_beta  = CONFIG.report.power_beta ./ total_power;
CONFIG.report.rpower_gamma = CONFIG.report.power_gamma ./ total_power;

% compute frontal alpha asymmetry
try
    frontal_channels = {'F3','F4','F7','F8'};
    frontal_alpha = zeros(1,length(frontal_channels));
    for chan_id = 1:length(frontal_channels)
        ch = strcmp(frontal_channels{chan_id},CONFIG.prep.chanlocs_labels_pre);
        frontal_alpha(chan_id) = CONFIG.report.power_alpha(ch);
    end
    CONFIG.report.frontal_alpha_asym_F34 = (frontal_alpha(1) - frontal_alpha(2)) / (frontal_alpha(1) + frontal_alpha(2));
    CONFIG.report.frontal_alpha_asym_F78 = (frontal_alpha(3) - frontal_alpha(4)) / (frontal_alpha(3) + frontal_alpha(4));
catch
    disp('Errors when computing frontal alpha asymmetry. Might be missing channels')
end

end


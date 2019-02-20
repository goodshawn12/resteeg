function resteeg(CONFIG)

%% ------------------------------------------------------------------------
%               Import Data and Obtain Dataset Info
% -------------------------------------------------------------------------
[EEG, CONFIG] = import_data(CONFIG);


%% ------------------------------------------------------------------------
%               Preprocessing Pipeline
% -------------------------------------------------------------------------

% basic cleaning pipeline

[EEG, CONFIG] = resample_data(EEG,CONFIG);

[EEG, CONFIG] = filter_data(EEG,CONFIG);

[EEG, CONFIG] = remove_linenoise(EEG,CONFIG);

[EEG, CONFIG] = remove_badchan(EEG,CONFIG);

[EEG, CONFIG] = interp_badchan(EEG,CONFIG);

[EEG, CONFIG] = reref_data(EEG,CONFIG);


% advance cleaning pipeline

[EEG, CONFIG] = asr_autoclean(EEG,CONFIG);

% [EEG, CONFIG] = ica_autoclean(EEG,CONFIG);

% [EEG, CONFIG] = waveica_autoclean(EEG,CONFIG);


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

[EEG, CONFIG] = compute_bandpower(EEG,CONFIG);

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

% [EEG, CONFIG] = gen_report(EEG,CONFIG);



end


function [EEG, CONFIG] = import_data(CONFIG)

if isempty(CONFIG.filepath) || isempty(CONFIG.filename)
    % allow user to select file
    EEG = pop_loadset();
end

if strcmp(CONFIG.fileformat,'bdf')
    EEG = pop_biosig([CONFIG.filepath filesep CONFIG.filename '.' CONFIG.fileformat]);
    EEG = eeg_checkset( EEG );
else
    disp('The data format not supported. Please see EEGLAB data import for more info.')
    return
end

% remove user-specified channels
if ~isempty(CONFIG.chan_to_rm)
    EEG = pop_select(EEG,'nochannel',CONFIG.chan_to_rm);
    EEG = eeg_checkset( EEG );
end

% load channel location
if ~isempty(CONFIG.chanlocs)
    chanlocs_file = load(CONFIG.chanlocs);
    EEG.chanlocs = chanlocs_file.chanlocs;
    EEG = eeg_checkset( EEG );
end

% convert data to double precision
if CONFIG.double_precision
    EEG.data = double(EEG.data);
    EEG = eeg_checkset( EEG );
end

% save file
if CONFIG.SAVESET
    filename = [CONFIG.filename '.set'];
    pop_saveset(EEG,'filepath',CONFIG.filepath,'filename',filename);
    fprintf('Saved EEG file ''%s'' under the folder ''%s''\n',filename, CONFIG.filepath);
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


function [EEG, CONFIG] = remove_badchan(EEG,CONFIG)

raw_channel_labels = {EEG.chanlocs.labels};

% option 1: using pop_rejchan
if CONFIG.DO_RMBADCHAN_REJCHAN  
    low_freq = CONFIG.filter_hp_cutoff;
    high_freq = CONFIG.filter_lp_cutoff;
    
    if isempty(low_freq), low_freq = 1; end
    if isempty(high_freq), high_freq = EEG.srate / 2; end
    
    EEG = pop_rejchan(EEG, 'threshold',[-3 3],'norm','on','measure','spec','freqrange',[low_freq high_freq]);
    EEG = eeg_checkset( EEG );
    
    clean_channel_labels_rejchan = {EEG.chanlocs.labels};
    badchan_labels_rejchan = setdiff(raw_channel_labels, clean_channel_labels_rejchan);
    CONFIG.report.badchan_rejchan = badchan_labels_rejchan;
    disp('Removed channels via pop_rejchan:')
    disp(badchan_labels_rejchan)
end

% option 2: usign clean_rawdata
if CONFIG.DO_RMBADCHAN_CLEANRAW     
    EEG_clean = clean_rawdata(EEG, CONFIG.rmchan_flatline, -1, CONFIG.rmchan_mincorr, CONFIG.rmchan_linenoise, -1, -1);
    try
        if CONFIG.VIS_CLEAN
            vis_artifacts(EEG_clean,EEG);
        end
    catch
        disp('Unsuccessful attempt to call vis_artifacts for visualization');
    end
    EEG = EEG_clean;
    EEG = eeg_checkset( EEG );
    
    clean_channel_labels_cleanraw = {EEG.chanlocs.labels};
    badchan_labels_cleanraw = setdiff(raw_channel_labels, clean_channel_labels_cleanraw);
    CONFIG.report.badchan_cleanraw = badchan_labels_cleanraw;
    disp('Removed channels via clean_rawdata:')
    disp(badchan_labels_cleanraw)
end

% option 3: eeg_detect_bad_channels from Jason's AMICA plugin


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


function [EEG, CONFIG] = interp_badchan(EEG,CONFIG)

% [TODO] interpolate removed bad channels 
if CONFIG.DO_INTERP_BADCHAN
    EEG = pop_interp(EEG, EEG.chanlocs, 'spherical');
    EEG = eeg_checkset(EEG );
end

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
EEG = pop_runica(EEG, 'extended',1,'interupt','on');
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


function [EEG, CONFIG] = compute_bandpower(EEG,CONFIG)

% compute power spectra density (PSD)
[spectra,freqs] = spectopo(EEG.data, 0, EEG.srate);

% Set the following frequency bands: delta=1-4, theta=4-8, alpha=8-13, beta=13-30, gamma=30-80.
CONFIG.report.power_delta = mean(10.^(spectra(:, freqs>=1 & freqs<4 )/10),2);
CONFIG.report.power_theta = mean(10.^(spectra(:, freqs>=4 & freqs<8 )/10),2);
CONFIG.report.power_alpha = mean(10.^(spectra(:, freqs>=8 & freqs<13 )/10),2);
CONFIG.report.power_beta  = mean(10.^(spectra(:, freqs>=13 & freqs<30 )/10),2);
CONFIG.report.power_gamma = mean(10.^(spectra(:, freqs>=30 & freqs<80 )/10),2);

end


function [EEG, CONFIG] = gen_report(EEG,CONFIG)

% % generate output table in the "preprocessed" subfolder listing the subject file name and relevant variables for assesssing how good/bad that datafile was and how well the pipeline worked
% outputtable=table({filename},EEG.xmax',Number_Channels_User_Selected',Number_Segments_Post_Segment_Rejection',...
%     Number_Good_Channels_Selected', Percent_Good_Channels_Selected', Interpolated_Channel_IDs',Number_ICs_Rejected',...
%     Percent_ICs_Rejected', Percent_Variance_Kept_of_Post_Waveleted_Data',Median_Artifact_Probability_of_Kept_ICs',...
%     Mean_Artifact_Probability_of_Kept_ICs',Range_Artifact_Probability_of_Kept_ICs',Min_Artifact_Probability_of_Kept_ICs',...
%     Max_Artifact_Probability_of_Kept_ICs');
% outputtable.Properties.VariableNames ={'FileNames','File_Length_In_Secs','Number_Channels_User_Selected','Number_Segments_Post_Segment_Rejection',...
%     'Number_Good_Channels_Selected', 'Percent_Good_Channels_Selected', 'Interpolated_Channel_IDs','Number_ICs_Rejected',...
%     'Percent_ICs_Rejected', 'Percent_Variance_Kept_of_Post_Waveleted_Data','Median_Artifact_Probability_of_Kept_ICs',...
%     'Mean_Artifact_Probability_of_Kept_ICs','Range_Artifact_Probability_of_Kept_ICs','Min_Artifact_Probability_of_Kept_ICs',...
%     'Max_Artifact_Probability_of_Kept_ICs'};
% 
% writetable(outputtable, ['HAPPE_output_table ',datestr(now,'dd-mm-yyyy'),'.csv']);

end



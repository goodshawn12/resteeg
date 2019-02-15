function resteeg(CONFIG)

%% ------------------------------------------------------------------------
%               Import Data and Obtain Dataset Info
% -------------------------------------------------------------------------
[EEG, CONFIG] = import_data(CONFIG);


%% ------------------------------------------------------------------------
%               Preprocessing Pipeline
% -------------------------------------------------------------------------

% basic cleaning pipeline

[EEG, CONFIG] = filter_data(EEG,CONFIG);

[EEG, CONFIG] = remove_linenoise(EEG,CONFIG);

[EEG, CONFIG] = remove_badchan(EEG,CONFIG);

% [EEG, CONFIG] = interp_badchan(EEG,CONFIG);

[EEG, CONFIG] = reref_data(EEG,CONFIG);


% advance cleaning pipeline

[EEG, CONFIG] = asr_autoclean(EEG,CONFIG);

[EEG, CONFIG] = ica_autoclean(EEG,CONFIG);

% [EEG, CONFIG] = waveica_autoclean(EEG,CONFIG);


%% ------------------------------------------------------------------------
%               Statistics of Signals
% -------------------------------------------------------------------------




%% ------------------------------------------------------------------------
%               Reported Clinical Biomarkers
% -------------------------------------------------------------------------




%% ------------------------------------------------------------------------
%               Power-related Measures
% -------------------------------------------------------------------------

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

[EEG, CONFIG] = gen_report(EEG,CONFIG);



end


function [EEG, CONFIG] = import_data(CONFIG)

if isempty(CONFIG.filepath) || isempty(CONFIG.filename)
    % allow user to select file
end

EEG = pop_biosig([CONFIG.filepath filesep CONFIG.filename '.bdf']);
EEG = eeg_checkset( EEG );

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

% save file
if CONFIG.SAVESET
    filename = [CONFIG.filename '.set'];
    pop_saveset(EEG,'filepath',CONFIG.filepath,'filename',filename);
    fprintf('Saved EEG file ''%s'' under the folder ''%s''\n',filename, CONFIG.filepath);
end

end


function [EEG, CONFIG] = filter_data(EEG,CONFIG)

% [TODO] investigate filtering methods and options
% high pass filtering using FIR
plotfreqz = 0;
if ~isempty(CONFIG.filter_hp_cutoff)
    EEG = pop_eegfiltnew(EEG,[],CONFIG.filter_hp_cutoff,[],1,[],plotfreqz); % why set revfilt = 1 (invert filter)?
end

% low pass filtering using FIR
if ~isempty(CONFIG.filter_lp_cutoff)
    EEG = pop_eegfiltnew(EEG,[],CONFIG.filter_lp_cutoff,[],0,[],plotfreqz);
end
EEG = eeg_checkset( EEG );

end


function [EEG, CONFIG] = remove_badchan(EEG,CONFIG)

% option 1: pop_rejchan
% EEG = pop_rejchan(EEG, 'elec',chan_index,'threshold',[-3 3],'norm','on','measure','spec','freqrange',[1 125]);
% EEG = eeg_checkset( EEG );
% 
% EEG = pop_rejchan(EEG, 'elec',[1:EEG.nbchan],'threshold',[-3 3],'norm','on','measure','spec','freqrange',[1 125]);
% EEG = eeg_checkset( EEG );
% selected_channel_locations=EEG.chanlocs;
% 
% %save the names of the rejected channels for output table after the pipeline finishes
% selected_channel_labels={selected_channel_locations.labels};
% bad_channels_removed= setdiff(chan_IDs, selected_channel_labels);

% option 2: clean_radata 

% option 3: eeg_detect_bad_channels from Jason's AMICA plugin


end


function [EEG, CONFIG] = remove_linenoise(EEG,CONFIG)

% option 1: cleanline
% % reduce line noise in the data (note: may not completely eliminate, re-referencing helps at the end as well)
% EEG = pop_cleanline(EEG, 'bandwidth',2,'chanlist',chan_index,'computepower',1,'linefreqs',...
%     [60 120] ,'normSpectrum',0,'p',0.01,'pad',2,'plotfigures',0,'scanforlines',1,'sigtype',...
%     'Channels','tau',100,'verb',0,'winsize',4,'winstep',1, 'ComputeSpectralPower','False');
% EEG = eeg_checkset(EEG);
% 
% % close window if visualizations are turned off
% if pipeline_visualizations_semiautomated == 0
%     close all;
% end
% 

% option 2: 60Hz, 120Hz notch filter


end


function [EEG, CONFIG] = interp_badchan(EEG,CONFIG)

% interpolate removed bad channels
EEG = pop_interp(EEG, EEG.chanlocs, 'spherical');
EEG = eeg_checkset(EEG );

end


function [EEG, CONFIG] = reref_data(EEG,CONFIG)

% average reference
EEG = pop_reref(EEG, []);
EEG = eeg_checkset(EEG);

% alternative: zero-reference

% alternative: CSD (toolbox)

% alternative: signle channel reref


end


function [EEG, CONFIG] = asr_autoclean(EEG,CONFIG)

% call asr specific function

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



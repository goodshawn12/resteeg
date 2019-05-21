function CONFIG = resteeg(CONFIG)

%% ------------------------------------------------------------------------
%               Import Data and Obtain Dataset Info
% -------------------------------------------------------------------------

% load EEG dataset if already exists, otherwise convert data to EEGLAB (.set) format
if exist([CONFIG.filepath filesep CONFIG.filename '_import.set'],'file') && ~CONFIG.FORCE_RUN_IMPORT
    EEG = pop_loadset([CONFIG.filepath filesep CONFIG.filename '_import.set']);
    tmp = load([CONFIG.report.directory filesep 'config_import.mat']);
    CONFIG.rawinfo = tmp.config_import;
else
    [EEG, CONFIG] = prep_import(CONFIG);
    [EEG, CONFIG] = save_data(EEG,CONFIG,[CONFIG.filename '_import'],0);
end


%% ------------------------------------------------------------------------
%               Preprocessing Pipeline
% -------------------------------------------------------------------------

% load preprocessed EEG data if already exists, otherwise apply preprocessing pipeline
if exist([CONFIG.filepath filesep CONFIG.filename '_prep.set'],'file') && ~CONFIG.FORCE_RUN_PREPROC
    EEG = pop_loadset([CONFIG.filepath filesep CONFIG.filename '_prep.set']);
    tmp = load([CONFIG.report.directory filesep 'config_prep.mat']);
    CONFIG.prep = tmp.config_prep;
else
    [EEG, CONFIG] = prep_proc(EEG,CONFIG);
    [EEG, CONFIG] = save_data(EEG,CONFIG,[CONFIG.filename '_prep'],1);
end

%% ------------------------------------------------------------------------
%               Power-related Measures
% -------------------------------------------------------------------------

% power spectral density
[EEG, CONFIG] = power_analysis(EEG,CONFIG);

% Short-time Fourier Transform (STFT)
[EEG, CONFIG] = time_freq_analysis(EEG,CONFIG);


%% ------------------------------------------------------------------------
%               Statistics of Signals
% -------------------------------------------------------------------------
% report channel statistics


%% ------------------------------------------------------------------------
%               Reported Clinical Biomarkers
% -------------------------------------------------------------------------

%% ------------------------------------------------------------------------
%           Connectivity and Coherence Analysis
% -------------------------------------------------------------------------

% coherence between channel pairs
[EEG, CONFIG] = coherence_analysis(EEG,CONFIG);


% power-amplitude coupling
% power-phase coupling


%% ------------------------------------------------------------------------
%                   Entropy Measures
% -------------------------------------------------------------------------



%% ------------------------------------------------------------------------
%               Source-level Analysis
% -------------------------------------------------------------------------



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

if CONFIG.EXPORT_REPORT
    [EEG, CONFIG] = gen_report_materials(EEG,CONFIG);
    [EEG, CONFIG] = gen_report(EEG,CONFIG);
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


function [EEG, CONFIG] = power_analysis(EEG,CONFIG)

% compute power spectra density (PSD)
[spectra,freqs] = spectopo(EEG.data, 0, EEG.srate); close

% Set the following frequency bands: delta=1-4, theta=4-8, alpha=8-13, beta=13-30, gamma=30-80.
CONFIG.report.power_delta = mean(10.^(spectra(:, freqs>=1 & freqs<4 )/10),2);
CONFIG.report.power_theta = mean(10.^(spectra(:, freqs>=4 & freqs<8 )/10),2);
CONFIG.report.power_alpha = mean(10.^(spectra(:, freqs>=8 & freqs<13 )/10),2);
CONFIG.report.power_beta  = mean(10.^(spectra(:, freqs>=13 & freqs<30 )/10),2);
CONFIG.report.power_gamma = mean(10.^(spectra(:, freqs>=30 & freqs<50 )/10),2);

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


function [EEG, CONFIG] = time_freq_analysis(EEG,CONFIG)

if ~isempty(CONFIG.report.timefreq_plot_chan)
    window_len = CONFIG.report.timefreq_window_len;
    for chan_id = 1:length(CONFIG.report.timefreq_plot_chan)
        channel = find(strcmpi({EEG.chanlocs.labels},CONFIG.report.timefreq_plot_chan{chan_id}));
        
        if isempty(channel)
            error('Incorrect channel label for time frequency plot')
        end
        
        window = hann(window_len*EEG.srate);
        noverlap = floor(length(window)/2);
        nfft = max(256, 2.^ceil(log2(length(window))));
        [s,f,t] = spectrogram(EEG.data(channel,:),window,noverlap,nfft,EEG.srate);
        
        freq_range = 1:(find(f>50,1)-1);
        log_power = log(abs(s(freq_range,:)).^2);
        figure, imagesc(t,f(freq_range),log_power); set(gca,'YDir','normal'); colorbar
        caxis([prctile(log_power(:),0.25),max(log_power(:))]);
        xlabel('Time (sec)'); ylabel('Frequency (Hz)'); set(gca,'fontsize',12); colormap('jet');
        title(sprintf('Channel %s (log power)',EEG.chanlocs(channel).labels));
        set(gcf,'position',[50,50,850,350])
        
        filename = sprintf('tfplot_%s',CONFIG.report.timefreq_plot_chan{chan_id});
        saveas(gcf,[CONFIG.report.directory filesep filename],'png'); close
    end
end

end

function [EEG, CONFIG] = coherence_analysis(EEG,CONFIG)

try
    if ~isempty(CONFIG.report.coh_chann_pair)
        CONFIG.report.mscohere = zeros(5,length(CONFIG.report.coh_chann_pair)); % 5 bands x N channel-pairs
        
        % iterate through all channel pairs
        for pair_id = 1:length(CONFIG.report.coh_chann_pair)
            
            channel_1 = find(strcmpi({EEG.chanlocs.labels},CONFIG.report.coh_chann_pair{pair_id}(1)));
            channel_2 = find(strcmpi({EEG.chanlocs.labels},CONFIG.report.coh_chann_pair{pair_id}(2)));
            
            % option 1: MATLAB magnitude-squared coherence
            nfft = 2.^(ceil(log2(EEG.srate)));
            noverlap = floor(nfft/2);
            [coh_msconhere,freqs] = mscohere(EEG.data(channel_1,:),EEG.data(channel_2,:), ...
                hann(nfft), noverlap, nfft, EEG.srate);
            
            % plot coherence over frequency
            freq_range = 1:(find(freqs>50,1)-1);
            figure, plot(freqs(freq_range), coh_msconhere(freq_range));
            xlabel('Frequency (Hz)'); ylabel('Magnitude-Squared Coherence'); set(gca,'fontsize',12);
            filename = sprintf('mscoherence_%s-%s',EEG.chanlocs(channel_1).labels,EEG.chanlocs(channel_2).labels);
            saveas(gcf,[CONFIG.report.directory filesep filename],'png'); close
            
            % report ms-coherence
            CONFIG.report.mscohere(1,pair_id) = mean(coh_msconhere(freqs>=1 & freqs<4 ));
            CONFIG.report.mscohere(2,pair_id) = mean(coh_msconhere(freqs>=4 & freqs<8 ));
            CONFIG.report.mscohere(3,pair_id) = mean(coh_msconhere(freqs>=8 & freqs<13 ));
            CONFIG.report.mscohere(4,pair_id)  = mean(coh_msconhere(freqs>=13 & freqs<30 ));
            CONFIG.report.mscohere(5,pair_id) = mean(coh_msconhere(freqs>=30 & freqs<50 ));
            
        end
    end
catch
    disp('Coherence analysis: channel labels were not correctly defined.')
end

end


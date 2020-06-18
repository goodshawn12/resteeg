function [EEG, CONFIG] = gen_report_materials(EEG,CONFIG)

if ~exist(CONFIG.report.directory,'file'), mkdir(CONFIG.report.directory); end

% save configurations
save([CONFIG.report.directory filesep 'CONFIG.mat'],'CONFIG');

% save cleaning results

% plot and save figures
if CONFIG.GEN_FIGURES
    
    try % FIXME: user defined PSD layout given electrode locations
        % export spectral maps
        spectra = CONFIG.report.spectra;
        spectra_freqs = CONFIG.report.freqs;
        
        y_lim = []; % min and max value for raw spectra
        plot_seq = 1:size(spectra,1); % [2,4,6:20,22,24];
        fig_size_x = ceil(sqrt(size(spectra,1)));
        fig_size_y = round(sqrt(size(spectra,1)));        
        
        % raw power spectral plot
        figure, set(gcf,'Position',[10 10 1100 910],'Color','white');
        freqs_idx = find(spectra_freqs >= 1 & spectra_freqs <=30);
        freq_range = [1, 4, 8, 12, 15, 18, 25, 30];
        for ch_id = 1:size(spectra,1)-2
            subplot(fig_size_y,fig_size_x,plot_seq(ch_id)); hold on
            plot(spectra_freqs(freqs_idx),10.^(spectra(ch_id,freqs_idx)./10),'linewidth',1.5,'color','k');
            if ~isempty(y_lim)
                set(gca,'YLim',y_lim);
            else
                y_lim = get(gca,'YLim');
            end
            area_color(spectra_freqs(freqs_idx),10.^(spectra(ch_id,freqs_idx)./10),freq_range,y_lim(1))
            xlim([1 30]); grid on; box off;
        end
        ylabel('Power (\muV^{2}/Hz)'); xlabel('Frequency (Hz)')
        saveas(gcf,[CONFIG.report.directory filesep 'spectral_power_map'],'png'); close
        
        % log power spectral plot
        figure, set(gcf,'Position',[10 10 1100 910],'Color','white');
        freqs_idx = find(spectra_freqs >= 1 & spectra_freqs <=50);
        freq_range = [1, 4, 8, 13, 20, 30, 50];
        for ch_id = 1:size(spectra,1)-2
            subplot(fig_size_y,fig_size_x,plot_seq(ch_id)); hold on
            plot(spectra_freqs(freqs_idx),spectra(ch_id,freqs_idx),'linewidth',1.5,'color','k');
            y_lim = get(gca,'YLim');
            area_color(spectra_freqs(freqs_idx),spectra(ch_id,freqs_idx),freq_range,y_lim(1))
            title(CONFIG.prep.chanlocs_labels_pre{ch_id}); xlim([1 50]); grid on; box off;
        end
        ylabel('Log Power (dB)'); xlabel('Frequency (Hz)')
        saveas(gcf,[CONFIG.report.directory filesep 'spectral_power_map_log'],'png'); close
    catch
        disp('gen_report_materials(): customized PSD plot not yet available...')
    end
    
    figure, topoplot(CONFIG.report.power_delta,EEG.chanlocs); c=colorbar; caxis([0 c.Limits(2)]); saveas(gcf,[CONFIG.report.directory filesep 'power_delta'],'png'); close
    figure, topoplot(CONFIG.report.power_theta,EEG.chanlocs); c=colorbar; caxis([0 c.Limits(2)]); saveas(gcf,[CONFIG.report.directory filesep 'power_theta'],'png'); close
    figure, topoplot(CONFIG.report.power_alpha,EEG.chanlocs); c=colorbar; caxis([0 c.Limits(2)]); saveas(gcf,[CONFIG.report.directory filesep 'power_alpha'],'png'); close
    figure, topoplot(CONFIG.report.power_beta,EEG.chanlocs); c=colorbar; caxis([0 c.Limits(2)]); saveas(gcf,[CONFIG.report.directory filesep 'power_beta'],'png'); close
    figure, topoplot(CONFIG.report.power_gamma,EEG.chanlocs); c=colorbar; caxis([0 c.Limits(2)]); saveas(gcf,[CONFIG.report.directory filesep 'power_gamma'],'png'); close
    
    figure, topoplot(CONFIG.report.rpower_delta,EEG.chanlocs); c=colorbar; caxis([0 c.Limits(2)]); saveas(gcf,[CONFIG.report.directory filesep 'rpower_delta'],'png'); close
    figure, topoplot(CONFIG.report.rpower_theta,EEG.chanlocs); c=colorbar; caxis([0 c.Limits(2)]); saveas(gcf,[CONFIG.report.directory filesep 'rpower_theta'],'png'); close
    figure, topoplot(CONFIG.report.rpower_alpha,EEG.chanlocs); c=colorbar; caxis([0 c.Limits(2)]); saveas(gcf,[CONFIG.report.directory filesep 'rpower_alpha'],'png'); close
    figure, topoplot(CONFIG.report.rpower_beta,EEG.chanlocs); c=colorbar; caxis([0 c.Limits(2)]); saveas(gcf,[CONFIG.report.directory filesep 'rpower_beta'],'png'); close
    figure, topoplot(CONFIG.report.rpower_gamma,EEG.chanlocs); c=colorbar; caxis([0 c.Limits(2)]); saveas(gcf,[CONFIG.report.directory filesep 'rpower_gamma'],'png'); close
end


end

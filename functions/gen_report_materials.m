function [EEG, CONFIG] = gen_report_materials(EEG,CONFIG)

if ~exist(CONFIG.report.directory,'file'), mkdir(CONFIG.report.directory); end

% save configurations
save([CONFIG.report.directory filesep 'CONFIG.mat'],'CONFIG');

% save cleaning results

% plot and save figures
if CONFIG.GEN_FIGURES
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

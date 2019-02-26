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

% generate output table in the "preprocessed" subfolder listing the subject file name and relevant variables for assesssing how good/bad that datafile was and how well the pipeline worked
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

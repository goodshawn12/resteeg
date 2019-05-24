function [EEG, CONFIG] = gen_report(EEG,CONFIG)

% Import report API classes (optional)
import mlreportgen.report.*
import mlreportgen.dom.*

textYN = {'Y','N'};

% Add report container (required)
rpt = Report([CONFIG.report.directory filesep CONFIG.filename],'pdf');

% Add content to container (required)
% Types of content added here: title 
% page and table of contents reporters
titlepg = TitlePage;
titlepg.Title = 'RESTEEG: Automated Analysis of Resting-State EEG for Clinicians';
titlepg.Author = 'Sheng-Hsiou Hsu';
add(rpt,titlepg);
add(rpt,TableOfContents);

% Chapter 1: basic data info 
chap1 = Chapter('Raw data information and basic cleaning report');
table_basic = BaseTable( ...
    {'File name:            ', [CONFIG.filename, '.', CONFIG.fileformat];
     'Number of Channels:   ', CONFIG.rawinfo.nbchan;
     'Total Time (sec):     ', round(CONFIG.rawinfo.xmax);
     'Sampling Rate (Hz):   ', CONFIG.rawinfo.srate});
add(chap1, Section('Title', 'Raw data information', 'Content', table_basic));

table_prep = BaseTable( ...
    {'Manually removed channel:     ', sprintf('%s, ',CONFIG.chan_to_rm{:}) ;
     'Manually selected time window:', sprintf('%d to %d sec',CONFIG.rawinfo.time_window(1),CONFIG.rawinfo.time_window(2));
     'Resampling (Hz):              ', CONFIG.resample_rate;
     'High-pass filter cutoff (Hz): ', CONFIG.filter_hp_cutoff;
     'Low-pass filter cutoff (Hz):  ', CONFIG.filter_lp_cutoff;
     'Rereference:                  ', CONFIG.reref_choice;});
add(chap1, Section('Title', 'Preprocessing pipeline', 'Content', table_prep));

table_clean = BaseTable( ...
    {'Bad channel removed (stat):   ', sprintf('%s ',CONFIG.prep.badchan_rejchan{:});
     'Bad channel removed (flatline):', sprintf('%s ',CONFIG.prep.badchan_flatlines{:});
     'Bad channel removed (corr):   ', sprintf('%s ',CONFIG.prep.badchan_corrnoise{:});
     'Number of clean channels:     ', CONFIG.prep.num_chan_prep; 
     'Interpolated Channels:        ', sprintf('%s ',CONFIG.prep.interp_chan{:})
     'Number of channels after preprocess:', CONFIG.prep.num_chan_total;
     });
add(chap1, Section('Title', 'Basic cleaning report', 'Content', table_clean));
add(rpt,chap1);


% Chapter
chap2 = Chapter('Advanced cleaning report ');
table_asr = BaseTable({'Artifact Subspace Reconstruction (ASR) threshold: ', num2str(CONFIG.asr_stdcutoff)});
add(chap2, Section('Title', 'ASR cleaning', 'Content', table_asr));

image_ICLabel = Image([CONFIG.report.directory filesep 'ICLabel.png']);
image_ICLabel.Style = {ScaleToFit};
add(chap2, Section('Title', 'ICA and IC classification results', 'Content', image_ICLabel));

table_ica = BaseTable(...
    {'IC rejection threshold:', num2str(CONFIG.ICrej_thres);
     'Rejected Muscle ICs:', sprintf('%d ',CONFIG.prep.ICrej_muscle);
     'Rejected Eye ICs:', sprintf('%d ',CONFIG.prep.ICrej_eye);
     'Rejected heart ICs:', sprintf('%d ',CONFIG.prep.ICrej_heart);
     'Rejected Line Noise ICs:', sprintf('%d ',CONFIG.prep.ICrej_linenoise);
     'Rejected Chan Noise ICs:', sprintf('%d ',CONFIG.prep.ICrej_channoise);
    });
add(chap2, Section('Title', 'Rejected Components', 'Content', table_ica));
add(rpt,chap2);


% Chapter
chap3 = Chapter('Band-power related measures');

% display absolute power 
image_size = {Width('1.2in')};
image_pdelta = Image([CONFIG.report.directory filesep 'power_delta.png']);
image_pdelta.Style = image_size;
image_ptheta = Image([CONFIG.report.directory filesep 'power_theta.png']);
image_ptheta.Style = image_size;
image_palpha = Image([CONFIG.report.directory filesep 'power_alpha.png']);
image_palpha.Style = image_size;
image_pbeta = Image([CONFIG.report.directory filesep 'power_beta.png']);
image_pbeta.Style = image_size;
image_pgamma = Image([CONFIG.report.directory filesep 'power_gamma.png']);
image_pgamma.Style = image_size;
table_power = BaseTable({'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'; ...
                        image_pdelta,image_ptheta,image_palpha,image_pbeta,image_pgamma});
add(chap3, Section('Title', 'Absolute power', 'Content', table_power));

% display relative power 
image_size = {Width('1.2in')};
image_rpdelta = Image([CONFIG.report.directory filesep 'rpower_delta.png']);
image_rpdelta.Style = image_size;
image_rptheta = Image([CONFIG.report.directory filesep 'rpower_theta.png']);
image_rptheta.Style = image_size;
image_rpalpha = Image([CONFIG.report.directory filesep 'rpower_alpha.png']);
image_rpalpha.Style = image_size;
image_rpbeta = Image([CONFIG.report.directory filesep 'rpower_beta.png']);
image_rpbeta.Style = image_size;
image_rpgamma = Image([CONFIG.report.directory filesep 'rpower_gamma.png']);
image_rpgamma.Style = image_size;
table_rpower = BaseTable({'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'; ...
                        image_rpdelta,image_rptheta,image_rpalpha,image_rpbeta,image_rpgamma});
add(chap3, Section('Title', 'Relative power', 'Content', table_rpower));
add(rpt,chap3);

% % display frontal alpha asymmetry
% add(chap3, Section('Title', 'Frontal alpha asymmetry'));
% if isfield(CONFIG.report,'frontal_alpha_asym_F34')
%     par1 = Paragraph(sprintf('(F3 - F4) / (F3 + F4) = %f', CONFIG.report.frontal_alpha_asym_F34));
%     add(chap3,par1);
% end
% if isfield(CONFIG.report,'frontal_alpha_asym_F78')
%     par2 = Paragraph(sprintf('(F7 - F8) / (F7 + F8) = %f', CONFIG.report.frontal_alpha_asym_F78));
%     add(chap3,par2);
% end

% chapter 4: time frequency deomposition plots
if isfield(CONFIG.report,'timefreq_plot_chan')
    if ~isempty(CONFIG.report.timefreq_plot_chan)
        % new chapter
        chap4 = Chapter('Time frequency decomposition');
        for chan_id = 1:length(CONFIG.report.timefreq_plot_chan)
            filename = sprintf('tfplot_%s.png',CONFIG.report.timefreq_plot_chan{chan_id});
            image_tfplot = Image([CONFIG.report.directory filesep filename]);
            image_tfplot.Style = {ScaleToFit};
            add(chap4, Section('Title', CONFIG.report.timefreq_plot_chan{chan_id} , 'Content', image_tfplot));
        end
        add(rpt,chap4);
    end
end

% Close the report (required)
close(rpt);
% Display the report (optional)
rptview(rpt);

end
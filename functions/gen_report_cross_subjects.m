function gen_report_cross_subjects(filepath,filename,folder_list)

% Import report API classes (optional)
import mlreportgen.report.*
import mlreportgen.dom.*

textYN = {'Y','N'};

% Add report container (required)
rpt = Report([filepath filesep filename],'pdf');

% Add content to container (required)
% Types of content added here: title 
% page and table of contents reporters
titlepg = TitlePage;
titlepg.Title = 'RESTEEG: Automated Analysis of Resting-State EEG for Clinicians';
titlepg.Author = 'Sheng-Hsiou Hsu';
add(rpt,titlepg);
add(rpt,TableOfContents);

% load CONFIG from all folders
filename_list = cell(1,length(folder_list));
CONFIG_all = cell(1,length(folder_list));
for fold_id = 1:length(folder_list)
    tmp = load([filepath filesep folder_list{fold_id} filesep 'CONFIG.mat']);
    CONFIG_all{fold_id} = tmp.CONFIG;
    filename_list{fold_id} = tmp.CONFIG.filename;
end

% Chapter 1: basic data info 
chap1 = Chapter('Dataset Information');
table_basic = BaseTable( ...
    {'File list: ', sprintf('%s, ',filename_list{:})});
add(chap1, Section('Title', 'Files included in the analysis', 'Content', table_basic));

table_prep = BaseTable( ...
    {'Manually removed channel:     ', sprintf('%s, ',CONFIG_all{1}.chan_to_rm{:}) ;
     'Resampling (Hz):              ', CONFIG_all{1}.resample_rate;
     'High-pass filter cutoff (Hz): ', CONFIG_all{1}.filter_hp_cutoff;
     'Low-pass filter cutoff (Hz):  ', CONFIG_all{1}.filter_lp_cutoff;
     'Rereference:                  ', CONFIG_all{1}.reref_choice;});
add(chap1, Section('Title', 'Preprocessing pipeline', 'Content', table_prep));

add(rpt,chap1);


% Chapter
chap2 = Chapter('Band-Power Related Measures');
freq_band_list = {'delta', 'theta', 'alpha', 'beta', 'gamma'};
table_power = Table( [ {'File'}, freq_band_list{:} ] );
% display absolute power 
image_size = {Width('1in')};
for file_id = 1:length(folder_list)
    row = TableRow;
    append(row, TableEntry(filename_list{file_id}));
    for fid = 1:length(freq_band_list)
        image_power = Image([CONFIG_all{file_id}.report.directory filesep 'power_' freq_band_list{fid} '.png']);
        image_power.Style = image_size;
        append(row, TableEntry(image_power));
    end
    append(table_power,row);
end
add(chap2, Section('Title', 'Absolute power', 'Content', table_power));

% display relative power 
table_rpower = Table( [ {'File'}, freq_band_list{:} ] );
for file_id = 1:length(folder_list)
    row = TableRow;
    append(row, TableEntry(filename_list{file_id}));
    for fid = 1:length(freq_band_list)
        image_rpower = Image([CONFIG_all{file_id}.report.directory filesep 'rpower_' freq_band_list{fid} '.png']);
        image_rpower.Style = image_size;
        append(row, TableEntry(image_rpower));
    end
    append(table_rpower,row);
end
add(chap2, Section('Title', 'Relative power', 'Content', table_rpower));


% display frontal alpha asymmetry
table_frontAA = Table({'File','   (F3 - F4) / (F3 + F4)   ','   (F7 - F8) / (F7 + F8)   '});
table_frontAA.TableEntriesHAlign = 'center';
for file_id = 1:length(folder_list)
    row = TableRow;
    append(row, TableEntry(filename_list{file_id}));
    append(row, TableEntry(num2str(CONFIG_all{file_id}.report.frontal_alpha_asym_F34)));
    append(row, TableEntry(num2str(CONFIG_all{file_id}.report.frontal_alpha_asym_F78)));
    append(table_frontAA,row);
end
table_frontAA.ColSep = 'single';
add(chap2, Section('Title', 'Frontal alpha asymmetry', 'Content', table_frontAA));

add(rpt,chap2);


% Close the report (required)
close(rpt);
% Display the report (optional)
rptview(rpt);

end
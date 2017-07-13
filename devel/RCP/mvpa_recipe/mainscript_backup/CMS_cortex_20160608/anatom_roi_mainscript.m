clear
clc
format compact

aname = 'anatom_roi_VTC';

config_options.name = aname;
config_options.dataset = 'ESWS';%Del_MCQ/Aro_MCQ
config_options.rawdata_type = 'anatom'; % 'estimatedHDR_spm' | 'unsmoothed_raw' |'LSS_eHDR'
config_options.analysis = 'roi';
config_options.analysis_method = 'classification';
config_options.behavioral_measure = 'allstim';
config_options.behavioral_transformation = 'origin_split';
config_options.TRlag = 0;% ZEROED OUT
config_options.TR_avg_window = 0;% ZEROED OUT
config_options.searchlight_radius = 1.5;
config_options.classifier = @knn;
config_options.result_dir = aname;


options = set_options(config_options);
%settings for anatom
options.lag_type = 'single'; %'single' | %'average'


preproc_data_file_pointers = load(fullfile(options.preproc_data_dir,'preproc_data_file_pointers'));
preproc_data_file_pointers = preproc_data_file_pointers.preproc_data_file_pointers;


primary_analysis_output = mvpa(subj_filepointers,options); 
save(fullfile(options.save_dir,options.classification_fname),'primary_analysis_output','options')

statistics_output = summarize_mvpa(primary_analysis_output,options); 
save(fullfile(options.save_dir,options.statistics_fname),'statistics_output','primary_analysis_output','options');

jk_get_permstats(statistics_output,primary_analysis_output,options) 
jk_mkfig_from_perm(options) 
jk_mkfig_4MCC_from_perm(options) 

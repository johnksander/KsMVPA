clear 
clc
format compact

% 
% config_options.name = 'prev_analysis_origSPM5';
% config_options.dataset = 'SPM5_Del_MCQ';%Del_MCQ/Aro_MCQ
% config_options.analysis = 'roi';%loso, preprocess w/e
% config_options.TRlag = 1;%TR lag
% config_options.TR_avg_window = 2;%TR window to average over
% config_options.classifier = @minpool;
% config_options.result_dir = 'prev_analysis_origSPM5';
% 
% 
% options = SPM5test_set_options(config_options);
% 
% preproc_data_file_pointers = preprocess_data(options);

% 
% config_options.name = 'prev_analysis_origSPM5';
% config_options.dataset = 'SPM5_Del_MCQ';%Del_MCQ/D
% config_options.analysis = 'roi';%loso, preprocess w/e
% config_options.TRlag = 1;%TR lag
% config_options.TR_avg_window = 2;%TR window to average over
% config_options.classifier = @minpool;
% config_options.result_dir = 'prev_analysis_origSPM5';
% 
% 
% options = SPM5test_set_options(config_options);
% subj_filepointers = load_filepointers(options);
% 
% primary_analysis_output = mvpa(subj_filepointers,options); 
% save(fullfile(options.save_dir,options.classification_fname),'primary_analysis_output','options')
% 
% statistics_output = summarize_mvpa(primary_analysis_output,options); 
% save(fullfile(options.save_dir,options.statistics_fname),'statistics_output','primary_analysis_output','options');
% 
% jk_get_permstats(statistics_output,primary_analysis_output,options) 
% jk_mkfig_from_perm(options) 
% jk_mkfig_4MCC_from_perm(options) 

config_options.name = 'prev_analysis_origSPM5_OP_delay2';
config_options.dataset = 'SPM5_Del_MCQ';%Del_MCQ/D
config_options.analysis = 'roi';%loso, preprocess w/e
config_options.TRlag = 2;%TR lag
config_options.TR_avg_window = 2;%TR window to average over
config_options.classifier = @minpool;
config_options.result_dir = 'prev_analysis_origSPM5';


options = SPM5test_set_options(config_options);
options.preproc_data_dir = '/home/ksander/previous_MCQD_preproc4mpva_data/unwhitened_roi_dir_03302015';
load(fullfile(options.preproc_data_dir,'file_pointers.mat'))
subj_filepointers = roi_subject_file_pointers;
% subj_filepointers = load_filepointers(options);

primary_analysis_output = mvpa(subj_filepointers,options); 
save(fullfile(options.save_dir,options.classification_fname),'primary_analysis_output','options')

statistics_output = summarize_mvpa(primary_analysis_output,options); 
save(fullfile(options.save_dir,options.statistics_fname),'statistics_output','primary_analysis_output','options');

jk_get_permstats(statistics_output,primary_analysis_output,options) 
jk_mkfig_from_perm(options) 
jk_mkfig_4MCC_from_perm(options) 



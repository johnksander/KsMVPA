clear 
clc
format compact

aname = 'prev_analysis_wSPM8_L3W2_90pca';

config_options.name = aname;
config_options.dataset = 'Del_MCQ';%Del_MCQ/D
config_options.analysis = 'roi';%loso, preprocess w/e
config_options.TRlag = 3;%TR lag
config_options.TR_avg_window = 2;%TR window to average over
config_options.classifier = @minpool;
config_options.result_dir = aname;

options = set_options(config_options);
options.PCAcomponents2keep = .90;
subj_filepointers = load_filepointers(options);

primary_analysis_output = mvpa(subj_filepointers,options); 
save(fullfile(options.save_dir,options.classification_fname),'primary_analysis_output','options')

statistics_output = summarize_mvpa(primary_analysis_output,options); 
save(fullfile(options.save_dir,options.statistics_fname),'statistics_output','primary_analysis_output','options');

jk_get_permstats(statistics_output,primary_analysis_output,options) 
jk_mkfig_from_perm(options) 
jk_mkfig_4MCC_from_perm(options) 





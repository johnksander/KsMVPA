clear 
clc
format compact

aname = 'test';

config_options.name = aname;
config_options.dataset = 'Del_MCQ';%Del_MCQ/D
config_options.analysis = 'roi';%loso, preprocess w/e
config_options.behavioral_measure = 'complete_file'; %vividness %complete_file
config_options.crossval_method = 'random_bag'; %runwise
config_options.TRlag = 2;%TR lag
config_options.TR_avg_window = 2;%TR window to average over
config_options.classifier = @minpool;
config_options.result_dir = aname;


options = set_options(config_options);
%options.which_behavior = 3; only specify for complete_file behavioral measure
%which_behavior 1 = conf, 2 = vivid, 3 = feel, 4 = order, 5 = thoughts
subj_filepointers = load_filepointers(options);

primary_analysis_output = mvpa(subj_filepointers,options); 
save(fullfile(options.save_dir,options.classification_fname),'primary_analysis_output','options')

statistics_output = summarize_mvpa(primary_analysis_output,options); 
save(fullfile(options.save_dir,options.statistics_fname),'statistics_output','primary_analysis_output','options');

jk_get_permstats(statistics_output,primary_analysis_output,options) 
jk_mkfig_from_perm(options) 
jk_mkfig_4MCC_from_perm(options) 

clear
clc
format compact

aname = 'ESWS_LOSO_SL_LSS_knn_r1p5';
preallocate_SLrois = 'load'; % 'run' | 'load'
num_workers = 16; %parpool workers

config_options.name = aname;
config_options.dataset = 'ESWS';%Del_MCQ/Aro_MCQ
config_options.rawdata_type = 'LSS_eHDR'; % 'estimatedHDR_spm' | 'unsmoothed_raw' |'LSS_eHDR'
config_options.analysis = 'LOSO_SL';
config_options.analysis_method = 'classification';
config_options.behavioral_measure = 'allstim';
config_options.behavioral_transformation = 'origin_split';
config_options.TRlag = 0;% ZEROED OUT
config_options.TR_avg_window = 0;% ZEROED OUT
config_options.searchlight_radius = 1.5;
config_options.classifier = @knn;
config_options.result_dir = aname;


options = set_options(config_options);
%settings for LSS_eHDR
options.lag_type = 'single'; %'single' | %'average'





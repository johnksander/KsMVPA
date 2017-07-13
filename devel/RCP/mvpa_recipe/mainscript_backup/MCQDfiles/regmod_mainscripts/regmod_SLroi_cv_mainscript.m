clear 
clc
format compact

aname = 'SL_regmod_cv';

config_options.name = aname;
config_options.use_regmodeling = 'on';
config_options.dataset = 'Del_MCQ';%Del_MCQ/D
config_options.analysis = 'roi';%loso, preprocess w/e
config_options.behavioral_measure = 'short_delay_complete_file'; %vividness %complete_file
config_options.crossval_method = 'runwise'; %runwise
config_options.TRlag = 1;%TR lag
config_options.TR_avg_window = 2;%TR window to average over
config_options.classifier = @minpool;
config_options.result_dir = aname;


options = set_options(config_options);
options.which_behavior = 1:2; %only specify for complete_file behavioral measure
options.searchlight_radius = 1;
brain_cells = regmod_cv_roi_searchlight(options);
save(fullfile(options.save_dir,[options.name '_braincells']),'brain_cells','options')



%which_behavior 1 = conf, 2 = vivid, 3 = feel, 4 = order, 5 = thoughts
%subj_filepointers = load_filepointers(options);

%primary_analysis_output = regression_model(subj_filepointers,options); 


% 
% %primary_analysis_output = mvpa(subj_filepointers,options); 
% save(fullfile(options.save_dir,options.classification_fname),'primary_analysis_output','options')
% 
% statistics_output = summarize_mvpa(primary_analysis_output,options); 
% save(fullfile(options.save_dir,options.statistics_fname),'statistics_output','primary_analysis_output','options');
% 
% jk_get_permstats(statistics_output,primary_analysis_output,options) 
% jk_mkfig_from_perm(options) 
% jk_mkfig_4MCC_from_perm(options) 





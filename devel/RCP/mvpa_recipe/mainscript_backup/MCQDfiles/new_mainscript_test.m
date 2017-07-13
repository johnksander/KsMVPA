classification_output_name = 'LOSO_test_nofs_output'; %must change output variable line 21 to this
statistics_output_name = 'LOSO_test_nofs_statistics'; %must change output variable line 24 to this
%must change filepointer var in line 20 according to roi/LOSO
%must change summarize_mvpa(X,options) to output variable
%must change analysis function on line 21 according to LOSO/roi

% ROI Preprocess
options = set_options_from_params('LOSO',2,@minpool,'single','LOSO_test_nofs');
%roi_subject_file_pointers = preprocess_data(options);
%save(fullfile(options.output_dir,'file_pointers'),'roi_subject_file_pointers');
load(fullfile(options.output_dir,'file_pointers')) %must be put within options/analysis script (NEW)
addpath(fullfile(options.script_dir,'stat_functions','jk_getstats'))

%analysis & save output---- make sure to change mvpa function & filepointer input
LOSO_test_nofs_output = LOSO_roi_mvpa(LOSO_subject_file_pointers,options); %CHANGE subj filepointer name for roi/LOSO
save(fullfile(options.save_dir,classification_output_name),classification_output_name,'options')

%stats % save
LOSO_test_nofs_statistics = summarize_mvpa(LOSO_test_nofs_output,options); 
save(fullfile(options.script_dir,'stat_functions','jk_getstats',statistics_output_name),classification_output_name,statistics_output_name,'options');

cd(fullfile(options.script_dir,'stat_functions','jk_getstats'))
rois = {'left hipp', 'right hipp', 'left amyg', 'right amyg', 'left pHc', 'right pHc' };
jk_get_permstats(rois,LOSO_test_nofs_statistics,LOSO_test_nofs_output,'LOSO_test_nofs_perm_stats') 
clear LOSO_test_nofs_output
clear LOSO_test_nofs_statistics

jk_mkfig_from_perm('nofs_test','LOSO_test_nofs_perm_stats',options) %fig file savename, permed stat output file (both strings)



%------------------------------------------

config_options.name = 'test_pipeline';
config_options.dataset = 'Del_MCQ';%Del_MCQ/D
config_options.analysis = 'roi';%loso, preprocess w/e
config_options.TRlag = 3;%TR lag
config_options.TR_avg_window = 2;%TR window to average over
config_options.classifier = @minpool;
config_options.result_dir = 'where/the/results/go';

primary_analysis_output = LOSO_roi_mvpa(LOSO_subject_file_pointers,options); %ADD filepointer business to options/analysis script
save(fullfile(options.save_dir,options.classification_fname),primary_analysis_output,'options')


statistics_output = summarize_mvpa(primary_analysis_output,options); 
save(fullfile(options.save_dir,options.statistics_fname),statistics_output,primary_analysis_output,'options');


jk_get_permstats(options.rois4fig,statistics_output,primary_analysis_output,options.permstats_fname) 
jk_mkfig_from_perm(options.figure_fname,options.permstats_fname,options) %fig file savename, permed stat output file (both strings)

%save all files to options.save_dir, figure & output functions must be
%modified for this.. 

%basic file structure should be.. 

%vividness_mvpa/ (main_dir)

%results/
%mvpa_recipe/(main script_dir)

%Data/ (all mvpa data)
%/Data/preprocessed_scan_data/
%/Aro_MCQ/
%/Del_MCQ/
%/LOSO
%/roi
%/TRfiles

%SPMdatasets/
%SPMdatasets/Del_MCQ/(all SPM data)
%SPMdatasets/Aro_MCQ/(all SPM data) 




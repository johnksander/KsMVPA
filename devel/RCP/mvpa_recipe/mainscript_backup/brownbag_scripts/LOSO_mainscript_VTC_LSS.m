clear
clc
format compact

aname = 'ESWS_LOSO_VTC_LSS_MP';

config_options.name = aname;
config_options.dataset = 'ESWS';%Del_MCQ/Aro_MCQ
config_options.rawdata_type = 'estimatedHDR_spm'; % 'estimatedHDR_spm' | 'unsmoothed_raw' |'LSS_eHDR'
config_options.analysis = 'LOSO';
config_options.analysis_method = 'classification';
config_options.behavioral_measure = 'allstim';
config_options.behavioral_transformation = 'origin_split';
config_options.TRlag = 0;% ZEROED OUT
config_options.TR_avg_window = 0;% ZEROED OUT
config_options.lag_type = 'single'; %'single' | %'average'
config_options.searchlight_radius = 4;
config_options.classifier = @RelVec;
config_options.result_dir = aname;


options = set_options(config_options);
options.roi_list = {'left_vtc.nii','right_vtc.nii'};   
options.rois4fig = {'left_vtc','right_vtc'}; 
options.RVint = 'on';
options.RVcsum_pred = 'off'; %cumulative subject prediction


preproc_data_file_pointers = load(fullfile(options.preproc_data_dir,'preproc_data_file_pointers'));
preproc_data_file_pointers = preproc_data_file_pointers.preproc_data_file_pointers;

predictions = LOSO_roi_mvpa(preproc_data_file_pointers,options);


save(fullfile(options.save_dir,[options.name '_predictions']),'predictions','options')




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





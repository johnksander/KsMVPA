clear
clc
format compact

aname = 'ESWS_LOSO_anatom_VTC_knn';
 
config_options.name = aname;
config_options.dataset = 'ESWS';%Del_MCQ/Aro_MCQ
config_options.rawdata_type = 'anatom'; % 'estimatedHDR_spm' | 'unsmoothed_raw' |'LSS_eHDR' | 'anatom'
config_options.analysis = 'LOSO';
config_options.analysis_method = 'classification';
config_options.behavioral_measure = 'allstim';
config_options.behavioral_transformation = 'origin_split';
config_options.TRlag = 0;%TR lag
config_options.TR_avg_window = 0;%TR window to average over
config_options.lag_type = 'single'; %'single' | %'average'
config_options.searchlight_radius = 1.5;
config_options.classifier = @knn;
config_options.result_dir = aname;


options = set_options(config_options);
%settings for perm anatom
options.permutation_classifer_testing = 'off';
%options.num_perms2test = 100000;
options.scans_per_run = 1; 
options.roi_list = {'left_vtc.nii','right_vtc.nii'};   
options.rois4fig = {'left_vtc','right_vtc'};  
  
 

preproc_data_file_pointers = load(fullfile(options.preproc_data_dir,'preproc_data_file_pointers'));
preproc_data_file_pointers = preproc_data_file_pointers.preproc_data_file_pointers;

predictions = LOSO_roi_mvpa(preproc_data_file_pointers,options);

save(fullfile(options.save_dir,[options.name '_predictions']),'predictions','options')



for idx = 1:numel(options.roi_list)
    roi_pred = predictions(:,idx);
    roi_pred = vertcat(roi_pred{:});
    roi_pred = (sum(roi_pred(:,1) == roi_pred(:,2))) / numel(roi_pred(:,1));
    disp(sprintf('%s classification accuracy %.2f%% \n',options.rois4fig{idx},(roi_pred*100))) 
end




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




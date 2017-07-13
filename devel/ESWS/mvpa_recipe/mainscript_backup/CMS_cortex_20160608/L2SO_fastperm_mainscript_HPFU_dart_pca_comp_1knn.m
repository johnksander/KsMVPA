clear
clc
format compact

aname = 'ESWS_L2SO_fastperm_HPFU_dart_comp_pca_1knn';
num_workers = 4; %parpool workers

config_options.name = aname;
config_options.dataset = 'ESWS';%Del_MCQ/Aro_MCQ
config_options.rawdata_type = 'dartel_raw'; % 'estimatedHDR_spm' | 'unsmoothed_raw' |'LSS_eHDR' | 'anatom'
config_options.analysis = 'LOSO';
config_options.analysis_method = 'classification';
config_options.behavioral_measure = 'memory';
config_options.behavioral_transformation = 'origin_split';
config_options.TRlag = 2;%TR lag
config_options.TR_avg_window = 2;%TR window to average over
config_options.lag_type = 'average'; %'single' | %'average'
config_options.searchlight_radius = 1.5;
config_options.classifier = @knn;
config_options.result_dir = aname;


options = set_options(config_options);
%settings for perm L2SO 
options.unique_jobID = randjobID(); %get random letter squence for ID 
options.permutation_classifer_testing = 'on';
options.num_perms2test = 10000;
options.trial_temporal_compression = 'on';
options.feature_selection = 'pca_only';
options.exclusions = [115 202 208];
options.roi_list = {'left_fusiformHO.nii','right_fusiformHO.nii','left_hippocampus.nii','right_hippocampus.nii'};   
options.rois4fig = {'left_fusiform','right_fusiform','left_hippocampus','right_hippocampus'};  

preproc_data_file_pointers = load(fullfile(options.preproc_data_dir,'preproc_data_file_pointers'));
preproc_data_file_pointers = preproc_data_file_pointers.preproc_data_file_pointers;

classifer_file = fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m']);
parpool(num_workers,'AttachedFiles',{classifer_file})

predictions = L2SO_roi_parfor_fastperm_mvpa(preproc_data_file_pointers,options);

delete(gcp('nocreate'))

%save
save(fullfile(options.save_dir,[options.name '_' options.unique_jobID]),'predictions','options')



% for idx = 1:numel(options.roi_list)
%     roi_pred = predictions(:,idx);
%     roi_pred = vertcat(roi_pred{:});
%     roi_pred = (sum(roi_pred(:,1) == roi_pred(:,2))) / numel(roi_pred(:,1));
%     disp(sprintf('%s classification accuracy %.2f%% \n',options.rois4fig{idx},(roi_pred*100))) 
% end

% acc = load('ESWS_LOSO_anatom_VTC_MP_predictions.mat'); %true labels 
% acc = acc.predictions; 
% perm_mat = load('ESWS_LOSO_perm_anatom_VTC_predictions.mat');
% perm_mat = perm_mat.predictions;
% ci_range = 90;
% 
% for idx = 1:numel(options.roi_list)
%     
%     true_acc = acc(:,idx);
%     true_acc = vertcat(true_acc{:});
%     true_acc = sum(true_acc(:,1) == true_acc(:,2)) / numel(true_acc(:,1));
%     curr_roi_perms = perm_mat(:,idx);
%     gt_matrix = bsxfun(@gt,curr_roi_perms,true_acc);
%     p_values = (sum(gt_matrix) + 1) ./ (options.num_perms2test + 1); %adjust for 0 p-values
%     ci_low = 50 - ci_range/2;
%     ci_high = 100 - ci_low;
%     ci = cat(1,prctile(curr_roi_perms,ci_low),prctile(curr_roi_perms,ci_high));
%     
%     disp(sprintf('ROI: %s accuracy = %.3f, p = %.3f',options.rois4fig{idx},true_acc,p_values))
% end



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





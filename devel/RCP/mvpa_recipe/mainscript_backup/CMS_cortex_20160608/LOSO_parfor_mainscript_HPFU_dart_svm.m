clear
clc
format compact

aname = 'ESWS_LOSO_HPFU_dart_MP_PCA_comp';
num_workers = 4; %parpool workers

config_options.name = aname;
config_options.dataset = 'ESWS';%Del_MCQ/Aro_MCQ
config_options.rawdata_type = 'dartel_raw'; % 'estimatedHDR_spm' | 'unsmoothed_raw' |'LSS_eHDR'
config_options.analysis = 'LOSO';
config_options.analysis_method = 'classification';
config_options.behavioral_measure = 'memory';
config_options.behavioral_transformation = 'origin_split';
config_options.TRlag = 2;
config_options.TR_avg_window = 2;
config_options.lag_type = 'average'; %'single' | %'average'
config_options.searchlight_radius = 4;
config_options.classifier = @svm;
config_options.result_dir = aname;


options = set_options(config_options);
%options.roi_list = {'left_hippocampus.nii','right_hippocampus.nii','left_fusiform.nii','right_fusiform.nii'};   
%options.rois4fig = {'left_hippocampus','right_hippocampus','left_fusiform','right_fusiform'};  
options.roi_list = {'left_fusiformHO.nii','right_fusiformHO.nii','left_hippocampus.nii','right_hippocampus.nii'};   
options.rois4fig = {'left_fusiform','right_fusiform','left_hippocampus','right_hippocampus'};  

options.trial_temporal_compression = 'off';
options.feature_selection = 'pca_only';
options.exclusions = [115 202 208];

preproc_data_file_pointers = load(fullfile(options.preproc_data_dir,'preproc_data_file_pointers'));
preproc_data_file_pointers = preproc_data_file_pointers.preproc_data_file_pointers;

classifer_file = fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m']);
parpool(num_workers,'AttachedFiles',{classifer_file})

predictions = LOSO_roi_parfor_mvpa(preproc_data_file_pointers,options);
delete(gcp('nocreate'))

save(fullfile(options.save_dir,[options.name '_predictions']),'predictions','options')


for idx = 1:numel(options.roi_list)
    roi_pred = predictions(:,idx);
    roi_pred = vertcat(roi_pred{:});
    roi_pred = (sum(roi_pred(:,1) == roi_pred(:,2))) / numel(roi_pred(:,1));
    disp(sprintf('%s classification accuracy %.2f%% \n',options.rois4fig{idx},(roi_pred*100))) 
end

for idx = 1:numel(options.roi_list)
    roi_pred = predictions(:,idx);
    roi_pred = vertcat(roi_pred{:});
    figure(idx)
    imagesc(roi_pred)
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

% options.roi_list = {'left_anterior_TL_medial.nii','right_anterior_TL_medial.nii','left_TL_lateral.nii','right_TL_lateral.nii',...
%         'left_superior_TL_posterior.nii', 'right_superior_TL_posterior.nii', 'left_middle_and_inferior_TG.nii',...
%         'right_middle_and_inferior_TG.nii','left_posterior_TL.nii','right_posterior_TL.nii',...
%         'left_superior_TG_anterior.nii','right_superior_TG_anterior.nii'};  
% 
% options.rois4fig = {'left_anterior_TL_medial','right_anterior_TL_medial','left_TL_lateral','right_TL_lateral',...
%         'left_superior_TL_posterior', 'right_superior_TL_posterior', 'left_middle_and_inferior_TG',...
%         'right_middle_and_inferior_TG','left_posterior_TL','right_posterior_TL',...
%         'left_superior_TG_anterior','right_superior_TG_anterior'};  
% 
% 
% 

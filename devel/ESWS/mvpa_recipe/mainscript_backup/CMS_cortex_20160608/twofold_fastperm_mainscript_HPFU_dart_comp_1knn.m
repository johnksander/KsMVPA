clear
clc
format compact

aname = 'ESWS_twofold_fastperm_HPFU_dart_comp_1knn';
num_workers = 4; %parpool workers

config_options.name = aname;
config_options.dataset = 'ESWS';%Del_MCQ/Aro_MCQ
config_options.rawdata_type = 'dartel_raw'; % 'estimatedHDR_spm' | 'unsmoothed_raw' |'LSS_eHDR'
config_options.analysis = 'LOSO';
config_options.analysis_method = 'classification';
config_options.behavioral_measure = 'memory';
config_options.behavioral_transformation = 'origin_split';
config_options.TRlag = 2; %TR lag
config_options.TR_avg_window = 2; %TR window to average over
config_options.lag_type = 'average'; %'single' | %'average'
config_options.searchlight_radius = 4;
config_options.classifier = @knn; %switched for knn testing
config_options.result_dir = aname;


options = set_options(config_options);
%settings for twofold perm
options.unique_jobID = randjobID(); %get random letter squence for ID 
options.permutation_classifer_testing = 'on';
options.num_perms2test = 10000;
options.trial_temporal_compression = 'on';
options.feature_selection = 'off';
options.exclusions = [115 202 208];
%make sure it's fusiformHO, for harvard-oxford
options.roi_list = {'left_fusiformHO.nii','right_fusiformHO.nii','left_hippocampus.nii','right_hippocampus.nii'};
options.rois4fig = {'left_fusiform','right_fusiform','left_hippocampus','right_hippocampus'};  

preproc_data_file_pointers = load(fullfile(options.preproc_data_dir,'preproc_data_file_pointers'));
preproc_data_file_pointers = preproc_data_file_pointers.preproc_data_file_pointers;

classifer_file = fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m']);
parpool(num_workers,'AttachedFiles',{classifer_file})

predictions = twofold_roi_parfor_fastperm_mvpa(preproc_data_file_pointers,options);
delete(gcp('nocreate'))

%save
save(fullfile(options.save_dir,[options.name '_' options.unique_jobID]),'predictions','options')






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

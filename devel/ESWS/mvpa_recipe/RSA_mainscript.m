clear
clc
format compact

aname = 'ESWS_RSA_HPFU_dart_test';
%num_workers = 4; %parpool workers

config_options.name = aname;
config_options.dataset = 'ESWS';%Del_MCQ/Aro_MCQ
config_options.rawdata_type = 'LSS_eHDR'; % 'estimatedHDR_spm' | 'unsmoothed_raw' |'LSS_eHDR' | 'dartel_raw'
config_options.analysis = 'LOSO';
config_options.analysis_method = 'classification';
config_options.behavioral_measure = 'memory';
config_options.behavioral_transformation = 'origin_split';
config_options.TRlag = 0;
config_options.TR_avg_window = 0;
config_options.lag_type = 'single'; %'single' | %'average'
config_options.searchlight_radius = 4;
config_options.classifier = @minpool;
config_options.result_dir = aname;


options = set_options(config_options);
%options.roi_list = {'left_hippocampus.nii','right_hippocampus.nii','left_fusiform.nii','right_fusiform.nii'};   
%options.rois4fig = {'left_hippocampus','right_hippocampus','left_fusiform','right_fusiform'};  
options.roi_list = {'left_fusiformHO.nii','right_fusiformHO.nii','left_hippocampus.nii','right_hippocampus.nii'};   
options.rois4fig = {'left_fusiform','right_fusiform','left_hippocampus','right_hippocampus'};  

options.trial_temporal_compression = 'on';
options.feature_selection = 'off';
options.exclusions = [115 202 208];
options.RDM_dist_metric = 'spearman'; %euclid spearman


%load correct ROI filepointers
preproc_data_file_pointers = PreprocDataFP_handler(options,[],'load'); 

%classifer_file = fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m']);
%parpool(num_workers,'AttachedFiles',{classifer_file})

RSAoutput = RSA_roi(preproc_data_file_pointers,options);
%delete(gcp('nocreate'))
save(fullfile(options.save_dir,[options.name '_output']),'RSAoutput','options')


clear
clc
format compact

aname = 'LOSO_ROI_searchlight_followup_svm_rbf_noCBR_perm';
num_workers = 4; %parpool workers

%----name---------------------------------------------------
config_options.name = aname;
config_options.result_dir = aname;
%----experiment---------------------------------------------
config_options.dataset = 'ESWS';
%----analysis-----------------------------------------------
config_options.analysis = 'LOSO';
config_options.CVscheme = 'OneOut';
config_options.trial_temporal_compression = 'runwise'; 
config_options.feature_selection = 'off';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom' 
config_options.LSSid = 'ASGM10'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 0;
config_options.roi_list = {'significant_searchlights.nii'};   
config_options.rois4fig = {'significant_searchlights'};  
%----TR-settings--------------------------------------------
config_options.TR_delay = 0;
config_options.TR_avg_window = 0;
config_options.remove_endrun_trials = 2;
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'origin_split';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = @svm;  %note for knn, use options.knn_neighbors = 5; & pca I guess 
%----------------------------------------------------------- 
options = set_options(config_options);
options.parforlog = 'on';
options.num_perms = 15000;



%load correct ROI filepointers
preproc_data_file_pointers = PreprocDataFP_handler(options,[],'load'); 

classifer_file = fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m']);
c = parcluster('local');
c.NumWorkers = num_workers;
parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',{classifer_file})

null_accuracies = LOSO_roi_parfor_perm_mvpa(preproc_data_file_pointers,options);
delete(gcp('nocreate'))

save(fullfile(options.save_dir,[options.name '_null']),'null_accuracies','options')


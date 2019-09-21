clear
clc
format compact

aname = 'LOSO_SL_memoryASGMmodel_test';
num_workers = 32; %parpool workers

%----name---------------------------------------------------
config_options.name = aname;
config_options.result_dir = aname;
%----experiment---------------------------------------------
config_options.dataset = 'ESWS';
%----analysis-----------------------------------------------
config_options.analysis = 'LOSO_SL';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom' 
config_options.LSSid = 'ASGM'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 1.5;
%----TR-settings--------------------------------------------
config_options.TR_delay = 0;
config_options.TR_avg_window = 0;
config_options.remove_endrun_trials = 2;
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'origin_split';
config_options.behavioral_measure = 'memory';
%----classifier---------------------------------------------
config_options.classifier = @knn;
%-----------------------------------------------------------
 
options = set_options(config_options);
options.roi_list = {'gray_matter.nii'};   
options.rois4fig = {'gray_matter'};  
options.parforlog = 'off';
options.trial_temporal_compression = 'on'; 
options.feature_selection = 'off';
options.RDM_dist_metric = 'spearman';


classifer_file = fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m']);
c = parcluster('local');
c.NumWorkers = num_workers;
parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',{classifer_file})

[brain_cells,searchlight_results] = RSA_SL_bigmem(options);
delete(gcp('nocreate'))


save(fullfile(options.save_dir,[options.name '_braincells']),'brain_cells','searchlight_results','options')
results_brain2nii(options)




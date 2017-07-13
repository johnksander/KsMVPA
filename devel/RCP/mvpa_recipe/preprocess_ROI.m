clear 
clc
format compact


aname = 'RCP_ROI_voxpreproc';

%----name---------------------------------------------------
config_options.name = aname;
config_options.result_dir = aname;
%----experiment---------------------------------------------
config_options.dataset = 'RCP';
%----analysis-----------------------------------------------
config_options.analysis = 'searchlight'; %just so correct data is loaded... 
config_options.CVscheme = 'oddeven';
config_options.normalization = 'runwise';
config_options.trial_temporal_compression = 'off'; 
config_options.feature_selection = 'off';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom' 
config_options.LSSid = 'RGM'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 1.5;
config_options.roi_list = {'MTL_left.nii',  'MTL_right.nii'};   
config_options.rois4fig = {'MTL_left',  'MTL_right'};  
%----TR-settings--------------------------------------------
config_options.TR_delay = 0;
config_options.TR_avg_window = 0;
config_options.remove_endrun_trials = 0;
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'encoding_valence';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = @GNB; %only matters for adding GNB func paths
config_options.performance_stat = 'Fscore'; %accuracy | Fscore
%----------------------------------------------------------- 
options = set_options(config_options);
options.parforlog = 'off';
%options.rois2process = {'MTL_left.nii',  'MTL_right.nii'};



options = set_options(config_options);



preproc_data_file_pointers = preprocess_ROI_from_SL(options);


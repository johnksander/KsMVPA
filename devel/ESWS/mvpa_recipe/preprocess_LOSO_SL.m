clear 
clc
format compact


aname = 'LOSO_SL_preproc';

%----name---------------------------------------------------
config_options.name = aname;
config_options.result_dir = aname;
%----experiment---------------------------------------------
config_options.dataset = 'ESWS';
%----analysis-----------------------------------------------
config_options.analysis = 'LOSO_SL';
config_options.CVscheme = 'OneOut';
config_options.trial_temporal_compression = 'on'; 
config_options.feature_selection = 'off';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom' 
config_options.LSSid = 'ASGM10'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 1.5;
config_options.roi_list = {'gray_matter_10thr.nii'};   
config_options.rois4fig = {'gray_matter'};  
%----TR-settings--------------------------------------------
config_options.TR_delay = 0;
config_options.TR_avg_window = 0;
config_options.remove_endrun_trials = 2;
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'origin_split';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = @GNB; %only matters for adding GNB func paths  
%----------------------------------------------------------- 
options = set_options(config_options);  


preproc_data_file_pointers = LOSO_SL_preprocess_data(options);
clear 
clc
format compact


aname = 'RCP_LOSO_voxpreproc';
num_workers = 4; %parpool workers

%----name---------------------------------------------------
config_options.name = aname;
config_options.result_dir = aname;
%----experiment---------------------------------------------
config_options.dataset = 'RCP';
%----analysis-----------------------------------------------
config_options.analysis = 'LOSO';
config_options.CVscheme = 'OneOut';
config_options.trial_temporal_compression = 'off'; 
config_options.feature_selection = 'off';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'unsmoothed_raw'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom' 
config_options.LSSid = 'RGM'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 0;
config_options.roi_list = {'gray_matter.nii'};   
config_options.rois4fig = {'gray_matter'};  
%----TR-settings--------------------------------------------
config_options.TR_delay = 0;
config_options.TR_avg_window = 0;
config_options.remove_endrun_trials = 0;
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'none';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = @GNB;  
config_options.performance_stat = 'none';
%----------------------------------------------------------- 
options = set_options(config_options);
options.parforlog = 'off';



options = set_options(config_options);



preproc_data_file_pointers = LOSO_preprocess_data(options);


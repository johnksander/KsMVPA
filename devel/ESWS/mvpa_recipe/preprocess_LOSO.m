clear 
clc
format compact


aname = 'test';
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
config_options.roi_list = {'signficiant_searchlights.nii'};   
config_options.rois4fig = {'significant_searchlights'};  
%----TR-settings--------------------------------------------
config_options.TR_delay = 0;
config_options.TR_avg_window = 0;
config_options.remove_endrun_trials = 2;
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'origin_split';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = @GNB;  
%----------------------------------------------------------- 
options = set_options(config_options);
options.parforlog = 'off';



options = set_options(config_options);



preproc_data_file_pointers = LOSO_preprocess_data(options);


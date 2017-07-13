clear
clc
format compact


resname = 'RSA_SL_1p5_ASGM_encodingValence';
permname = [resname '_stats'];

%----name---------------------------------------------------
config_options.name = permname;
config_options.result_dir = permname;
%----experiment---------------------------------------------
config_options.dataset = 'RCP';
%----analysis-----------------------------------------------
config_options.analysis = 'searchlight';
config_options.CVscheme = 'none';
config_options.normalization = 'runwise';
config_options.trial_temporal_compression = 'off'; 
config_options.feature_selection = 'off';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom' 
config_options.LSSid = 'ASGM'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 1.5;
config_options.roi_list = {'gray_matter.nii'};   
config_options.rois4fig = {'gray_matter'};  
%----TR-settings--------------------------------------------
config_options.TR_delay = 0;
config_options.TR_avg_window = 0;
config_options.remove_endrun_trials = 0;
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'encoding_valence';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = @GNB; %only matters for adding GNB func paths
config_options.performance_stat = 'none'; %accuracy | Fscore
%----------------------------------------------------------- 
options = set_options(config_options);
options.parforlog = 'off';
options.RDM_dist_metric = 'spearman';
options.num_perms = 100;


%here's the statistics 
voxel_null = load(fullfile(options.save_dir,[options.name '_voxel_null']));
voxel_null = voxel_null.voxel_null;
searchlight_results = load(fullfile(options.home_dir,'Results',resname,[resname '_braincells.mat']));
searchlight_results = searchlight_results.searchlight_cells;
searchlight_stats = map_searchlight_significance(searchlight_results,voxel_null,options);









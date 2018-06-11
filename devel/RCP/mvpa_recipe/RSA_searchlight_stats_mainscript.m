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
%----evaluation---------------------------------------------
config_options.cluster_conn = 26;
config_options.cluster_effect_stat = 'extent';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom' 
config_options.LSSid = 'ASGM'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 1.5;
config_options.roi_list = {'gray_matter.nii'};   
config_options.rois4fig = {'gray_matter'};  
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'encoding_valence';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = @GNB; %only matters for adding GNB func paths
config_options.performance_stat = 'none'; %accuracy | Fscore
%----------------------------------------------------------- 
options = set_options(config_options);
options.parforlog = 'off';
options.RDM_dist_metric = 'spearman'; %'spearman' | 'kendall'
options.num_perms = 100;


%load analysis results
voxel_null = load(fullfile(options.save_dir,[options.name '_voxel_null']));
voxel_null = voxel_null.voxel_null;
searchlight_results = load(fullfile(options.home_dir,'Results',resname,[resname '_braincells.mat']));
searchlight_results = searchlight_results.searchlight_cells;

%handle the save directory
options.save_dir = fullfile(options.save_dir,sprintf('conn_scheme_%i',options.cluster_conn));
if strcmp(options.cluster_effect_stat,'t-stat')
    options.save_dir = fullfile(options.save_dir,'cluster_t-stat');end
if ~isdir(options.save_dir),mkdir(options.save_dir);end

%here's the statistics 
searchlight_stats = map_searchlight_significance(searchlight_results,voxel_null,options);
 
%---cleanup-------------------
driverfile = mfilename;
backup_jobcode(driverfile,options)






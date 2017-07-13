clear
clc
format compact

aname = 'RSA_SL_1p5_ASGM_encodingValence';
aname = [aname '_stats'];
num_workers = 32; %parpool workers

%----name---------------------------------------------------
config_options.name = aname;
config_options.result_dir = aname;
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
options.parforlog = 'on';
options.RDM_dist_metric = 'spearman';
options.num_perms = 100;


files2attach = {which('RSA_constructRDM.m')};
files2attach = horzcat(files2attach,{which('corr.m')});
files2attach = horzcat(files2attach,{which('atanh.m')});
c = parcluster('local');
c.NumWorkers = num_workers;
parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',files2attach)



[voxel_null,roi_seed_inds]  = RSA_SL_perm_bigmem(options);
delete(gcp('nocreate'))

save(fullfile(options.save_dir,[options.name '_voxel_null']),'voxel_null','roi_seed_inds','options')







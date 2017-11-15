clear
clc
format compact

aname = 'RSA_SL_2p5_VMGM_enc2ret'; %might need a diff enc2ret naming scheme... 
enc_job = 'RSA_SL_2p5_VMGM_encodingValence'; %encoding results to pull 
aname = [aname '_stats'];
num_workers = 30; %parpool workers

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
config_options.LSSid = 'VMGM'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 2.5;
config_options.roi_list = {'gray_matter.nii'};   
config_options.rois4fig = {'gray_matter'};  
%----TR-settings--------------------------------------------
config_options.TR_delay = 0;
config_options.TR_avg_window = 0;
config_options.remove_endrun_trials = 0;
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'retrieval_valence';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = @GNB; %only matters for adding GNB func paths
config_options.performance_stat = 'none'; %accuracy | Fscore
%----------------------------------------------------------- 
options = set_options(config_options);
options.parforlog = 'on';
options.RDM_dist_metric = 'spearman'; %'spearman' | 'kendall'
options.num_perms = 100;
options.enc_job = enc_job; %put the enc job in options 


files2attach = {which('RSA_constructRDM.m')};
files2attach = horzcat(files2attach,{which('corr.m')});
files2attach = horzcat(files2attach,{which('atanh.m')});
c = parcluster('local');
c.NumWorkers = num_workers;
parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',files2attach)

RSA_SL_enc2ret_perm(options);
delete(gcp('nocreate'))

%all the saving goes on inside RSA_SL_enc2ret_perm() here, just save options
save(fullfile(options.save_dir,'job_options'),'options')

%---cleanup-------------------
driverfile = mfilename;
backup_jobcode(driverfile,options)

clear
clc
format compact

%do both the analysis and permutations 

aname = 'MVPA_R2SL_2p5_enc2ret_k80'; %might need a diff enc2ret naming scheme... 
enc_job = 'RSA_SL_1p5_ASGM_encodingValence'; %encoding results to pull 
num_workers = 24; %parpool workers
k = 80; %PCs...

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
%----evaluation---------------------------------------------
config_options.cluster_conn = 26;
config_options.cluster_effect_stat = 'extent';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom' 
config_options.LSSid = 'ASGM'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 2.5;
config_options.roi_list = {'gray_matter.nii'};   
config_options.rois4fig = {'gray_matter'};  
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'enc2ret_valence';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = 'linear'; 
config_options.performance_stat = 'accuracy';
%----------------------------------------------------------- 
options = set_options(config_options);
options.PCAcomponents2keep = k;
options.enc_job = enc_job; %put the enc job in options 


%classifer_file = {fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m'])};
files2attach = {which('predict.m')};
c = parcluster('local');
c.NumWorkers = num_workers;
parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',files2attach)


searchlight_cells = MVPA_ROI2searchlight(options);

save(fullfile(options.save_dir,[options.name '_braincells']),'searchlight_cells','options')


%---now permutations----------------------------------------
config_options.name = [config_options.name '_stats'];
config_options.result_dir = [config_options.result_dir '_stats'];
options = set_options(config_options);
options.PCAcomponents2keep = k;
options.enc_job = enc_job; %put the enc job in options 


MVPA_ROI2searchlight_perm(options);
delete(gcp('nocreate'))

%all the saving goes on inside RSA_SL_enc2ret_perm() here, just save options
save(fullfile(options.save_dir,'job_options'),'options')
 

%---cleanup-------------------
driverfile = mfilename;
backup_jobcode(driverfile,options)




clear
clc
format compact

aname = 'MVPA_ROI2searchlight_2p5_ASGM_enc2ret'; %might need a diff enc2ret naming scheme... 
enc_job = 'RSA_SL_1p5_ASGM_encodingValence'; %encoding results to pull 
aname = [aname '_stats'];
num_workers = 24; %parpool workers

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
options.parforlog = 'on';
options.PCAcomponents2keep = 60;
options.num_perms = 100;
options.enc_job = enc_job; %put the enc job in options 

%split this work up
%options.exclusions = [options.exclusions,options.subjects(options.subjects < 420)];


%classifer_file = {fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m'])};
files2attach = {which('predict.m')};
switch options.performance_stat
    case 'oldMC'
        files2attach = horzcat(files2attach,{which('test_oldMC_LDA')});
    case 'Fscore'
        files2attach = horzcat(files2attach,{which('modelFscore')});
end
c = parcluster('local');
c.NumWorkers = num_workers;
parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',files2attach)


MVPA_ROI2searchlight_perm(options);
delete(gcp('nocreate'))

%all the saving goes on inside RSA_SL_enc2ret_perm() here, just save options
save(fullfile(options.save_dir,'job_options'),'options')
 

%---cleanup-------------------
driverfile = mfilename;
backup_jobcode(driverfile,options)

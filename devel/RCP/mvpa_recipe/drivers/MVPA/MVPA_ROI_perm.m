clear
clc
format compact

aname = 'MVPA_ROI_enc2ret_2p5ASGM';
aname = [aname '_stats'];
num_workers = 24;

%----name---------------------------------------------------
config_options.name = aname;
config_options.result_dir = aname;
%----experiment---------------------------------------------
config_options.dataset = 'RCP';
%----analysis-----------------------------------------------
config_options.analysis = 'ROI';
config_options.CVscheme = 'none';
config_options.normalization = 'runwise';
config_options.trial_temporal_compression = 'off';
config_options.feature_selection = 'martinez PCA';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom'
config_options.LSSid = 'ASGM'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 2.5;
config_options.roi_list = {'encoding_valence.nii', 'retrieval_valence.nii'};   
config_options.rois4fig = {'encoding_valence', 'retrieval_valence'};
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'enc2ret_valence';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = @LDA; %only matters for adding GNB func paths
config_options.performance_stat = 'accuracy'; %accuracy | Fscore
%-----------------------------------------------------------
options = set_options(config_options);
options.parforlog = 'off';
options.PCAcomponents2keep = 60;
options.num_perms = 15e3;

subject_file_pointers = PreprocDataFP_handler(options,[],'load');



classifer_file = {fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m'])};
c = parcluster('local');
c.NumWorkers = num_workers;
parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',classifer_file)


MVPA_ROI_enc2ret_perm(subject_file_pointers,options);

delete(gcp('nocreate'))
%all the saving goes on inside RSA_SL_enc2ret_perm() here, just save options
save(fullfile(options.save_dir,'job_options'),'options')

%---cleanup-------------------
driverfile = mfilename;
backup_jobcode(driverfile,options)



null_res = dir(fullfile(options.save_dir,'files','*mat'));
null_res = {null_res.name};
for idx = 1:numel(null_res)
    null_res{idx} = load(fullfile(options.save_dir,'files',null_res{idx}));
    null_res{idx} = null_res{idx}.cv_accuracy;
end
null_res = cat(1,null_res{:});



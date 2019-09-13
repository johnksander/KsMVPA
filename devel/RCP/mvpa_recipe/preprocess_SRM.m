clear
clc
format compact

aname = 'SRM_preproc';

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
config_options.feature_selection = 'none';
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

subject_file_pointers = PreprocDataFP_handler(options,[],'load');
preproc_srm_data(subject_file_pointers,options);

%save(fullfile(options.save_dir,[options.name '_predictions']),'predictions','options')

%---cleanup-------------------
driverfile = mfilename;
backup_jobcode(driverfile,options)



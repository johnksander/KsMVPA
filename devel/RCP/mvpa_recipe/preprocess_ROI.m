clear 
clc
format compact


aname = 'RCP_ROI_voxpreproc';
%this was for handling multiple enc2ret ROIs cleanly 
%job2load = 'RSA_SL_1p5_ASGM_enc2ret'; %for special enc2ret business... 
% FNs = '/home/acclab/Desktop/ksander/holly_mvpa/KsMVPA_h/maskdir';
% FNs = dir(fullfile(FNs,sprintf('%s*nii',job2load)));
% FNs = {FNs.name};
% easier_names = cellfun(@(x) strsplit(x,job2load),FNs,'uniformoutput',false);
% easier_names = cellfun(@(x) x{end},easier_names,'uniformoutput',false);
% easier_names = cellfun(@(x) strrep(x,'.nii',''),easier_names,'uniformoutput',false);

%----name---------------------------------------------------
config_options.name = aname;
config_options.result_dir = aname;
%----experiment---------------------------------------------
config_options.dataset = 'RCP';
%----analysis-----------------------------------------------
config_options.analysis = 'searchlight'; %just so correct data is loaded... 
config_options.CVscheme = 'none';
config_options.normalization = 'runwise';
config_options.trial_temporal_compression = 'off'; 
config_options.feature_selection = 'off';
%----evaluation---------------------------------------------
config_options.cluster_conn = 6;
config_options.cluster_effect_stat = 'extent';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom' 
config_options.LSSid = 'ASGM'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 2.5;
config_options.roi_list = {'encoding_valence.nii', 'retrieval_valence.nii'};   
config_options.rois4fig = {'encoding_valence', 'retrieval_valence'};  
%config_options.roi_list = FNs;   
%config_options.rois4fig = easier_names;  
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'enc2ret_valence';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = 'linear'; 
config_options.performance_stat = 'accuracy'; 
%----------------------------------------------------------- 
options = set_options(config_options);
options.parforlog = 'off';


preproc_data_file_pointers = preprocess_ROI_from_SL(options);


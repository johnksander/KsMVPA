clear 
clc
format compact


aname = 'RCP_ROI_voxpreproc';
job2load = 'RSA_SL_1p5_ASGM_enc2ret'; %for special enc2ret business... 
FNs = '/home/acclab/Desktop/ksander/holly_mvpa/KsMVPA_h/maskdir';
FNs = dir(fullfile(FNs,sprintf('%s*nii',job2load)));
FNs = {FNs.name};
easier_names = cellfun(@(x) strsplit(x,job2load),FNs,'uniformoutput',false);
easier_names = cellfun(@(x) x{end},easier_names,'uniformoutput',false);
easier_names = cellfun(@(x) strrep(x,'.nii',''),easier_names,'uniformoutput',false);

%----name---------------------------------------------------
config_options.name = aname;
config_options.result_dir = aname;
%----experiment---------------------------------------------
config_options.dataset = 'RCP';
%----analysis-----------------------------------------------
config_options.analysis = 'searchlight'; %just so correct data is loaded... 
config_options.CVscheme = 'oddeven';
config_options.normalization = 'runwise';
config_options.trial_temporal_compression = 'off'; 
config_options.feature_selection = 'off';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom' 
config_options.LSSid = 'ASGM'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 1.5;
%config_options.roi_list = {'MTL_left.nii',  'MTL_right.nii'};   
%config_options.rois4fig = {'MTL_left',  'MTL_right'};  
config_options.roi_list = FNs;   
config_options.rois4fig = easier_names;  
%----TR-settings--------------------------------------------
config_options.TR_delay = 0;
config_options.TR_avg_window = 0;
config_options.remove_endrun_trials = 0;
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'encoding_valence';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = @GNB; %only matters for adding GNB func paths
config_options.performance_stat = 'Fscore'; %accuracy | Fscore
%----------------------------------------------------------- 
options = set_options(config_options);
options.parforlog = 'off';



options = set_options(config_options);



preproc_data_file_pointers = preprocess_ROI_from_SL(options);


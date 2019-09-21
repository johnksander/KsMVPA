clear
clc
format compact

aname = 'MVPA_ROI_enc2ret_2p5ASGM';

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


subject_file_pointers = PreprocDataFP_handler(options,[],'load');

predictions = MVPA_ROI_enc2ret(subject_file_pointers,options);

save(fullfile(options.save_dir,[options.name '_predictions']),'predictions','options')

%---cleanup-------------------
driverfile = mfilename;
backup_jobcode(driverfile,options)


%only 1 ROI here... 
curr_pred = cell2mat(predictions);
accuracy = sum(curr_pred(:,1) == curr_pred(:,2)) / numel(curr_pred(:,1));
sprintf('enc-to-ret ROI accuracy = %.2f',accuracy*100)
figure();imagesc(curr_pred)

a = cellfun(@(x) sum(x(:,1) == x(:,2)) / numel(x(:,1)),predictions(~cellfun(@isempty,predictions)))

ref = load('view_niis/reference.mat');
ref.vox_results(:,1)




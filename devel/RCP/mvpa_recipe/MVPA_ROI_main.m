clear
clc
format compact

aname = 'MVPA_ROI_enc2ret_1p5ASGM';

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
config_options.analysis = 'ROI';
config_options.CVscheme = 'none';
config_options.normalization = 'runwise';
config_options.trial_temporal_compression = 'off';
config_options.feature_selection = 'off';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom'
config_options.LSSid = 'ASGM'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 1.5;
config_options.roi_list = FNs;
config_options.rois4fig = easier_names;
%----TR-settings--------------------------------------------
config_options.TR_delay = 0;
config_options.TR_avg_window = 0;
config_options.remove_endrun_trials = 0;
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'enc2ret_valence';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = @GNB; %only matters for adding GNB func paths
config_options.performance_stat = 'accuracy'; %accuracy | Fscore
%-----------------------------------------------------------
options = set_options(config_options);
options.parforlog = 'off';

subject_file_pointers = PreprocDataFP_handler(options,[],'load');

predictions = MVPA_ROI(subject_file_pointers,options);

save(fullfile(options.save_dir,[options.name '_predictions']),'predictions','options')

%---cleanup-------------------
driverfile = mfilename;
backup_jobcode(driverfile,options)


for idx = 1:numel(options.roi_list)
    
    curr_pred = predictions(:,idx);
    curr_pred = cell2mat(curr_pred);
    accuracy = sum(curr_pred(:,1) == curr_pred(:,2)) / numel(curr_pred(:,1));
    sprintf('ROI %i accuracy = %.2f',idx,accuracy*100)
    %figure(idx);imagesc(curr_pred)
end




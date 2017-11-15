clear
clc
format compact

aname = 'LOSO_ROI_searchlight_followup_gender2_gnb';
num_workers = 8; %parpool workers

%----name---------------------------------------------------
config_options.name = aname;
config_options.result_dir = aname;
%----experiment---------------------------------------------
config_options.dataset = 'ESWS';
%----analysis-----------------------------------------------
config_options.analysis = 'LOSO';
config_options.CVscheme = 'genderCVs'; %OneOut, TwoOut
config_options.trial_temporal_compression = 'runwise'; 
config_options.feature_selection = 'off';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom' 
config_options.LSSid = 'ASGM10'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 0;
config_options.roi_list = {'significant_searchlights.nii'};   
config_options.rois4fig = {'significant_searchlights'};  
%----TR-settings--------------------------------------------
config_options.TR_delay = 0;
config_options.TR_avg_window = 0;
config_options.remove_endrun_trials = 2;
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'origin_split';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = @GNB;  
%----------------------------------------------------------- 
options = set_options(config_options);
%get CV folds for gender followup analysis
options.exclusions = options.subjects(options.demos_gender == 1); %exclude males for setting up CV folds 
combos = gender_followup_analysis_combos(options,'train_Fonly');
options.exclusions = []; %reset exclusions now that CV folds have been preallocated. 
save(fullfile(options.save_dir,'genderCVs'),'combos')


%load correct ROI filepointers
preproc_data_file_pointers = PreprocDataFP_handler(options,[],'load'); 

classifer_file = fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m']);
c = parcluster('local');
c.NumWorkers = num_workers;
parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',{classifer_file})

predictions = LOSO_roi_parfor_mvpa(preproc_data_file_pointers,options);
delete(gcp('nocreate'))

save(fullfile(options.save_dir,[options.name '_predictions']),'predictions','options')

%---cleanup-------------------
driverfile = mfilename;
backup_jobcode(driverfile,options)


%---maybe look at some stats
for idx = 1:numel(options.roi_list)
    roi_pred = predictions(:,idx);
    roi_pred = vertcat(roi_pred{:});
    roi_pred = (sum(roi_pred(:,1) == roi_pred(:,2))) / numel(roi_pred(:,1));
    disp(sprintf('%s classification accuracy %.2f%% \n',options.rois4fig{idx},(roi_pred*100)))
end

for idx = 1:numel(options.roi_list)
    roi_pred = predictions(:,idx);
    roi_pred = vertcat(roi_pred{:});
    figure(idx)
    imagesc(roi_pred)
end
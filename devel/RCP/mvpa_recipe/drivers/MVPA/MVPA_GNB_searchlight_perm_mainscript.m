clear
clc
format compact

aname = 'GNB_SL_1p5_RGM_stats_local';
num_workers = 4; %parpool workers

%----name---------------------------------------------------
config_options.name = aname;
config_options.result_dir = aname;
%----experiment---------------------------------------------
config_options.dataset = 'RCP';
%----analysis-----------------------------------------------
config_options.analysis = 'searchlight';
config_options.CVscheme = 'oddeven';
config_options.trial_temporal_compression = 'off'; 
config_options.feature_selection = 'off';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom' 
config_options.LSSid = 'RGM'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 1.5;
config_options.roi_list = {'gray_matter.nii'};   
config_options.rois4fig = {'gray_matter'};  
%----TR-settings--------------------------------------------
config_options.TR_delay = 0;
config_options.TR_avg_window = 0;
config_options.remove_endrun_trials = 0;
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'R';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = @GNB; %only matters for adding GNB func paths  
%----------------------------------------------------------- 
options = set_options(config_options);
options.parforlog = 'on';
options.num_perms = 10;
options.exclusions = [401,409:445]; %just do three subjects for test, 406,407,408


classifer_file = fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m']);
c = parcluster('local');
c.NumWorkers = num_workers;
parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',{classifer_file})%{classifer_file,which('modelFscore')} for F score

[voxel_null,roi_seed_inds] = MVPA_GNB_SL_perm(options);
delete(gcp('nocreate'))

save(fullfile(options.save_dir,[options.name '_voxel_null']),'voxel_null','roi_seed_inds','options')






% 
% % 
% % %in progress---
% permtestfiles_dir = '/home/acclab/Desktop/ksander/KsMVPA/Results/LOSO_GNB_SL_1p5_ASGM10_runwise_stats';
% %permtestfiles_dir = '/Users/chewie/Desktop/work/KsMVPA/Results/LOSO_GNB_SL_1p5_ASGM10_runwise_stats';
% permtestfiles = dir(fullfile(permtestfiles_dir,'*voxel_null*'));
% permtestfiles = {permtestfiles.name};
% %lets save some memory for chewie
% voxel_null = load(fullfile(permtestfiles_dir,permtestfiles{1}));
% voxel_null = size(voxel_null.voxel_null{1});
% voxel_null(2) = voxel_null(2) * numel(permtestfiles); 
% voxel_null = NaN(voxel_null); 
% %lets save some memory for chewie
% for loadidx = 1:numel(permtestfiles)
%     curr_VNinds = (((loadidx - 1) * 1000) + 1):(loadidx * 1000);
%     hld = load(fullfile(permtestfiles_dir,permtestfiles{loadidx}));
%     options = hld.options;    
%     hld = hld.voxel_null{1};
%     voxel_null(:,curr_VNinds) = hld;
%     clear hld 
% end
% options = set_bigmem_options2linus(options);
% 
% 
% results = '/home/acclab/Desktop/ksander/KsMVPA/Results/LOSO_GNB_SL_1p5_ASGM10_runwise';
% results = load(fullfile(results,'LOSO_GNB_SL_1p5_ASGM10_runwise_braincells.mat'));
% %results = '/Users/chewie/Desktop/work/KsMVPA/Results/LOSO_GNB_SL_1p5_ASGM10_runwise';
% %results = load(fullfile(results,'LOSO_GNB_SL_1p5_ASGM10_runwise_braincells.mat'));
% searchlight_reults = results.searchlight_results;
% %fisher transform r values 
% %searchlight_reults(:,2) = atanh(searchlight_reults(:,2)); 
% %voxel_null = atanh(voxel_null); 
% 
% searchlight_stats = map_searchlight_significance(searchlight_reults,voxel_null,options);





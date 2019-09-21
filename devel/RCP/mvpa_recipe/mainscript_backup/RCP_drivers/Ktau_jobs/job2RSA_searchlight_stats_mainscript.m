clear
clc
format compact

resname = 'RSA_SL_1p5_VMGM_Ktau_Tcomp_1kperm_retrievalValence';
permname = [resname '_stats'];


%----name---------------------------------------------------
config_options.name = permname;
config_options.result_dir = permname;
%----experiment---------------------------------------------
config_options.dataset = 'RCP';
%----analysis-----------------------------------------------
config_options.analysis = 'searchlight';
config_options.CVscheme = 'none';
config_options.normalization = 'runwise';
config_options.trial_temporal_compression = 'runwise'; 
config_options.feature_selection = 'off';
config_options.treat_special_stimuli = 'faces_and_scenes'; %compress these seperately
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom' 
config_options.LSSid = 'VMGM'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 1.5;
config_options.roi_list = {'gray_matter.nii'};   
config_options.rois4fig = {'gray_matter'};  
%----TR-settings--------------------------------------------
config_options.TR_delay = 0;
config_options.TR_avg_window = 0;
config_options.remove_endrun_trials = 0;
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'retrieval_valence';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = @GNB; %only matters for adding GNB func paths
config_options.performance_stat = 'none'; %accuracy | Fscore
%----------------------------------------------------------- 
options = set_options(config_options);
options.parforlog = 'off';
options.RDM_dist_metric = 'kendall'; %'spearman' | 'kendall'
options.num_perms = 1000;


%get all the job subdirs & their output files 
jobdirs = dir(fullfile(options.save_dir,'job*')); 
jobdirs = {jobdirs.name};
jobfiles = cellfun(@(x) ...
    fullfile(options.save_dir,x,[options.name '_voxel_null']),jobdirs,'Uniformoutput',false);
%load & concatenate null distributions subjectwise 
voxel_null = cellfun(@(x) load(x,'voxel_null'),jobfiles,'Uniformoutput',false);
voxel_null = cellfun(@(x) x.voxel_null,voxel_null,'Uniformoutput',false);
voxel_null = cat(2,voxel_null{:});
voxel_null = num2cell(voxel_null,2);
voxel_null = cellfun(@(x) cat(2,x{:}),voxel_null,'Uniformoutput',false);


%here's the statistics 
searchlight_results = load(fullfile(options.home_dir,'Results',resname,[resname '_braincells.mat']));
searchlight_results = searchlight_results.searchlight_cells;
searchlight_stats = map_searchlight_significance(searchlight_results,voxel_null,options);


%---cleanup-------------------
driverfile = mfilename;
backup_jobcode(driverfile,options)






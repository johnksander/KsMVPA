clear
clc
format compact

aname = 'GNB_SL_1p5_RGM_Fscore';
num_workers = 32; %parpool workers

%----name---------------------------------------------------
config_options.name = aname;
config_options.result_dir = aname;
%----experiment---------------------------------------------
config_options.dataset = 'RCP';
%----analysis-----------------------------------------------
config_options.analysis = 'searchlight';
config_options.CVscheme = 'oddeven';
config_options.normalization = 'runwise';
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
config_options.performance_stat = 'Fscore'; %accuracy | Fscore
%----------------------------------------------------------- 
options = set_options(config_options);
options.parforlog = 'off';



classifer_file = {fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m'])};
switch options.performance_stat
    case 'Fscore'
       classifer_file = horzcat(classifer_file,{which('modelFscore')});
end
c = parcluster('local');
c.NumWorkers = num_workers;
parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',classifer_file)


[brain_cells,searchlight_cells] = MVPA_GNB_SL_bigmem(options);
delete(gcp('nocreate'))


save(fullfile(options.save_dir,[options.name '_braincells']),'brain_cells','searchlight_cells','options')
results_brain2nii(options)
%you might be able to do away with the output brain stuff, just keep searchlight output 

clear
clc
format compact

aname = 'LOSO_SL_rwASGM_comp_1p5';
preallocate_SLrois = 'load'; % 'run' | 'load'
num_workers = 4; %parpool workers

%----name---------------------------------------------------
config_options.name = aname;
config_options.result_dir = aname;
%----experiment---------------------------------------------
config_options.dataset = 'ESWS';
%----analysis-----------------------------------------------
config_options.analysis = 'LOSO_SL';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom' 
config_options.LSSid = 'ASGM'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 1.5;
%----TR-settings--------------------------------------------
config_options.TR_delay = 0;
config_options.TR_avg_window = 0;
config_options.remove_endrun_trials = 2; 
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'origin_split';
config_options.behavioral_measure = 'memory';
%----classifier---------------------------------------------
config_options.classifier = @knn;
%-----------------------------------------------------------
 
options = set_options(config_options);
options.roi_list = {'gray_matter.nii'};   
options.rois4fig = {'gray_matter'};  
options.trial_temporal_compression = 'on'; 
options.feature_selection = 'off';
options.RDM_dist_metric = 'spearman';

preproc_data_file_pointers = PreprocDataFP_handler(options,[],'load'); %reconcile filepointers 


switch preallocate_SLrois
    case 'run'
        options.SL_per_file = 10000;
        parpool(num_workers)
        preprocessed_SLroi_files = preprocess_searchlight_rois(preproc_data_file_pointers,options);
        delete(gcp('nocreate'))
    case 'load'
        preprocessed_SLroi_files = SLroi_filelocs(options);
end


classifer_file = fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m']);
c = parcluster('local');
c.NumWorkers = num_workers;
parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',{classifer_file})

[brain_cells,searchlight_results] = RSA_SL_parfor_mvpa(preprocessed_SLroi_files,preproc_data_file_pointers,options);
delete(gcp('nocreate'))


save(fullfile(options.save_dir,[options.name '_braincells']),'brain_cells','searchlight_results','options')
results_brain2nii(options)




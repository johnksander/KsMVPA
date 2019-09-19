function options = set_options(config_options)
rng('shuffle') %just for fun 

%Directories
location = 'woodstock';

switch location
    case 'harvard'
        options.home_dir = '/ncf/mri/01/users/ksander/RCP/KsMVPA_h/';
        addpath('/ncf/mri/01/users/ksander/RCP/spm12');
    case 'bender'
        options.home_dir  = '/Users/ksander/Desktop/work/RCP';
    case 'hpc'
        options.home_dir = '/work/jksander/RCP/KsMVPA_h';
        addpath('/work/jksander/RCP/KsMVPA_h/spm12');
    case 'woodstock'
        options.home_dir = '/home/acclab/Desktop/ksander/holly_mvpa/KsMVPA_h';
        addpath('/home/acclab/Desktop/ksander/spm12')
    case 'linus'
        options.home_dir = '/home/acclab/Desktop/ksander/holly_mvpa/KsMVPA_h';
        select_linus_spm('spm12');
end
options.script_dir = fullfile(options.home_dir,'mvpa_recipe');
options.script_function_dir = fullfile(options.script_dir,'script_functions');
options.helper_function_dir = fullfile(options.script_dir,'helper_functions');
options.classifier_function_dir = fullfile(options.script_dir,'classifier_functions');
options.searchlight_function_dir = fullfile(options.script_dir,'searchlight_functions');
options.stat_function_dir = fullfile(options.script_dir,'stat_functions');
options.srm_function_dir = fullfile(options.script_dir,'srm_functions');
options.mask_dir = fullfile(options.home_dir,'maskdir');
options.save_dir = fullfile(options.home_dir,'Results',config_options.result_dir);
options.baseDir4mpva_data = fullfile(options.home_dir,'Data');
options.SPMbase_dir =  fullfile(options.home_dir,'SPM_datasets');
addpath(options.script_function_dir);
addpath(options.helper_function_dir);
addpath(options.classifier_function_dir);
addpath(options.searchlight_function_dir);
addpath(options.stat_function_dir);
addpath(options.srm_function_dir)

% Options template
fprintf('Creating options structure\r')
%File Info
options.name = config_options.name;
options.dataset = config_options.dataset;
options.analysis = config_options.analysis;
options.classification_fname = [config_options.name '_output'];
options.statistics_fname = [config_options.name '_statistics'];
options.permstats_fname = [config_options.name '_perm_stats'];
options.figure_fname = [config_options.name '_results_figure'];
options.rawdata_type = config_options.rawdata_type;
switch options.rawdata_type
    case 'unsmoothed_raw'
        options.scan_ft = 'wuaf*.nii';
        ID4preproc_datadir = '';
    case 'dartel_raw'
        options.scan_ft = 'wraf*.nii';
        ID4preproc_datadir = '_dartel';
    case 'LSS_eHDR'
        options.scan_ft = [config_options.LSSid '_LSS_eHDR*.mat'];
        ID4preproc_datadir = ['_' config_options.LSSid '_LSSeHDR'];
    case 'anatom'
        options.scan_ft = 'w3danat*.nii';
        ID4preproc_datadir = '_anatoms';
    case 'SPMbm'
        options.scan_ft = [config_options.SPMbm_id '_SPMbm*.nii'];
        ID4preproc_datadir =['_' config_options.SPMbm_id '_SPMbm'];
end
options.mt = 'mask_pointer';
options.behavioral_measure = config_options.behavioral_measure;
switch options.dataset
    case 'RCP'
        options.subjects = [401,406:410,413,414,417:419,421,425,429:431,433,436,439,445];
        options.exclusions = [401,417,418,445];
        %options.which_behavior = 1;
        options.behavioral_transformation = config_options.behavioral_transformation;
        %behavioral transformation should be to select R or something
        switch options.behavioral_measure
            case 'allstim'
                options.behavioral_file_list = {'RCP'};
                options.which_behavior = 4;
        end
        switch options.rawdata_type
            case 'unsmoothed_raw'
                options.scan_ft = 'wuf-*.nii';
                ID4preproc_datadir = '';
            case 'LSS_eHDR' %honestly, this could just be handled in a load_behavioral_data() switch
                options.behavioral_file_list = strcat(options.behavioral_file_list,'_LSS'); %append LSS to behavioral filename
        end
        options.enc_runs = 1:2:8;
        options.ret_runs = 2:2:8;
        options.scan_vol_size = [79,95,68]; %hardcoded
        options.TR_duration = 2; %2 second TR duration
        %anything using these is borked:
        %options.trials_per_run = [54,54]; %hardcoded
        %options.scans_per_run = [150,150]'; %hardcoded (first 5 must be thrown out)
        %scans per run can be used with these below, but I think there's an
        %exception in this dataset somewhere. Avoid if possible. 
% for idx = 1:8
% sum(x == idx)
% end
% ans =
%    280
% ans =
%    490
% ans =
%    280
% ans =
%    490
% ans =
%    280
% ans =
%    490
% ans =
%    280
% ans =
%    490
        
        %-------
        options.SPMdata_dir = fullfile(options.SPMbase_dir,'RCP_SPMdata','raw_scans');
        options.SPMsubj_dir = ''; %raw scans transferred into seperate folder
        options.runfolders = {'001','002','003','004','005','006','007','008'};
        options.mvpa_datadir = fullfile(options.baseDir4mpva_data,'RCP');
        options.motion_param_FNs = fullfile(options.mvpa_datadir,'motion_params','RCP_motion_params_');
        options.TRfile_dir = fullfile(options.mvpa_datadir,'TRfiles');
        switch options.analysis
            case 'ROI'
                preproc_data_dir = fullfile(options.mvpa_datadir,'preprocessed_scan_data',['ROI' ID4preproc_datadir]);
                config_options.cluster_conn = NaN;
            case 'searchlight'
                preproc_data_dir = fullfile(options.mvpa_datadir,'preprocessed_scan_data',['searchlight' ID4preproc_datadir]);
                addpath(fullfile(options.script_dir,'Nifti_Toolbox'))
            case 'LOSO'
                preproc_data_dir = fullfile(options.mvpa_datadir,'preprocessed_scan_data',['LOSO' ID4preproc_datadir]);
            case 'LOSO_SL'
                preproc_data_dir = fullfile(options.mvpa_datadir,'preprocessed_scan_data',['LOSO_SL' ID4preproc_datadir]);
                addpath(fullfile(options.script_dir,'Nifti_Toolbox'))
        end
        switch options.rawdata_type
            case 'anatom'
                options.SPManatom_dir = fullfile(options.SPMbase_dir,'RCP_SPMdata','anatoms');
        end
        
end

options.preproc_data_dir = preproc_data_dir;
%Settings----
%roi
options.roi_list = config_options.roi_list;  %options.roi_list = {'whole_brain_mask.nii'}; %default mask
options.rois4fig = config_options.rois4fig;  %options.rois4fig = {'whole_brain' };
options.searchlight_radius = config_options.searchlight_radius; %1.5 should be 19 voxels, 4 should be like 257
%fmri data treatment
options.trial_temporal_compression = config_options.trial_temporal_compression;
options.normalization = config_options.normalization;
%setting these to zero 
%options.TR_delay = config_options.TR_delay;
%options.TR_avg_window = config_options.TR_avg_window; %running average, time window N events wide
%options.remove_endrun_trials = config_options.remove_endrun_trials; %remove trials with onsets occuring at N TRs from the end of a run
options.TR_delay = 0; 
options.TR_avg_window = 0; %running average, time window N events wide
options.remove_endrun_trials = 0; %remove trials with onsets occuring at N TRs from the end of a run
if isfield(config_options,'treat_special_stimuli')
    %this was added for handling the face/scene stimuli differently for
    %temporal compression. Might be a catchall hacky add on option... 
    options.treat_special_stimuli = config_options.treat_special_stimuli;
else
    options.treat_special_stimuli = 'off';
end
options.parforlog = 'on';
%feature selection
options.feature_selection = config_options.feature_selection;
options.lambda = 0.1; %whitening regularizatv
options.PCAcomponents2keep = .8; %PCA components to keep (.99 = keep 99% of variance)
options.k_iterations = 500;
options.num_centroids = .80;
options.parkmeans = 'off';%off open parpool for 'UseParallel' kmeans argument
%classifier/CV
options.classifier_type = config_options.classifier; %@knn, @svm, @logistic, @minpool,@RelVec
options.CVscheme = config_options.CVscheme;
options.knn_neighbors = 1; %default number of neighbors is 1 (watch for spelling neighbors)
options.cv_summary_statistic = @mean; %function to summarize classification accuracies across crossval folds
if isfield(config_options,'performance_stat')
    options.performance_stat = config_options.performance_stat;
else
    options.performance_stat = 'accuracy'; %default
end
%statistical inference
options.cluster_conn = config_options.cluster_conn; %cluster connectivity scheme (6, 18, or 26)
if isfield(config_options,'cluster_effect_stat')
    options.cluster_effect_stat = config_options.cluster_effect_stat;
else
    options.cluster_effect_stat = 'extent'; %default (t-stat is alt)
end
if isfield(config_options,'vox_alpha')
    options.vox_alpha = config_options.vox_alpha;
else
    options.vox_alpha = .001; %default 
end


if isequal(options.classifier_type,@RelVec)
    addpath(fullfile(options.classifier_function_dir,'RelVec'))
    options.RV_settings = SB2_ParameterSettings;
    options.RV_options = SB2_UserOptions; %initialize RelVec parameters, these are changed within RelVec code
end
if isequal(options.classifier_type,@svm)
    addpath(fullfile(options.classifier_function_dir,'libsvm'))
end
if isequal(options.classifier_type,@GNB)
    addpath(fullfile(options.classifier_function_dir,'GNB'))
end




if ~isdir(options.preproc_data_dir)
    mkdir(options.preproc_data_dir)
end
if ~isdir(options.save_dir)
    mkdir(options.save_dir)
end

%keep below code in case you come back to these things
% switch config_options.analysis_method
%     case 'regression'
%         options.regression_lambda = config_options.lambda;
%         addpath(fullfile(options.script_dir,'regression_modeling'));
%         addpath(fullfile(options.script_dir,'regression_modeling','minFunc'));
%         addpath(fullfile(options.script_dir,'regression_modeling','minFunc','logistic'));
%         options.summed_behavior4regmod = config_options.summed_behavior4regmod;
% end
% switch config_options.analysis
%     case 'roi'
%         options.crossval_method = 'runwise';
%         %         options.crossval_method = config_options.crossval_method; %'random_bag'; %runwise
%         %         switch options.crossval_method
%         %             case 'random_bag'
%         %                 options.randbag_itr = 100;
%         %         end
% end



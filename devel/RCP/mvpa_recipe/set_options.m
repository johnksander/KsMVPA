function options = set_options(varargin)

rng('shuffle') %just for fun 

fprintf('Creating options structure\r')

%defaults
options.location = 'woodstock';
options.name = 'default_name';
options.analysis = 'searchlight'; % 'searchlight' | 'ROI' | 'LOSO' | 'LOSO_SL'
%----File Info-------------------------
options.dataset = 'RCP';
options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom'
options.LSSid = 'ASGM'; %ID for LSS_eHDR preprocessed data 
options.SPMbm_id = ''; %ID for SPMbm preprocessed data 
options.parforlog = 'on';
%----behavioral data-------------------
options.behavioral_measure = 'allstim';
options.behavioral_transformation = 'enc2ret_valence'; 
    %'Rmemory_retrieval'|'encoding_valence'|'retrieval_valence'|'enc2ret_valence'
%----ROIs and searchlights-------------
options.roi_list = {'gray_matter.nii'};%default mask 
options.rois4fig = {'gray_matter'}; 
options.searchlight_radius = 1.5; %1.5 should be 19 voxels, 2.5 is 81 vox, 4 should be like 257
%----fmri data treatment---------------
options.trial_temporal_compression = 'off'; %'on' | 'runwise' | 'off'
options.normalization = 'runwise'; %'runwise' | 'off'
options.TR_delay = 0; 
options.TR_avg_window = 0; %running average, time window N events wide
options.remove_endrun_trials = 0; %remove trials with onsets occuring at N TRs from the end of a run
options.treat_special_stimuli = 'off'; %'off'|'faces_and_scenes
    %this was added for handling the face/scene stimuli differently for
    %temporal compression. Might be a catchall hacky add on option... 
%----feature selection-----------------
options.feature_selection = 'off'; %'pca_only' | 'martinez PCA' | 'off'
options.lambda = 0.1; %whitening regularizatv
options.PCAcomponents2keep = .8; %PCA components to keep (.99 = keep 99% of variance, integers keep k PCs)
options.k_iterations = 500;
options.num_centroids = .80;
options.parkmeans = 'off'; %off open parpool for 'UseParallel' kmeans argument
%----classification--------------------
options.classifier_type = @GNB; 
    %@knn, @svm, @logistic, @minpool,@RelVec, @LDA, there's a ton. Look in classifier funcs. 
    %Use 'linear' or 'quadratic' when doing ROI2searchlight. 
options.CVscheme = 'none'; %'none' | 'oddeven' | 'TwoOut' | 'OneOut'| 
options.knn_neighbors = 1; %default number of neighbors is 1 (watch for spelling neighbors)
options.performance_stat = 'accuracy';  %'accuracy'|'oldMC'|'Fscore'
%----permutation testing---------------
options.num_perms = 100; %also used for cluster stats
%----searchlight stats-----------------
options.cluster_conn = 6; %cluster connectivity scheme (6, 18, or 26)
options.cluster_effect_stat = 't-stat'; %'extent' | 't-stat'
options.vox_alpha = .001; %default 
%----ROI2searchlight analysis----------
options.enc_job = ''; %might wana nest this, pack more info there 



%parse inputs 
if mod(numel(varargin),2) ~= 0
    error('arguments must be name-value pairs')
end

num_args = numel(varargin) / 2;
fnames = varargin(1:2:end);
fvals = varargin(2:2:end);
for idx = 1:num_args
    %check for typo first
    if ~isfield(options,fnames{idx})
        error(sprintf('unknown argument: %s',fnames{idx}))
    end
    options.(fnames{idx}) = fvals{idx};
end

%----directories-----------------------
switch options.location
    case 'harvard'
        options.home_dir = '/ncf/mri/01/users/ksander/RCP/KsMVPA_h/';
        addpath('/ncf/mri/01/users/ksander/RCP/spm12');
    case 'bender'
        options.home_dir  = '/Users/ksander/Desktop/work/KsMVPA_github/devel/RCP';
        addpath('/Users/ksander/Desktop/work/spm12')
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
%code 
options.script_dir = fullfile(options.home_dir,'mvpa_recipe');
options.script_function_dir = fullfile(options.script_dir,'functions','scripts');
options.helper_function_dir = fullfile(options.script_dir,'functions','helpers');
options.classifier_function_dir = fullfile(options.script_dir,'functions','classifiers');
options.searchlight_function_dir = fullfile(options.script_dir,'functions','searchlight');
options.srm_function_dir = fullfile(options.script_dir,'functions','SRM');
%data
options.mask_dir = fullfile(options.home_dir,'maskdir');
options.save_dir = fullfile(options.home_dir,'Results',options.name); 
options.baseDir4mpva_data = fullfile(options.home_dir,'Data');
options.SPMbase_dir =  fullfile(options.home_dir,'SPM_datasets');
addpath(options.script_function_dir);
addpath(options.helper_function_dir);
addpath(options.classifier_function_dir);
addpath(options.searchlight_function_dir);
addpath(options.srm_function_dir)
%results



%----File Info-------------------------
options.classification_fname = [options.name '_output'];
options.statistics_fname = [options.name '_statistics'];
options.permstats_fname = [options.name '_perm_stats'];
options.figure_fname = [options.name '_results_figure'];
switch options.rawdata_type
    case 'unsmoothed_raw'
        options.scan_ft = 'wuaf*.nii';
        ID4preproc_datadir = '';
    case 'dartel_raw'
        options.scan_ft = 'wraf*.nii';
        ID4preproc_datadir = '_dartel';
    case 'LSS_eHDR'
        options.scan_ft = [options.LSSid '_LSS_eHDR*.mat'];
        ID4preproc_datadir = ['_' options.LSSid '_LSSeHDR'];
    case 'anatom'
        options.scan_ft = 'w3danat*.nii';
        ID4preproc_datadir = '_anatoms';
    case 'SPMbm'
        options.scan_ft = [options.SPMbm_id '_SPMbm*.nii'];
        ID4preproc_datadir = ['_' options.SPMbm_id '_SPMbm'];
end

switch options.dataset
    case 'RCP'
        options.subjects = [401,406:410,413,414,417:419,421,425,429:431,433,436,439,445];
        options.exclusions = [401,417,418,445];
        %options.which_behavior = 1;

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

%classifier shit...
if isequal(options.classifier_type,@RelVec)
    addpath(fullfile(options.classifier_function_dir,'RelVec'))
    options.RV_settings = SB2_ParameterSettings;
    options.RV_options = SB2_UserOptions; %initialize RelVec parameters, these are changed within RelVec code
end
if isequal(options.classifier_type,@svm),addpath(fullfile(options.classifier_function_dir,'libsvm'));end
if isequal(options.classifier_type,@GNB),addpath(fullfile(options.classifier_function_dir,'GNB'));end

if ~isdir(options.preproc_data_dir),mkdir(options.preproc_data_dir);end
if ~isdir(options.save_dir),mkdir(options.save_dir);end


%do nested params later if you want 
% nest_fields = {'ratelim'}; %nest_fields = {'LDA','ballistic','TD_l','SVL','Xmemory'};
% %now parse the fields you want nested
% for idx = 1:numel(nest_fields)
%    Fall = fieldnames(options); 
%    Fparent = nest_fields{idx};
%    F = Fall(startsWith(Fall,Fparent));
%    Fnest = cellfun(@(x) strsplit(x,[Fparent '_']),F,'UniformOutput',false);
%    Fnest = cellfun(@(x) x{2},Fnest,'UniformOutput',false);
%    for j = 1:numel(Fnest)
%       options.(Fparent).(Fnest{j}) = options.(F{j});       
%    end
%    %now remove the holder fields you just nested 
%    options = rmfield(options,F);
% end


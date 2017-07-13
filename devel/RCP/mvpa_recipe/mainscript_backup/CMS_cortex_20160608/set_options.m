function options = set_options(config_options)


%Directories
%options.preproc_data_dir = preproc_data_dir;
%options.preproc_data_dir is dependant on dataset & analysis options, set below
%options.home_dir = '/scratch/ksander/ESWS_MVPA';
options.home_dir = '/home/acclab/Desktop/ksander/ESWS_MVPA/';
options.script_dir = fullfile(options.home_dir,'mvpa_recipe');
options.script_function_dir = fullfile(options.script_dir,'script_functions');
options.helper_function_dir = fullfile(options.script_dir,'helper_functions');
options.classifier_function_dir = fullfile(options.script_dir,'classifier_functions');
options.searchlight_function_dir = fullfile(options.script_dir,'searchlight_functions');
options.stat_function_dir = fullfile(options.script_dir,'stat_functions');
options.mask_dir = fullfile(options.home_dir,'maskdir');
options.save_dir = fullfile(options.home_dir,'Results',config_options.result_dir);
options.baseDir4mpva_data = fullfile(options.home_dir,'Data');
options.SPMbase_dir =  fullfile(options.home_dir,'SPM_datasets');
addpath(options.script_function_dir);
addpath(options.helper_function_dir);
addpath(options.classifier_function_dir);
addpath(options.searchlight_function_dir);
addpath(options.stat_function_dir);
%addpath('/scratch/ksander/ESWS_MVPA/projSPMversion/spm12');
select_linus_spm('spm12');

switch config_options.analysis_method
    case 'regression'
        options.regression_lambda = config_options.lambda;
        addpath(fullfile(options.script_dir,'regression_modeling'));
        addpath(fullfile(options.script_dir,'regression_modeling','minFunc'));
        addpath(fullfile(options.script_dir,'regression_modeling','minFunc','logistic'));
        options.summed_behavior4regmod = config_options.summed_behavior4regmod;
end




% Options template for MCQD
fprintf('Creating options structure\r')
%File Info
options.name = config_options.name;
options.dataset = config_options.dataset;
options.analysis = config_options.analysis;
options.classification_fname = [config_options.name '_output']; %must change output variable line 21 to this
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
        ID4preproc_datadir = '';
    case 'estimatedHDR_spm'
        options.rawdata_type_subdir = 'Extraction';
        options.scan_ft = 'beta*.nii';
        ID4preproc_datadir = '_eHDRspm';
    case 'LSS_eHDR'
        options.rawdata_type_subdir = 'LSS_estimated';
        options.scan_ft = 'LSS_eHDR*.mat';
        ID4preproc_datadir = '_LSSeHDR';
    case 'anatom'
        options.scan_ft = 'w3danat*.nii';
        ID4preproc_datadir = '_anatoms';
end
options.mt = 'mask_pointer';
options.behavioral_measure = config_options.behavioral_measure;
switch options.dataset
    case 'ESWS'
        options.subjects = [101:120 201:220];
        options.exclusions = [];
        switch options.behavioral_measure
            case 'allstim'
                options.behavioral_file_list = {'ESWS_allstim'};
                options.which_behavior = 1;
                options.behavioral_transformation = config_options.behavioral_transformation;
            case 'memory'
                options.behavioral_file_list = {'ESWS_TsameRsame'};
                options.which_behavior = 1;
                options.behavioral_transformation = config_options.behavioral_transformation;
                switch options.rawdata_type
                    case 'LSS_eHDR'
                        options.behavioral_file_list = {'ESWS_TsameRsame_LSS'};
                    otherwise
                        options.behavioral_file_list = {'ESWS_TsameRsame'};
                end
                options.which_behavior = 1;
                options.behavioral_transformation = config_options.behavioral_transformation;
        end
        options.scans_per_run = [150,150]'; %hardcoded (first 5 must be thrown out)
        options.SPMdata_dir = fullfile(options.SPMbase_dir,'ESWS_SPMdata','raw_scans');
        options.SPMsubj_dir = ''; %raw scans transferred into seperate folder
        options.runfolders = {'001' '002'};
        options.mvpa_datadir = fullfile(options.baseDir4mpva_data,'ESWS');
        options.TRfile_dir = fullfile(options.mvpa_datadir,'TRfiles');
        switch options.analysis
            case 'roi'
                preproc_data_dir = fullfile(options.mvpa_datadir,'preprocessed_scan_data',['roi' ID4preproc_datadir]);
            case 'LOSO'
                preproc_data_dir = fullfile(options.mvpa_datadir,'preprocessed_scan_data',['LOSO' ID4preproc_datadir]);
            case 'LOSO_SL'
                preproc_data_dir = fullfile(options.mvpa_datadir,'preprocessed_scan_data',['LOSO_SL' ID4preproc_datadir]);
                addpath(fullfile(options.script_dir,'Nifti_Toolbox'))
        end
        switch options.rawdata_type
            case 'anatom'
                options.SPManatom_dir = fullfile(options.SPMbase_dir,'ESWS_SPMdata','anatoms');
        end
        
end

options.preproc_data_dir = preproc_data_dir;
%Settings
options.roi_list = {'whole_brain_mask.nii'};
options.rois4fig = {'whole_brain' };

options.tr_delay = config_options.TRlag;
options.running_average_window = config_options.TR_avg_window; %running average, time window N events wide
options.lag_type = config_options.lag_type;
options.lambda = 0.1; %whitening regularizatv
options.PCAcomponents2keep = .8; %PCA components to keep (.99 = keep 99% of variance)
options.k_iterations = 500;
options.num_centroids = .80;
options.searchlight_radius = config_options.searchlight_radius; %1.5 should be 19 voxels, 4 should be like 257
options.classifier_type = config_options.classifier; %@knn, @svm, @logistic, @minpool,@RelVec
options.permutation_classifer_testing = 'off';
options.trial_temporal_compression = 'off';

if isequal(options.classifier_type,@RelVec)
    addpath(fullfile(options.classifier_function_dir,'RelVec'))
    options.RV_settings = SB2_ParameterSettings;
    options.RV_options = SB2_UserOptions; %initialize RelVec parameters, these are changed within RelVec code
end
if isequal(options.classifier_type,@svm)
    addpath(fullfile(options.classifier_function_dir,'libsvm'))
end




switch config_options.analysis
    case 'roi'
        options.crossval_method = 'runwise';
        %         options.crossval_method = config_options.crossval_method; %'random_bag'; %runwise
        %         switch options.crossval_method
        %             case 'random_bag'
        %                 options.randbag_itr = 100;
        %         end
end

options.cv_summary_statistic = @mean; %function to summarize classification accuracies across crossval folds
options.parkmeans = 'off';%off open parpool for 'UseParallel' kmeans argument

if ~isdir(options.preproc_data_dir)
    mkdir(options.preproc_data_dir)
end
if ~isdir(options.save_dir)
    mkdir(options.save_dir)
end








%
%
% % Options template for MCQD
% fprintf('Creating options structure\r')
% %File Info
% options.name = config_options.name;
% options.dataset = config_options.dataset;
% options.analysis = config_options.analysis;
% options.classification_fname = [config_options.name '_output']; %must change output variable line 21 to this
% options.statistics_fname = [config_options.name '_statistics'];
% options.permstats_fname = [config_options.name '_perm_stats'];
% options.figure_fname = [config_options.name '_results_figure'];
% options.scan_ft = 'wuaf*.img';
% options.mt = 'mask_pointer';
% options.behavioral_measure = config_options.behavioral_measure;
% switch options.dataset
%     case 'Del_MCQ'
%         options.subjects = 1:22;
%         options.exclusions = [14 15 16 18]; % 16,18 - brain data; %% CONSIDER RE-ADD %% 11,20,21 - multiclass failed; 15,17 - insufficient trials per vivid rating (reconsider later)
%         %options.exclusions = [15]; % 05/22/15 considering re-add for 14,16,18 after new SPM8 preproc.
%         switch options.behavioral_measure
%             case 'vividness'
%                 options.behavioral_file_list = {'MCQDPA','MCQDNU','MCQDNA'};
%             case 'composite_metamemory'
%                 options.behavioral_file_list = {'MCQDPAcomp','MCQDNUcomp','MCQDNAcomp'};
%             case 'complete_file'
%                 options.behavioral_file_list = {'MCQDPAall','MCQDNUall','MCQDNAall'};
%                 %which_behavior 1 = conf, 2 = vivid, 3 = feel, 4 = order, 5 = thoughts
%                 %options.which_behavior must be specified in roi_mainscript
%             case 'pca_metamemory'
%                 options.behavioral_file_list = {'MCQDPApca','MCQDNUpca','MCQDNApca'};
%             case 'pca_confviv'
%                 options.behavioral_file_list = {'MCQDPApcacv','MCQDNUpcacv','MCQDNApcacv'};
%             case 'summed_confviv'
%                 options.behavioral_file_list = {'MCQDPAaddcv','MCQDNUaddcv','MCQDNAaddcv'};
%             case 'summed_confvivfeel'
%                 options.behavioral_file_list = {'MCQDPAaddfcv','MCQDNUaddfcv','MCQDNAaddfcv'};
%             case 'short_delay_complete_file'
%                 options.behavioral_file_list = {'MCQDPAs_all','MCQDNUs_all','MCQDNAs_all'};
%                 %which_behavior 1 = conf, 2 = vivid, 3 = feel, 4 = order, 5 = thoughts
%                 %options.which_behavior must be specified in roi_mainscript
%         end
%         options.scans_per_run = [334,334,334]'; %hardcoded
%         options.SPMdata_dir = fullfile(options.SPMbase_dir,'MCQD_JohnK','Data');
%         options.SPMsubj_dir = 'MCQD'; %'MCQD epi dir'; %runwise
%         options.runfolders = {'bold/005' 'bold/006' 'bold/007'};
%         options.mvpa_datadir = fullfile(options.baseDir4mpva_data,'Del_MCQ');
%         options.TRfile_dir = fullfile(options.mvpa_datadir,'TRfiles');
%         switch options.analysis
%             case 'roi'
%                 preproc_data_dir = fullfile(options.mvpa_datadir,'preprocessed_scan_data','roi');
%             case 'LOSO'
%                 preproc_data_dir = fullfile(options.mvpa_datadir,'preprocessed_scan_data','LOSO');
%         end
%     case 'Aro_MCQ'
%         options.subjects = 1:21;
%         options.exclusions = [3 19]; % No data for 3 & 19, evaluate others for exclusion based on behav data
%         switch options.behavioral_measure
%             case 'vividness'
%                 options.behavioral_file_list = {'AMCQPA' 'AMCQPN' 'AMCQNU' 'AMCQNA' 'AMCQNN'};
%             case 'composite_metamemory'
%                 options.exclusions = [2 3 13 15 16 19]; % No data for 3 & 19, 2 13 15 & 16 low trial #s
%                 options.behavioral_file_list = {'MCQPAcomp' 'MCQPNcomp' 'MCQNUcomp' 'MCQNAcomp' 'MCQNNcomp'}; %these are MCQ not AMCQ, dumb
%             case 'pca_confviv'
%                 options.exclusions = [1 2 3 14 16 17 18 19]; % No data for 3 & 19, evaluate others for exclusion based on behav data
%                 options.behavioral_file_list = {'AMCQPApcacv' 'AMCQPNpcacv' 'AMCQNUpcacv' 'AMCQNApcacv' 'AMCQNNpcacv'};
%             case 'summed_confviv'
%                 options.exclusions = [1 2 3 14 16 17 18 19]; % No data for 3 & 19, evaluate others for exclusion based on behav data
%                 options.behavioral_file_list = {'AMCQPAaddcv' 'AMCQPNaddcv' 'AMCQNUaddcv' 'AMCQNAaddcv' 'AMCQNNaddcv'};
%         end
%         options.scans_per_run = [175,175,175]'; %hardcoded
%         options.SPMdata_dir = fullfile(options.SPMbase_dir,'AMCQ','Data');
%         options.SPMsubj_dir = 'MCQ'; %'MCQD epi dir'; %runwise
%         options.runfolders = {'bold/005' 'bold/006' 'bold/007'};
%         options.mvpa_datadir = fullfile(options.baseDir4mpva_data,'Aro_MCQ');
%         options.TRfile_dir = fullfile(options.mvpa_datadir,'TRfiles');
%         switch options.analysis
%             case 'roi'
%                 preproc_data_dir = fullfile(options.mvpa_datadir,'preprocessed_scan_data','roi');
%             case 'LOSO'
%                 preproc_data_dir = fullfile(options.mvpa_datadir,'preprocessed_scan_data','LOSO');
%         end
% end
% options.preproc_data_dir = preproc_data_dir;
% %Settings
% options.roi_list = {'left_hippocampus.nii','right_hippocampus.nii','left_amygdala.nii','right_amygdala.nii',...
%     'left_Parahippocampal.nii','right_Parahippocampal.nii'};
% options.rois4fig = {'left hipp', 'right hipp', 'left amyg', 'right amyg', 'left pHc', 'right pHc' };
% switch options.behavioral_measure
%     case 'vividness'
%         switch options.dataset
%             case 'Del_MCQ'
%                 options.which_behavior = 2; %1 = conf, 2 = vividness
%             case 'Aro_MCQ'
%                 options.which_behavior = 1; %confidence data not included in AMCQ TRfile
%         end
%     case {'composite_metamemory','pca_metamemory','pca_confviv',...
%             'summed_confviv','summed_confvivfeel'}
%         options.which_behavior = 1;
% end
% options.behavioral_transformation = 'balanced_median_split';%'';
% options.tr_delay = config_options.TRlag;
% options.lag_type = 'average'; %'single'; %'average'
% options.running_average_window = config_options.TR_avg_window; %running average, time window N events wide
% options.lambda = 0.1; %whitening regularizatv
% options.PCAcomponents2keep = .99; %PCA components to keep (.99 = keep 99% of variance)
% options.k_iterations = 500;
% options.num_centroids = .80;
% options.searchlight_radius = 1.5; %should be 19 voxels
% options.classifier_type = config_options.classifier; %@knn, @svm, @logistic @minpool
% options.crossval_method = config_options.crossval_method; %'random_bag'; %runwise
% switch options.crossval_method
%     case 'random_bag'
%         options.randbag_itr = 100;
% end
% options.cv_summary_statistic = @mean; %function to summarize classification accuracies across crossval folds
% options.parkmeans = 'off';%off open parpool for 'UseParallel' kmeans argument
%
% if ~isdir(options.preproc_data_dir)
%     mkdir(options.preproc_data_dir)
% end
% if ~isdir(options.save_dir)
%     mkdir(options.save_dir)
% end
%
%

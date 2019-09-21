clear
clc
format compact

aname = 'RSA_SL_ASGM10_1p5_stats';
num_workers = 32; %parpool workers

%----name---------------------------------------------------
config_options.name = aname;
config_options.result_dir = aname;
%----experiment---------------------------------------------
config_options.dataset = 'ESWS';
%----analysis-----------------------------------------------
config_options.analysis = 'LOSO_SL';
config_options.CVscheme = 'TwoOut'; 
config_options.trial_temporal_compression = 'on'; 
config_options.feature_selection = 'off';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom' 
config_options.LSSid = 'ASGM10'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 1.5;
config_options.roi_list = {'gray_matter_10thr.nii'};   
config_options.rois4fig = {'gray_matter'};  
%----TR-settings--------------------------------------------
config_options.TR_delay = 0;
config_options.TR_avg_window = 0;
config_options.remove_endrun_trials = 2;
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'origin_split';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = @knn;
%----------------------------------------------------------- 
options = set_options(config_options);
options.parforlog = 'on';
 
options = set_options(config_options);
options.num_perms = 1000;
options.RDM_dist_metric = 'spearman';



classifer_file = fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m']);
c = parcluster('local');
c.NumWorkers = num_workers;
parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',{classifer_file})

[voxel_null,roi_seed_inds] = RSA_SL_perm_bigmem(options);
delete(gcp('nocreate'))

currdate = datestr(now,30);
currdate = currdate(5:end); %hopefully don't need the year here...
currdate = strrep(currdate,'T','');

save(fullfile(options.save_dir,[options.name '_voxel_null_' currdate]),'voxel_null','roi_seed_inds','options')

% 
% %in progress---
% permtestfiles_dir = '/home/acclab/Desktop/ksander/KsMVPA/Results/LOSO_SL_MGM_comp_bigmem_1p5_stats';
% permtestfiles = dir(fullfile(permtestfiles_dir,'*voxel_null*'));
% permtestfiles = {permtestfiles.name};
% voxel_null = cell(1,numel(permtestfiles));
% for loadidx = 1:numel(permtestfiles)
%     hld = load(fullfile(permtestfiles_dir,permtestfiles{loadidx}));
%     voxel_null{loadidx} = hld.voxel_null{1};
%     options = hld.options;    
% end
% clear hld %just to free up some mem
% voxel_null = cell2mat(voxel_null);
% %load(fullfile(options.save_dir,[options.name '_voxel_null']));
% options = set_bigmem_options2linus(options);
% 
% results = '/home/acclab/Desktop/ksander/KsMVPA/Results/LOSO_SL_MGM_comp_bigmem_exclusions';
% results = load(fullfile(results,'LOSO_SL_MGM_comp_bigmem_exclusions_braincells'));
% %results = load(fullfile(options.save_dir,[options.name '_braincells.mat']));
% searchlight_reults = results.searchlight_results;
% %fisher transform r values 
% searchlight_reults(:,2) = atanh(searchlight_reults(:,2)); 
% voxel_null = atanh(voxel_null); 
% 
% searchlight_stats = map_searchlight_signicance(searchlight_reults,voxel_null,options);
% 
% %find p = .001 threshold map from permutation dist
% seed_thresholds = voxel_sig_threshold(voxel_null); 
% %find null distribution of cluster sizes
% cluster_null = calc_cluster_null(voxel_null,seed_thresholds,searchlight_reults(:,1),options); 
% %find result clusters   
% sig_vox = searchlight_reults(:,2) >= seed_thresholds;
% [real_clusters,seed_cluster_sizes] = cluster_search(searchlight_reults(sig_vox,1),options.scan_vol_size);
% 
% %FDR threshold
% n = numel(vol_cluster_sizes(:,1)); %num searchlights
% q = 0.05; %alpha (FDR)
% c = 1; %independance-ish
% %c = sum([1:n].^-1); %no independance
% x = (1:n)'/n*q/c; %compare this to sorted pvalues
% 
% 
% sum(cluster_null < 20) / numel(cluster_null)









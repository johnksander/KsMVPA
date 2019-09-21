clear
clc
format compact
num_workers = 4; %parpool workers

linus_home_dir = '/home/acclab/Desktop/ksander/KsMVPA/';
result_dir = fullfile(linus_home_dir,'Results','LOSO_SL_ASGM_comp_bigmem_r1p5_p');
result_file = dir(fullfile(result_dir,'*braincells.mat')); %load p map from results folder 
load(fullfile(result_dir,result_file.name))
options = set_bigmem_options2linus(options); %fix filepaths from bigmem
%add junk that doesn't come with config_options
options.roi_list = {'gray_matter.nii'};   
options.rois4fig = {'gray_matter'};  
options.trial_temporal_compression = 'on'; 
options.feature_selection = 'off';
options.RDM_dist_metric = 'spearman';
%add paths 
addpath(options.script_function_dir);
addpath(options.helper_function_dir);
addpath(options.classifier_function_dir);
addpath(options.searchlight_function_dir);
addpath(options.stat_function_dir);
%addpath('/data/netapp/jksander/spm12');
select_linus_spm('spm12');

%start doing stuff 
pmap = spm_read_vols(spm_vol(fullfile(options.save_dir,[options.name '_pmap.nii'])));
sig_searchlights = find(pmap == 1);
parpool(num_workers)
[brain_cells,permutation_results] = RSA_searchlight_perm(options,sig_searchlights);
delete(gcp('nocreate'))
save(fullfile(options.save_dir,[options.name '_permtest']),'brain_cells','permutation_results','options')

clc
clear
format compact



res_file = 'LOSO_output.mat';
res_folder = 'LOSO_results_04142015_assembled';
result_dir = '/home/ksander/MCQD_JohnK/mvpa_recipe/result_files';
savename = 'secondrun_LOSO_perm_statistics';


load(fullfile(result_dir,res_folder,res_file))
addpath(options.helper_function_dir)
addpath(fullfile(options.script_dir,'stat_functions'))

%roicols_2remove = [3:4];
%amyhipp_output(:,roicols_2remove,:) = [];

stat_output = summarize4permstats(LOSO_output,options);

rois = {'left hipp', 'right hipp', 'left amyg', 'right amyg', 'left pHc', 'right pHc' };

%get_stats_fromjkscripts(rois,stat_output,amyhipp_output,savename)

get_stats_fromjkscripts(rois,stat_output,LOSO_output,savename)

%get_stats_fromjkscripts(rois,minpool_roi_nofs_statistics,minpool_roi_nofs_output,'minpool_roi_nofs_perm_statistics')
clear
clc
format compact

aname = 'RSA_ROI_followup_grand_hipass';
num_workers = 4; %parpool workers

%----name---------------------------------------------------
config_options.name = aname;
config_options.result_dir = aname;
%----experiment---------------------------------------------
config_options.dataset = 'ESWS';
%----analysis-----------------------------------------------
config_options.analysis = 'LOSO'; %must be LOSO to draw correct data (even though it's really RSA...)
config_options.CVscheme = 'none';
config_options.normalize_space = 'off';
config_options.trial_temporal_compression = 'off';
config_options.feature_selection = 'off';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom'
config_options.LSSid = 'ASGM10'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 0;
config_options.roi_list = {'significant_searchlights.nii'};
config_options.rois4fig = {'significant_searchlights'};
%----TR-settings--------------------------------------------
config_options.TR_delay = 0;
config_options.TR_avg_window = 0;
config_options.remove_endrun_trials = 2;
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'origin_split';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = @svm;
%-----------------------------------------------------------
options = set_options(config_options);
options.cocktail_blank = 'off';
options.RDM_dist_metric = 'spearman';
options.model2test = 'grand_SFRhi';
options.num_perms = 15000;
options.num_straps = 15000;

%load correct ROI filepointers
preproc_data_file_pointers = PreprocDataFP_handler(options,[],'load'); 

% classifer_file = fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m']);
% c = parcluster('local');
% c.NumWorkers = num_workers;
% parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',{classifer_file})

group_fits = RSA_roi_latecomb(preproc_data_file_pointers,options);
%delete(gcp('nocreate'))
save(fullfile(options.save_dir,[options.name '_group_fits']),'group_fits','options')

permuted_group_fits = RSA_roi_latecomb_perm(preproc_data_file_pointers,options);
save(fullfile(options.save_dir,[options.name '_permuted_group_fits']),'permuted_group_fits','options')

model_deviations = RSA_roi_latecomb_bootstrap_mdl(preproc_data_file_pointers,options);
save(fullfile(options.save_dir,[options.name '_model_deviations']),'model_deviations','options')

%---cleanup-------------------
driverfile = mfilename;
backup_jobcode(driverfile,options)

%---do stats------------------
stat_output_log = fullfile(options.save_dir,'stats_output.txt');
txtappend(stat_output_log,'--------group model fits--------\n')

num_groups = numel(group_fits);
group_labels = {'US','EA'}; %sort of hardcoded here but w/e
pvals = NaN(num_groups,1);
for idx = 1:num_groups
    txtappend(stat_output_log,'   \n') %give it some space
    pvals(idx) = (sum(permuted_group_fits(:,idx) > group_fits(idx)) + 1) / (numel(permuted_group_fits(:,idx)) + 1);   %no zero pvals
    txtappend(stat_output_log,sprintf('%s Group:\n',group_labels{idx}))
    txtappend(stat_output_log,sprintf('    r = %.4f\n',group_fits(idx)))
    txtappend(stat_output_log,sprintf('    p = %.4f\n',pvals(idx)))
end

txtappend(stat_output_log,'   \n')
txtappend(stat_output_log,'-----difference of fit test-----\n')
txtappend(stat_output_log,'   \n')

fit_diffs = diff(model_deviations,1,2);

CI = [.975 .025]';
tind = [1:numel(fit_diffs)] ./ numel(fit_diffs);
indCI = NaN(size(CI));
for idx = 1:numel(CI)
    [~,curr_ind] = min(abs(tind - CI(idx)));
    indCI(idx) = min(curr_ind); %in case there's a tie or something
end
fit_diffs = sort(fit_diffs);
CIvals = fit_diffs(indCI);
if sum(fit_diffs > 0) < sum(fit_diffs < 0)
    p_diff = (sum(fit_diffs > 0) + 1) / (numel(fit_diffs) + 1);   %no zero pvals
else
    p_diff = (sum(fit_diffs < 0) + 1) / (numel(fit_diffs) + 1);   %no zero pvals
end
txtappend(stat_output_log,sprintf('    mu = %.4f\n',mean(fit_diffs)))
txtappend(stat_output_log,sprintf('    CI(95) = %.4f\n             %.4f\n',CIvals))
txtappend(stat_output_log,sprintf('    p = %.4f\n',p_diff))

txtappend(stat_output_log,'   \n')











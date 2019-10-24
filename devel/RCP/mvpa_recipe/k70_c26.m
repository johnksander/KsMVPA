clear
clc
format compact

%do both the analysis and permutations 
num_workers = 30; %parpool workers
do_analysis = true;
do_stats = false;

options = set_options('name','MVPA_R2SL_2p5_enc2ret_k70_perm250','location','harvard',...
    'enc_job','RSA_SL_1p5_ASGM_encodingValence',...
    'cluster_conn',26,'cluster_effect_stat','t-stat',...
    'searchlight_radius',2.5,'classifier_type','linear',...
    'PCAcomponents2keep',70,'num_perms',250);

 skip_subs = options.subjects(options.subjects < 413);
 skip_subs = [skip_subs, options.exclusions];
 skip_subs = unique(skip_subs);
 options.exclusions = skip_subs;

 subs2run = options.subjects(~ismember(options.subjects,options.exclusions));
 JID = str2num(getenv('SLURM_ARRAY_TASK_ID'));
 subs2run = subs2run(JID);
 options.exclusions = options.subjects(~ismember(options.subjects,subs2run));

if do_analysis
   
    %classifer_file = {fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m'])};
    files2attach = {which('predict.m')};
    c = parcluster('local');
    c.NumWorkers = num_workers;
    prof_loc = sprintf('/users/ksander/parprofiles/prof_%i',JID);
    if ~isdir(prof_loc),mkdir(prof_loc);end
    c.JobStorageLocation = prof_loc;
    parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',files2attach)
    
    %---main analysis----------------------------------------
    
 %      searchlight_cells = MVPA_ROI2searchlight(options);
    
    %---permutations-----------------------------------------
    
    MVPA_ROI2searchlight_perm(options);
    
    delete(gcp('nocreate'))
end


if do_stats
    
    %---stats mapping----------------------------------------
    
    map_ROI2searchlight_stats(options);
    
end
%---cleanup-------------------
driverfile = mfilename;
backup_jobcode(driverfile,options)



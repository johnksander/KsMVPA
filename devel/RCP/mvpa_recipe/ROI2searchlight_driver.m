clear
clc
format compact

%do both the analysis and permutations 
num_workers = 24; %parpool workers
do_analysis = true;
do_stats = true;

options = set_options('name','MVPA_R2SL_2p5_enc2ret_k80','location','bender',...
    'enc_job','RSA_SL_1p5_ASGM_encodingValence',...
    'cluster_conn',26,'cluster_effect_stat','extent',...
    'searchlight_radius',2.5,'classifier_type','linear',...
    'PCAcomponents2keep',80);

if do_analysis
   
    %classifer_file = {fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m'])};
    files2attach = {which('predict.m')};
    c = parcluster('local');
    c.NumWorkers = num_workers;
    parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',files2attach)
    
    %---main analysis----------------------------------------
    
    searchlight_cells = MVPA_ROI2searchlight(options);
    
    %---permutations-----------------------------------------
    
    MVPA_ROI2searchlight_perm(options);
    
    delete(gcp('nocreate'))
end


if do_stats
    
    %---stats mapping----------------------------------------
    
    map_ROI2searchlight_stats(options)
    
end
%---cleanup-------------------
driverfile = mfilename;
backup_jobcode(driverfile,options)



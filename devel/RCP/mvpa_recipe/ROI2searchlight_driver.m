clear
clc
format compact

%do both the analysis and permutations 
num_workers = 30; %parpool workers
skipping_subs = false;
do_analysis = true;
do_stats = false;

mdl = {'DiscrimType','linear','Prior','uniform','SaveMemory','on','FillCoeffs','off'...
    'OptimizeHyperparameters','auto',...
    'HyperparameterOptimizationOptions',struct('Kfold',10,'ShowPlots',false,'Verbose',0)};
    
options = set_options('name','MVPA_R2SL_2p5_enc2ret_k70_HP','location','harvard',...
    'enc_job','RSA_SL_1p5_ASGM_encodingValence','LSSid','ASGM','cluster_conn',26,...
    'searchlight_radius',2.5,'PCAcomponents2keep',70,...
    'classifier_type',mdl);

if skipping_subs
    skip_subs = options.subjects(options.subjects < 439);
    skip_subs = [skip_subs, options.exclusions];
    skip_subs = unique(skip_subs);
    options.exclusions = skip_subs;
end

if do_analysis
   
    %classifer_file = {fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m'])};
    files2attach = {which('predict.m')};
    c = parcluster('local');
    c.NumWorkers = num_workers;
    parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',files2attach)
    
    %---main analysis----------------------------------------
    if ~skipping_subs %all subs run at once
        searchlight_cells = MVPA_ROI2searchlight(options);
    end
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



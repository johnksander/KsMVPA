clear
clc
format compact


%tuna:
%autoencoder ROI2searchlight... uses enc2ret analysis scheme 


options = set_options('name','tuna_enoding_ROIs','location','bender',...
    'enc_job','RSA_SL_1p5_ASGM_encodingValence','LSSid','ASGM','cluster_conn',6,...
    'searchlight_radius',NaN);



tuna_ROI(options);





if skipping_subs
    skip_subs = options.subjects(options.subjects < 439);
    skip_subs = [skip_subs, options.exclusions];
    skip_subs = unique(skip_subs);
    options.exclusions = skip_subs;
end

if do_analysis
   
    %classifer_file = {fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m'])};
  %  files2attach = {which('predict.m')};
  %  c = parcluster('local');
  %  c.NumWorkers = num_workers;
  %  parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',files2attach)
    
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



clear
clc
format compact

%do both the analysis and permutations 
num_workers = 24; %parpool workers
do_analysis = false;
do_stats = true;

options = set_options('name','RSA_SL_1p5_VMGM_encodingValence','location','woodstock',...
    'LSSid','VMGM','behavioral_transformation','encoding_valence',...
    'cluster_conn',26,'cluster_effect_stat','t-stat',...
    'searchlight_radius',1.5);

if do_analysis
   
    files2attach = {which('RSA_constructRDM.m')};
    files2attach = horzcat(files2attach,{which('corr.m')});
    files2attach = horzcat(files2attach,{which('atanh.m')});
    c = parcluster('local');
    c.NumWorkers = num_workers;
    parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',files2attach)
    
    %---main analysis----------------------------------------
    
    searchlight_cells = RSA_SL_bigmem(options);
    
    %---permutations-----------------------------------------
    
    RSA_SL_perm(options);
    
    delete(gcp('nocreate'))
end


if do_stats
    
    %---stats mapping----------------------------------------
    %load analysis results
    voxel_null = load(fullfile(options.save_dir,[options.name '_voxel_null']));
    voxel_null = voxel_null.voxel_null;
    searchlight_results = load(fullfile(options.home_dir,'Results',options.name,[options.name '_braincells.mat']));
    searchlight_results = searchlight_results.searchlight_cells;
    
    %handle save directory
    options.save_dir = fullfile(options.save_dir,'stats',...
        sprintf('%s_conn_%i',options.cluster_effect_stat,options.cluster_conn));
    if ~isdir(options.save_dir),mkdir(options.save_dir);end

    %here's the statistics
    searchlight_stats = map_searchlight_significance(searchlight_results,voxel_null,options);
    
    
end
%---cleanup-------------------
driverfile = mfilename;
backup_jobcode(driverfile,options)



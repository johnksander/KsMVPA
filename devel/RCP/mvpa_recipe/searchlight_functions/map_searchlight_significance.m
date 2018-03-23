function searchlight_stats = map_searchlight_significance(searchlight_results,voxel_null,options)
%input:
%searchlight seed inds, classification accuracy/F1 score/r value (fisher's Z assumed)
%voxel null distribution
%options
%-----------------------------------------
%output searchlight stat results:
%cluster p values
%seed p vales
%binary 3d brain volume with significant voxels
%::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
num_straps = 1e5; %do 1e4 locally, switch to 1e5 on bigmem

voxel_null = cat(3,voxel_null{:}); %make this into a nice matrix
seed_inds = find(~ismember(options.subjects,options.exclusions),1,'first'); %grab a valid subject index
seed_inds = searchlight_results{seed_inds};
seed_inds = seed_inds(:,1); %get seed inds 
searchlight_results = cat(3,searchlight_results{:});
searchlight_results = squeeze(searchlight_results(:,2,:));
searchlight_results = mean(searchlight_results,2); %average searchlight accuracy map from results 
output_log = fullfile(options.save_dir,'stats_output_log.txt');


%preallocate matrix for drawing accuracy maps from each subject
%in 10e5 group accuracy maps. This can be used to regenerate
%distributions since these arrays are too big for local RAM (100GB).
group_map_keys = inds4groupmap(options,num_straps);
%bootstrap group average chance accuracy maps
update_logfile('Bootstrapping group chance accuracy maps...',output_log)
group_accuracy_maps = bootstrap_group_maps(voxel_null,group_map_keys);
update_logfile('---complete',output_log)
%find p = .001 threshold map from permutation dist
update_logfile('Calculating voxelwise thresholds...',output_log)
seed_thresholds = voxel_sig_threshold(group_accuracy_maps,options);
update_logfile('---complete',output_log)
%find null distribution of cluster sizes for significant voxels
update_logfile('Calculating null cluster size distribution...',output_log)
cluster_null = calc_cluster_null(group_accuracy_maps,seed_thresholds,seed_inds,options);
update_logfile('---complete',output_log)
%find clusters in real results
update_logfile('Calculating experiment results...',output_log)
sig_vox = searchlight_results >= seed_thresholds;
[real_cluster_sizes,seed_cluster_info,Cl_inds] = cluster_search(seed_inds(sig_vox),options);
switch options.cluster_effect_stat
    case 't-stat'
        %find cumulative cluster t-statistic for result clusters
        Vmu = mean(group_accuracy_maps,2); %chance
        Vsd = std(group_accuracy_maps,[],2); %Stnd. error
        %get voxel logicals for each cluster
        Cl_inds = cellfun(@(x) ismember(seed_inds,x),Cl_inds,'uniformoutput',false);
        %calculate cumulative cluster t-stat (& replace "real cluster sizes")
        real_cluster_sizes = ...
            cellfun(@(x) sum((searchlight_results(x) - Vmu(x)) ./ Vsd(x)),Cl_inds);
        %now replace "seed_cluster_info"'s extent with t-stats
        for rep_idx = 1:numel(real_cluster_sizes)
            %really annoying vector index scheme mismatch...
            curr_cl = ismember(seed_inds(sig_vox),seed_inds(Cl_inds{rep_idx}));
            seed_cluster_info(curr_cl) = real_cluster_sizes(rep_idx);
        end
end



seed_cluster_info = [seed_inds(sig_vox) seed_cluster_info]; %reattach seed inds to their cluster sizes
update_logfile('---complete',output_log)
%find p values for real clusters

cluster_pvals = nan(size(real_cluster_sizes));
for idx = 1:numel(cluster_pvals)
    cluster_pvals(idx) = (sum(cluster_null >= real_cluster_sizes(idx)) + 1) / (numel(cluster_null) + 1);   %no zero pvals
end

[sorted_cluster_pvals,sig_rank] = sort(cluster_pvals);


if sum(~isnan(seed_cluster_info(:,2))) == 0
    %skip FDR testing, no clusters found
    significant_clusters = 0;
    update_logfile('Zero supra-threshold clusters observed in results!',output_log)
else
    
    %FDR threshold
    n = numel(real_cluster_sizes);
    q = 0.05; %alpha (FDR)
    c = 1; %independance-ish
    %c = sum([1:n].^-1); %no independance
    FDR_pvals = (1:n)'/n*q/c; %compare this to sorted pvalues
    
    significant_clusters = sorted_cluster_pvals <= FDR_pvals;
end

if sum(significant_clusters) > 0
    update_logfile(sprintf('Significant clusters found = %i',sum(significant_clusters)),output_log)
    disp(sprintf('Significant clusters found = %i',sum(significant_clusters)))
    significant_cluster_sizes = real_cluster_sizes(sig_rank);
    significant_cluster_sizes = significant_cluster_sizes(significant_clusters);
    searchlight_results2nii(significant_cluster_sizes,seed_cluster_info,options);
    
else
    update_logfile('No significant clusters',output_log)
end
searchlight_stats = [];
save(fullfile(options.save_dir,'stat_outcomes'),'cluster_null','sig_vox','real_cluster_sizes')



% bigclust = seed_cluster_info(:,2) > 30;
% bigloc = seed_cluster_info(bigclust,1);
% results2show = zeros(options.scan_vol_size);
% results2show(bigloc) = 1;
% 
% %show where the cluster is
% template_scan = load_nii(fullfile(options.script_dir,'view_niis','w3danat.nii')); %load template nifti file
% template_scan.img = results2show;
% template_scan.hdr.dime.datatype = 64; %reset to double (so decimals will work..)
% template_scan.hdr.dime.bitpix = 64;
% save_nii(template_scan,'cluster_results.nii')



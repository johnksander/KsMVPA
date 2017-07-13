function searchlight_stats = map_searchlight_significance(searchlight_reults,voxel_null,options)
%input:
%searhclight seed inds, r/classification accuracy (fisher's Z assumed)
%voxel null distribution
%options
%-----------------------------------------
%output searchlight stat results:
%cluster p values
%seed p vales
%binary 3d brain volume with significant voxels
%::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


%find p = .001 threshold map from permutation dist
seed_thresholds = voxel_sig_threshold(voxel_null);
%find null distribution of cluster sizes for significant voxels
cluster_null = calc_cluster_null(voxel_null,seed_thresholds,searchlight_reults(:,1),options);
%find clusters in real results
sig_vox = searchlight_reults(:,2) >= seed_thresholds;
[real_cluster_sizes,seed_cluster_info] = cluster_search(searchlight_reults(sig_vox,1),options.scan_vol_size);
seed_cluster_info = [searchlight_reults(sig_vox,1) seed_cluster_info]; %reattach seed inds to their cluster sizes
%find p values for real clusters

cluster_pvals = nan(size(real_cluster_sizes));
for idx = 1:numel(cluster_pvals)
    cluster_pvals(idx) = (sum(cluster_null > real_cluster_sizes(idx)) + 1) / (numel(cluster_null) + 1);   %no zero pvals
end

[sorted_cluster_pvals,sig_rank] = sort(cluster_pvals);



%FDR threshold
n = numel(real_cluster_sizes);
q = 0.05; %alpha (FDR)
c = 1; %independance-ish
%c = sum([1:n].^-1); %no independance
FDR_pvals = (1:n)'/n*q/c; %compare this to sorted pvalues
keyboard
significant_clusters = sorted_cluster_pvals <= FDR_pvals;

if sum(significant_clusters) > 0
    
    disp(sprintf('Significant clusters found = %i',sum(significant_clusters)))
    significant_cluster_sizes = real_cluster_sizes(sig_rank);
    significant_cluster_sizes = significant_cluster_sizes(significant_clusters);
    searchlight_results2nii(significant_cluster_sizes,seed_cluster_info,options);
    
else
    disp('No significant clusters...')
end





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



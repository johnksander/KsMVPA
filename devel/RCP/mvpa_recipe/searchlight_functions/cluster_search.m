function [vol_cluster_sizes,seed_cluster_sizes,vol_clusters] = cluster_search(seed_inds,options)
%find clusters of significant searchlight seeds 
%input- linear indicies of signficiant seeds, options struct containing
%both the 3D scan volume dimensions & the cluster connectivity scheme
%output- 
%   cluster_sizes: size of each unqiue cluster in volume 
%   seed_cluster_sizes: seed ind, cluster size (for that seed)
%   vol_cluster: indicies for each cluster (in cell array)

%this param now specified in set_options()
%cluster_conn = 6; %cluster connectivity scheme (6, 18, or 26)

scan_vol = zeros(options.scan_vol_size); %create scan matrix
scan_vol(seed_inds) = 1; %binarize with significant seeds
vol_clusters = bwconncomp(scan_vol,options.cluster_conn); %find clusters, face connectivity scheme
vol_clusters = vol_clusters.PixelIdxList'; 
loners = cellfun(@(x) numel(x) == 1,vol_clusters); %remove non cluster seeds
vol_clusters = vol_clusters(~loners);
vol_cluster_sizes = cellfun(@numel,vol_clusters); %size of all unique clusters 
seed_cluster_sizes = NaN(size(seed_inds));
for idx = 1:numel(vol_clusters) %find seed inds' cluster size 
    seed_cluster_sizes(ismember(seed_inds,vol_clusters{idx})) = numel(vol_clusters{idx});
end





% loners = cellfun(@(x) numel(x) == 1,cluster_info); %remove non cluster seeds
% cluster_info = cluster_info(~loners);
% vol_clusters = sum(cellfun(@numel,cluster_info));

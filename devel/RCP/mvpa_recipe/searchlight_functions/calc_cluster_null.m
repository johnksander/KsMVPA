function cluster_null = calc_cluster_null(group_accuracy_maps,seed_thresholds,seed_inds,options)
%find cluster null distribution from voxel permutation distributions
%input- voxel permutation distributions, voxel significance threshold, voxel linear indicies
%output- cluster extent threshold



num_straps = numel(group_accuracy_maps(1,:));
cluster_null = cell(num_straps,1);
for idx = 1:num_straps
    sig_voxels = group_accuracy_maps(:,idx) >= seed_thresholds;
    sig_voxels = seed_inds(sig_voxels);
    cluster_null{idx} = cluster_search(sig_voxels,options.scan_vol_size);
end
cluster_null = cell2mat(cluster_null);

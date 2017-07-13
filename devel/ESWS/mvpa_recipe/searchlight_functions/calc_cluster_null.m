function cluster_null = calc_cluster_null(voxel_null,seed_thresholds,seed_inds,options)
%find cluster null distribution from voxel permutation distributions
%input- voxel permutation distributions, voxel significance threshold, voxel linear indicies
%output- cluster extent threshold



num_perms = numel(voxel_null(1,:));
cluster_null = cell(num_perms,1);
for idx = 1:num_perms
    sig_voxels = voxel_null(:,idx) >= seed_thresholds;
    sig_voxels = seed_inds(sig_voxels);
    cluster_null{idx} = cluster_search(sig_voxels,options.scan_vol_size);
end
cluster_null = cell2mat(cluster_null);

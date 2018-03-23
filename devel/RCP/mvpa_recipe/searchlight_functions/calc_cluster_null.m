function cluster_null = calc_cluster_null(group_accuracy_maps,seed_thresholds,seed_inds,options)
%find cluster null distribution from voxel permutation distributions
%input- voxel permutation distributions, voxel significance threshold, voxel linear indicies
%output- cluster extent threshold (options.cluster_effect_stat = 'extent')
%or cluster t-stat threshold (options.cluster_effect_stat = 't-stat')



num_straps = numel(group_accuracy_maps(1,:));
cluster_null = cell(num_straps,1);

switch options.cluster_effect_stat
    case 't-stat' %precalcuate chance and S.E.
        Vmu = mean(group_accuracy_maps,2);
        Vsd = std(group_accuracy_maps,[],2);
end

for idx = 1:num_straps
    sig_voxels = group_accuracy_maps(:,idx) >= seed_thresholds;
    sig_voxels = seed_inds(sig_voxels);
    switch options.cluster_effect_stat
        case 'extent'
            %take cluster sizes
            cluster_null{idx} = cluster_search(sig_voxels,options);
        case 't-stat'
            %find cumulative cluster t-statistic
            [~,~,vol_clusters] = cluster_search(sig_voxels,options); %cluster inds
            if numel(vol_clusters) > 0 %only run if you find something
                whole_brain = group_accuracy_maps(:,idx); %current accuracy map
                %get voxel logicals for each cluster
                vox = cellfun(@(x) ismember(seed_inds,x),vol_clusters,'uniformoutput',false);
                %calculate cumulative cluster t-stat 
                cluster_t = cellfun(@(x) sum((whole_brain(x) - Vmu(x)) ./ Vsd(x)),vox);
                cluster_null{idx} = cluster_t;
            end
    end
end
cluster_null = cell2mat(cluster_null);













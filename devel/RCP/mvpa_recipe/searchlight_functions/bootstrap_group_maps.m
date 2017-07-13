function group_accuracy_maps = bootstrap_group_maps(voxel_null,group_map_keys)

num_subs = numel(group_map_keys(:,1));
num_straps = numel(group_map_keys(1,:));
num_searchlights = size(voxel_null);
num_searchlights = num_searchlights(1);

group_accuracy_maps = NaN(num_searchlights,num_straps);
for idx = 1:num_straps
    randmaps = NaN(num_searchlights,num_subs);
    for subidx = 1:num_subs
        randmaps(:,subidx) = voxel_null(:,group_map_keys(subidx,idx),subidx); 
    end
    group_accuracy_maps(:,idx) = mean(randmaps,2);
end
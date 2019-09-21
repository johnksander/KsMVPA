function group_map_keys = inds4groupmap(options,num_straps)
%%preallocate matrix for which accuracy map from each subject will be drawn
%for 10e5 group accuracy maps. This can be used to regenerate
%distributions since these arrays are too big for local RAM (100GB).

num_sub_maps = options.num_perms;
num_subjects = numel(options.subjects(~ismember(options.subjects,options.exclusions)));
group_map_keys = randi(num_sub_maps,num_subjects,num_straps);

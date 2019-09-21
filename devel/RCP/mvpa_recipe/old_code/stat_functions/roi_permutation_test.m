function [p_values,ci] = roi_permutation_test(data_structure,field,behavior,num_perms,ci_range,adj_chance)

%accuracy_data = data_structure.accuracy_mean;
accuracy_data = data_structure.(field);
if adj_chance == true,
    accuracy_data = accuracy_data - data_structure.chance;
end
accuracy_data = accuracy_data(:,:,behavior); %select a single behavior slice
dimension_size = size(accuracy_data); %2-d size vector
true_mean = nanmean(accuracy_data);
perm_matrix = nan(num_perms,numel(true_mean));
for idx = 1:num_perms,
    if (mod(idx,1000) == 0), fprintf('Permutation number: %d / %d\n', idx, num_perms); end
    ss = polarity_switch(dimension_size);
    perm_matrix(idx,:) = nanmean(ss.*accuracy_data);
end
gt_matrix = bsxfun(@gt,perm_matrix,true_mean);
p_values = (sum(gt_matrix) + 1) ./ (num_perms + 1); %adjust for 0 p-values
ci_low = 50 - ci_range/2;
ci_high = 100 - ci_low;
ci = cat(1,prctile(perm_matrix,ci_low),prctile(perm_matrix,ci_high));

function pm = polarity_switch(ds)
% pm = randi(2,[ds(1),1]) - 1;
% pm = repmat(pm,1,ds(2));
pm = randi(2,ds) - 1;
pm(pm==0) = -1;




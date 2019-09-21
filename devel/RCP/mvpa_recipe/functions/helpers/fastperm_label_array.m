function permd_labels = fastperm_label_array(true_labels,options)
%preallocate permuted labeling for fastperm test
permd_labels = cell(numel(true_labels),options.num_perms2test);
for idx = 1:options.num_perms2test
    permd_labels(:,idx) = perm_labels2cell(true_labels);
end


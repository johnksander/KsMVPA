function permd_labels = perm_labels2cell(true_labels)
rng('shuffle')
shuffle_order = randperm(sum(~isnan(vertcat(true_labels{:}))))'; %permutation order
subject_inds = cell(size(true_labels));
for idx = 1:numel(true_labels) %get subject inds for all trials 
    if ~isempty(true_labels{idx})
        subject_inds{idx} = repmat(idx,numel(true_labels{idx}),1);
    else %do nothing
    end
end
subject_inds = vertcat(subject_inds{:}); %collapse to matrix 
permed_label_mat = vertcat(true_labels{:}); %set up permed label matrix
only_labeled_trials = permed_label_mat(~isnan(permed_label_mat)); %take just the true labeled trials for easier indexing 
permed_label_mat(~isnan(permed_label_mat)) = only_labeled_trials(shuffle_order); %shuffle 
permd_labels = cell(size(true_labels)); %set up final permed labels array 
for idx = 1:numel(permd_labels) %get subject inds for all trials 
    if ~isempty(true_labels{idx})
        curr_subject = subject_inds == idx; %find which trials belong to subject 
        permd_labels{idx} = permed_label_mat(curr_subject); %put back into a cell array 
    else %do nothing
    end
end
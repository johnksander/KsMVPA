function models = train_oldMC_LDA(training_data,training_labels)
%train LDA models with "old MC" scheme. Make binary decision models for
%each partitioning of "one label vs the rest".

classes = sort(unique(training_labels));
n_class = numel(classes);
models = cell(1,n_class);

rest_label = 9999; %label for "the rest" in this scheme, reserved
if sum(classes == rest_label) > 0,error('label 9999 is reserved in old MC');end

for idx = 1:n_class
    target_class = classes(idx); %pick a class
    target_obs = ismember(training_labels,target_class); %corresponding trials
    
    target_labels = NaN(size(training_labels)); %new label vector
    target_labels(target_obs) = target_class;
    target_labels(~target_obs) = rest_label; %1 vs rest
    %train old MC model, LDA struct keeps the label names 
    models{idx} = fitcdiscr(training_data,target_labels,'Prior','uniform');
end
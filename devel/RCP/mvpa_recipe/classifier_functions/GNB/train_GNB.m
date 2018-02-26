function model = train_GNB(training_data,training_labels)
%Gaussian naive bayes--- special case. Just returns trained model for 
%regualr old timepoint x voxel matrix 

class_labels = unique(training_labels);
model.mu = NaN(numel(class_labels),numel(training_data(1,:)));
model.SD = NaN(numel(class_labels),numel(training_data(1,:)));
model.class_priors = NaN(size(class_labels)); %got a record so they put me with the baddest bunch
for idx = 1:numel(class_labels)
    curr_class = training_labels == class_labels(idx);
    model.mu(idx,:) = mean(training_data(curr_class,:));
    model.SD(idx,:) = std(training_data(curr_class,:));
    model.class_priors(idx) = log(sum(curr_class) / numel(curr_class));
end
model.class_labels = class_labels;




function [model_mu,model_SD,model_Cpriors] = GNBtrain_wholebrain(training_data,training_labels)
%Gaussian naive bayes: whole brain edition
%calculate mu & SD for class voxels, class priors 
%note: parfor won't let me use a structure for model output.. 

vsz = size(training_data);
vsz = vsz(2:3); %get size for voxels x searchlights
class_labels = unique(training_labels);
model_mu = NaN(numel(class_labels),vsz(1),vsz(2));
model_SD = NaN(numel(class_labels),vsz(1),vsz(2));
model_Cpriors = NaN(size(class_labels)); %got a record so they put me with the baddest bunch 
for idx = 1:numel(class_labels)
    curr_class = training_labels == class_labels(idx);
    model_mu(idx,:,:) = mean(training_data(curr_class,:,:),1);
    model_SD(idx,:,:) = std(training_data(curr_class,:,:),0,1);
    model_Cpriors(idx) = log(sum(curr_class) / numel(curr_class));
end
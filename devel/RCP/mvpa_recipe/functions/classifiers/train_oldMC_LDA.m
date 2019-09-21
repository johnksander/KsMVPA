function models = train_oldMC_LDA(training_data,training_labels)
%train LDA models with "old MC" scheme. Make binary decision models for
%each pairwise combination of labels. (note: can't do 1 v rest because 
%LDA needs better class balancing, setting uniform priors doesn't cut it).

classes = sort(unique(training_labels));
%n_class = numel(classes);
balcheck = cellfun(@(x) sum(training_labels == x), num2cell(classes));
balcheck = numel(unique(balcheck));
if balcheck > 1,error('balanced training classes required for old MC');end

class_pairs = nchoosek(classes,2);
n_pairs = numel(class_pairs(:,1));

models = cell(1,n_pairs);

for idx = 1:n_pairs
    target_classes = class_pairs(idx,:); %pick a binary combo 
    target_obs = ismember(training_labels,target_classes); %corresponding trials
    target_labels = training_labels(target_obs); %labels 
    target_data = training_data(target_obs,:); %data 
    %train old MC model, LDA struct keeps the label names 
    models{idx} = fitcdiscr(target_data,target_labels,...
        'DiscrimType',options.classifier_type,'Prior','uniform');
end




%depreciated: need to balance the class set better for LDA, just setting 
%uniform priors doesn't do it 
% 
% classes = sort(unique(training_labels));
% n_class = numel(classes);
% models = cell(1,n_class);
% 
% rest_label = 9999; %label for "the rest" in this scheme, reserved
% if sum(classes == rest_label) > 0,error('label 9999 is reserved in old MC');end
% 
% for idx = 1:n_class
%     target_class = classes(idx); %pick a class
%     target_obs = ismember(training_labels,target_class); %corresponding trials
%     
%     target_labels = NaN(size(training_labels)); %new label vector
%     target_labels(target_obs) = target_class;
%     target_labels(~target_obs) = rest_label; %1 vs rest
%     %train old MC model, LDA struct keeps the label names 
%     models{idx} = fitcdiscr(training_data,target_labels,'Prior','uniform');
% end

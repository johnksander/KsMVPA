function predictions  = test_oldMC_LDA(models,testing_data,true_labels)
%test LDA models with "old MC" scheme: binary decision models for
%each pairwise combination of labels (note: can't do 1 v rest because 
%LDA needs better class balancing, setting uniform priors doesn't cut it).
%Input--- cell array of models, binary model in each cell (array = 1 x n class pairs) 
%and testing data (obs x features), and the true testing labels (only used for partitioning data!!!!)
%the true testing labels takes format (N obs x N pairs) with NaNs for out-of-pair obs
%output--- trials x N class pairs prediction matrix 


%find model target class pairs
mdl_target_pairs = cellfun(@(x) x.ClassNames',models,'UniformOutput',false);
mdl_target_pairs = cat(1,mdl_target_pairs{:});
testing_pairs = cellfun(@(x) unique(x(~isnan(x))),num2cell(true_labels,1),'UniformOutput',false);

n_pairs = numel(mdl_target_pairs(:,1));
n_obs = numel(testing_data(:,1));

predictions = NaN(n_obs,n_pairs);

for idx = 1:n_pairs
    binary_model = models{idx}; %get binary model  
    target_classes = mdl_target_pairs(idx,:); %get corresponding label pair 
    %find the label vector for this pair 
    target_obs = cellfun(@(x) sum(ismember(target_classes,x)) == 2,testing_pairs); 
    target_obs = true_labels(:,target_obs); %corresponding pair of trials 
    target_obs = ~isnan(target_obs); %target pair trial indicies
    predictions(target_obs,idx) = predict(binary_model,testing_data(target_obs,:));
end

 



% %depreciated: need to balance the class set better for LDA, just setting 
%uniform priors doesn't do it. Input format changed consequently 
% rest_label = 9999; %label for "the rest" in this scheme, reserved
% 
% %find model target class (the "one label" type)
% mdl_target_classes = cellfun(@(x) x.ClassNames(x.ClassNames ~= rest_label)...
%     ,models,'UniformOutput',false);
% mdl_target_classes = cat(1,mdl_target_classes{:});
% 
% classes = sort(unique(mdl_target_classes)); %ensure these are sorted
% n_class = numel(classes);
% num_obs = numel(testing_data(:,1));
% 
% predictions = NaN(num_obs,n_class);
% 
% for idx = 1:n_class
%     target_class = classes(idx); %pick from ordered classes
%     %get corresponding model
%     binary_model = models{mdl_target_classes == target_class};
%     predictions(:,idx) = predict(binary_model,testing_data);
% end
% 

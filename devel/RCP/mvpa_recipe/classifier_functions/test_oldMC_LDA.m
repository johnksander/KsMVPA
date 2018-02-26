function predictions  = test_oldMC_LDA(models,testing_data)
%test LDA models with "old MC" scheme: binary decision models for
%each partitioning of "one label vs the rest". 
%Input--- cell array of models, binary model in each cell (array = 1 x n class) 
%and testing data (obs x features)
%output--- trials x N classes prediction matrix 

%The output's N classes dim is orgnaized by sorted label values,
%this is needed to match expected format for other oldMC stuff (i.e. label
%"1" is first, label "2" is second, etc)

rest_label = 9999; %label for "the rest" in this scheme, reserved

%find model target class (the "one label" type)
mdl_target_classes = cellfun(@(x) x.ClassNames(x.ClassNames ~= rest_label)...
    ,models,'UniformOutput',false);
mdl_target_classes = cat(1,mdl_target_classes{:});

classes = sort(unique(mdl_target_classes)); %ensure these are sorted
n_class = numel(classes);
num_obs = numel(testing_data(:,1));

predictions = NaN(num_obs,n_class);

for idx = 1:n_class
    target_class = classes(idx); %pick from ordered classes
    %get corresponding model
    binary_model = models{mdl_target_classes == target_class};
    predictions(:,idx) = predict(binary_model,testing_data);
end


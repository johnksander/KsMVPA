function label_predictions = equal_prior_GNB(cv_params,options)
%Gaussian naive bayes without a term for class prior probabilties 
%effectively assumes each class is equally likely in the population 


class_labels = unique(cv_params.training_labels);
model.mu = NaN(numel(class_labels),numel(cv_params.fe_training_data(1,:)));
model.SD = NaN(numel(class_labels),numel(cv_params.fe_training_data(1,:)));
for idx = 1:numel(class_labels)
    curr_class = cv_params.training_labels == class_labels(idx);
    model.mu(idx,:) = mean(cv_params.fe_training_data(curr_class,:));
    model.SD(idx,:) = std(cv_params.fe_training_data(curr_class,:));
end

test_class_probs = NaN(numel(cv_params.testing_labels),numel(class_labels)); %each row is an obs, each col is class prob
for idx = 1:numel(class_labels)
    %z score to class training data
    test_data = bsxfun(@rdivide,bsxfun(@minus,cv_params.fe_testing_data,model.mu(idx,:)),model.SD(idx,:));
    %get log gauss pdf probabilties for current class
    test_data = normpdf(test_data);
    test_data(test_data < eps) = eps; %protect against -Inf log probs
    test_data = log(test_data);
    %voxel joint probability (without class priors)
    test_class_probs(:,idx) = sum(test_data,2);
end
%pick class with highest probability
[~,label_predictions] = max(test_class_probs,[],2);
label_predictions = class_labels(label_predictions);


label_predictions = cat(2,label_predictions,cv_params.testing_labels);



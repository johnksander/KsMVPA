function label_predictions = GNBclassify_searchlight(testing_data,testing_labels,model)
%Gaussian naive bayes: searchlight classification edition
%input- searchlight *testing* data, testing labels, and 
%trained searchlight GNB model 
%output- label predictions


test_class_probs = NaN(numel(testing_labels),numel(model.class_labels)); %each row is an obs, each col is class prob
for idx = 1:numel(model.class_labels)
    %z score to class training data
    Xtest = bsxfun(@rdivide,bsxfun(@minus,testing_data,model.mu(idx,:)),model.SD(idx,:));
    %get log gauss pdf probabilties for current class 
    Xtest = normpdf(Xtest);
    Xtest(Xtest < eps) = eps; %protect against -Inf log probs
    Xtest = log(Xtest);
    %searchlight voxel joint probability with class priors
    test_class_probs(:,idx) = sum(Xtest,2) + model.class_priors(idx);
end
[~,label_predictions] = max(test_class_probs,[],2);
label_predictions = model.class_labels(label_predictions);


label_predictions = cat(2,label_predictions,testing_labels);



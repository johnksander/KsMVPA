function [label_predictions,auc_matrix] = logistic_multiclass(cv_params,options)

addpath(fullfile(options.classifier_function_dir,'minFunc'))
options = optimset('GradObj', 'on', 'MaxIter', 10000);

%Is not currently set up for multiclass... 
lambda = 10; %regularization parameter... Can be regularized later
c = size(cv_params.fe_training_data,2);
combo_names = unique(cv_params.training_labels);
combo_names(isnan(combo_names)) = [];
num_combos = numel(combo_names);
scores = nan(numel(cv_params.testing_labels),num_combos); 
auc_matrix = nan(num_combos,1);
for idx = 1:num_combos,
    target_training_labels = double(cv_params.training_labels == combo_names(idx));
    target_testing_labels = double(cv_params.testing_labels == combo_names(idx));
    theta0 = zeros(c+1,1);
    Xtr = cat(2,ones(size(cv_params.training_labels)),cv_params.fe_training_data);
    model = fminunc(...
       @(theta) logistic_cost_with_regularization(Xtr, target_training_labels, lambda, theta),...
       theta0, options);
    Xte = cat(2,ones(size(cv_params.testing_labels)),cv_params.fe_testing_data);
    scores(:,idx) = sigmoid(Xte * model); 
	if numel(unique(target_testing_labels)) == 1,
	   auc_matrix(idx) = NaN;
	else
           [~,~,~,auc_matrix(idx)] = perfcurve(target_testing_labels,scores(:,idx),1);
	end
end
if sum(isnan(auc_matrix)) == numel(auc_matrix),
   auc_matrix = .5;
else
   auc_matrix = nanmean(auc_matrix);
end
[~,label_predictions] = max(scores'); %gives max posterior prob
label_predictions = label_predictions'; %transpose
label_predictions = cat(2,label_predictions,cv_params.testing_labels);


function [J, gradient] = logistic_cost_with_regularization(X, y, lambda, theta)
%regularized logistic regression
[m, n] = size(X);
%g = @(z) 1 ./ (1 + exp(-z));
%h = g(X*theta);
h = sigmoid(X*theta);
J = (1/m)*sum(-y.*log(h) - (1-y).*log(1-h))+ (lambda/(2*m))*norm(theta(2:end))^2;
gradient = nan(1,n);
gradient(1) = (1/m)*sum((h-y) .* X(:,1));
for i = 2:n
    gradient(i) = (1/m)*sum((h-y) .* X(:,i)) - (lambda/m)*theta(i);
end

function g = sigmoid(z)
g = 1 ./ (1 + exp(-z));

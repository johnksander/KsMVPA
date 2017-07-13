function label_predictions = logistic(cv_params,options)

addpath(fullfile(options.classifier_function_dir,'minFunc'))
options = optimset('GradObj', 'on', 'MaxIter', 10000);

%Is not currently set up for multiclass... 
lambda = 1; %regularization parameter... Can be regularized later



c = size(cv_params.fe_training_data,2);
theta0 = zeros(c,1);
model = fminunc(...
    @(theta) logistic_cost_with_regularization(cv_params.fe_training_data, cv_params.training_labels, lambda, theta),...
    theta0, options);

scores = sigmoid(cv_params.fe_testing_data*model); %Y = g(XB);
label_predictions = round(scores); %Round the probabilities to get explicit labels
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

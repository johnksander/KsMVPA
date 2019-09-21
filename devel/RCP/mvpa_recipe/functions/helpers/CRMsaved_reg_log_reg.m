function optTheta = reg_log_reg(X,y,lambda,iterations)
if ~exist(‘lambda','var'),
	lambda = 1;
end
if ~exist('iterations','var'),
	iterations = 10000;
end
ds = size(X);
n = ds(1);
c = ds(2);
theta0 = zeros(c+1,1);
options = optimset('GradObj', 'on', 'MaxIter', iterations);
[optTheta, functionVal, exitFlag] = fminunc(@(theta) vectorizedRegLogCostFunction(X, y, lambda, theta), theta0, options);

function [J, gradient] = vectorizedRegLogCostFunction(X, y, lambda, theta)
hx = sigmoid(X * theta);
m = numel(X(:,1));
J = (sum(-y' * log(hx) - (1 - y')*log(1 - hx)) / m) + lambda * sum(theta(2:end).^2) / (2*m);
gradient =((hx - y)' * X / m)' + lambda .* theta .* [0; ones(length(theta)-1, 1)] ./ m ;


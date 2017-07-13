function [optTheta, functionVal, exitFlag] = regularized_LogReg(cv_params,options)

% Values for simulation -- can remove these 
n = numel(cv_params.training_labels); %number of observations -- needs to be replaced if not simulating, e.g. n = size(behavior,1);
c = numel(cv_params.training_data(1,:)); %number of design matrix columns
%v = 8; %value range for design matrix

% Putting the model together
lambda = 50; %regularization parameter
X_data = cv_params.training_data;
X_int = ones(n,1);
X = cat(2,X_int,X_data); %
y = cv_params.training_labels; %Replace with your DV

theta0 = zeros(c+1,1); % +1 since including an intercept
% warning off
% fmnfc_options = optimset('GradObj', 'on', 'MaxIter', 10000,'TolFun',1e-10,'TolX',1e-10); % You can change iterations as you see fit
% [optTheta, functionVal, exitFlag] = fminunc(@(theta) vectorizedRegLinearCostFunction(X, y, lambda, theta, cv_params), theta0, fmnfc_options);
% warning off
% %optTheta contains your "betas"

l = speye(size(X_data,1),size(X_data,1)) .* lambda;
l(1) = 0;
optTheta = (X'*X + lambda) \ X'*y; 
%Betas = (X'X + lambda) \ X'Y 
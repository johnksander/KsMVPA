function [J, gradient] = vectorizedRegLinearCostFunction(X, y, lambda, theta, cv_params)
    %regularized linear regression
   
    m = numel(X(:,1));
    hx = X*theta; %07292015: dropped transpose from theta- fixed dim mismatch error
    J = (sum(hx - y).^2)/(2*m) + ((lambda/(2*m)) * sum(theta(2:end)) .^ 2); 
    
    %Lopt_pkg.theta = theta;
    %%Lopt_pkg.y = y;
    %Lopt_pkg.X = X;
    %Lopt_pkg.lambda_range = [.1:.1:.9 1:10000];
    %Lopt_pkg.cv_idcs = crossvalind('Kfold', cv_params.training_labels, 5);
    
    
    %opt_Lambda = optimize_Lambda(Lopt_pkg,cv_params);


	gradient = ((hx-y)' * X / m)' + lambda .* theta .* [0; ones(length(theta)-1,1)] ./ m;

%%%Normal equation -- regular linear reguression holds if #examples > #features -- otherwise, noninvertable, and tons of regularization needed
%fi = eye(size(X));
%fi(1) = 0;
%theta = (X'*X + lambda*fi)\(X'Y);
    
    

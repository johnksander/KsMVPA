% cf_dir = '/Users/drewlinsley/Desktop/reg_fun'; %directory containing cost function & optimizer
% addpath(genpath(cf_dir)); %add those file pointers to path
% 07272015: taken care of in set_options

% Values for simulation -- can remove these 
n = 200; %number of observations -- needs to be replaced if not simulating, e.g. n = size(behavior,1);
c = 10; %number of design matrix columns
v = 8; %value range for design matrix

% Putting the model together
lambda = 10; %regularization parameter
X_data = randi(v,[n,c]);
X_int = ones(n,1);
X = cat(2,X_int,X_data); %
y = rand(n,1); %Replace with your DV

theta0 = zeros(c+1,1); % +1 since including an intercept
options = optimset('GradObj', 'on', 'MaxIter', 10000); % You can change iterations as you see fit
[optTheta, functionVal, exitFlag] = fminunc(@(theta) vectorizedRegLinearCostFunction(X, y, lambda, theta), theta0, options);
%optTheta contains your "betas"

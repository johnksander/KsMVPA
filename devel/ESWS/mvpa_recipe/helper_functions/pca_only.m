function [training_features,testing_features] = pca_only(cv_params,options)


%1. Normalize data
mu = mean(cv_params.training_data);
sd = std(cv_params.training_data);
sd(sd==0) = 1; %protect /0 errors
norm_training_data = bsxfun(@rdivide,bsxfun(@minus,cv_params.training_data,mu),sd);
norm_testing_data = bsxfun(@rdivide,bsxfun(@minus,cv_params.testing_data,mu),sd);

%2. Build PCA model
dcov = cov(norm_training_data);
[training_coeffs,~,err] = pcacov(dcov);

%3a. Identify dimensions to cut
err_cut = cumsum(err./sum(err));
err_cut = find(err_cut < options.PCAcomponents2keep,1,'last');
nc = size(norm_training_data,2) - 1;
err_cut = min(err_cut,nc);

%3b. Cut dimensions and create scores
training_coeffs = training_coeffs(:,1:err_cut);
training_features = norm_training_data * training_coeffs;
testing_features = norm_testing_data * training_coeffs;




% % %----------------------------------------
% %rule of one code: 
% %orig code 
% %1. Normalize data
% mu = mean(cv_params.training_data);
% sd = std(cv_params.training_data);
% sd(sd==0) = 1; %protect /0 errors
% norm_training_data = bsxfun(@rdivide,bsxfun(@minus,cv_params.training_data,mu),sd);
% norm_testing_data = bsxfun(@rdivide,bsxfun(@minus,cv_params.testing_data,mu),sd);
% 
% %2. Build PCA model
% dcov = cov(norm_training_data);
% [training_coeffs,~,err] = pcacov(dcov);
% 
% %3a. Identify dimensions to cut- rule of one 
% Rof1_thresh = 100 / numel(err); %err is in like, full percent digits (100.00 = 100% etc)
% err_cut = find(err > Rof1_thresh,1,'last');
% nc = size(norm_training_data,2) - 1;
% err_cut = min(err_cut,nc);
% 
% %3b. Cut dimensions and create scores
% training_coeffs = training_coeffs(:,1:err_cut);
% training_features = norm_training_data * training_coeffs;
% testing_features = norm_testing_data * training_coeffs;
% 







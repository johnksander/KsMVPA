function [training_features,testing_features] = pca_featsel(cv_params,options)


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
%err_cut = find(err_cut < .99,1,'last');
err_cut = find(err_cut < options.PCAcomponents2keep,1,'last');
nc = size(norm_training_data,2) - 1;
err_cut = min(err_cut,nc);

%3b. Cut dimensions and create scores
training_coeffs = training_coeffs(:,1:err_cut);
training_scores = norm_training_data * training_coeffs;
testing_scores = norm_testing_data * training_coeffs;
training_features = training_scores;
testing_features = testing_scores;

% %4a. set num_centroids
% if options.num_centroids < 1,
%     curr_num_centroids = round(options.num_centroids * size(training_scores,2));
% else
%     curr_num_centroids = options.num_centroids;
% end


% %4b. Train kmeans
% [~,trained_centroids] = kmeans(training_scores,curr_num_centroids,'MaxIter',1000,...
%     'Replicates',options.k_iterations,'options',statset('Display','off','UseParallel',1));
% training_features = extract_brain_features(training_scores,trained_centroids);
% testing_features = extract_brain_features(testing_scores,trained_centroids);


%%Figure out error between kmeans initializations
%[~,trained_centroids] = kmeans(training_scores,curr_num_centroids,'MaxIter',options.k_iterations,'Replicates',100);
%a = extract_brain_features(training_scores,trained_centroids);
%[~,trained_centroids] = kmeans(training_scores,curr_num_centroids,'MaxIter',options.k_iterations,'Replicates',100);
%b = extract_brain_features(training_scores,trained_centroids);
%plot(mean(a-b,2)) %plot average error at each dimension
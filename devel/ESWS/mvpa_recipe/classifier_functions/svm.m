function label_predictions = svm(cv_params,options)

t = 2; % 0 (linear) or 2 (radial basis function)
%c = 100; % Can optimize this at some point...
c = 10;
k = 1./size(cv_params.fe_training_data,2); %1/nfeatures; only useful for rbf
train_options = sprintf('-s 0 -t %i -c %f -g %f -q',t,c,k);
predict_options = '-q';
model = libsvmtrain(cv_params.training_labels,cv_params.fe_training_data,train_options);
label_predictions = libsvmpredict(cv_params.testing_labels,cv_params.fe_testing_data,model,predict_options);
label_predictions = cat(2,label_predictions,cv_params.testing_labels);

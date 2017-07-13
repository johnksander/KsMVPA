function label_predictions = kfhp_svm(cv_params,options)
%svm with hyperparameter optimization in training set, using libsvm's K-fold CV

t = 2; % 0 (linear) or 2 (radial basis function)
kfolds = 10;
predict_options = '-q'; %quiet mode


%find best C & gamma parameters by CVing on training data
C = -5:2:14; %range for C & gamma
gamma = -14:1:-5;
if t == 0 %fix gamma if model is linear 
    gamma = 1./size(cv_params.fe_training_data,2);
end
hp_combos = combvec(C,gamma); %get all parameter combos
C = hp_combos(1,:)'; %reassign to nice vectors
gamma = hp_combos(2,:)';
num_params = numel(C); %number of parameter combos to try

HPacc = NaN(num_params,1);

for hpidx = 1:num_params
        train_options = sprintf('-s 0 -t %i -c %f -g %f -v %d -q',t,2^C(hpidx),2^gamma(hpidx),kfolds);
        %HPacc(hpidx) = libsvmtrain(cv_params.training_labels,cv_params.fe_training_data,train_options);  
        %suppress all that garbage command-line output
        [~,HPacc(hpidx)] = evalc('libsvmtrain(cv_params.training_labels,cv_params.fe_training_data,train_options)');
end

[~,best_model] = max(HPacc);
bestC = 2^C(best_model);
bestGamma = 2^gamma(best_model);

%use optimized box paramater, do full classification on left-out testing data
train_options = sprintf('-s 0 -t %i -c %f -g %f -q',t,bestC,bestGamma);
model = libsvmtrain(cv_params.training_labels,cv_params.fe_training_data,train_options);
label_predictions = libsvmpredict(cv_params.testing_labels,cv_params.fe_testing_data,model,predict_options);
label_predictions = cat(2,label_predictions,cv_params.testing_labels);

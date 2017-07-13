function label_predictions = hp_svm(cv_params,options)
%svm with hyperparameter optimization in training set

t = 2; % 0 (linear) or 2 (radial basis function)
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

CVscheme = floor(1:.5:[(numel(cv_params.training_labels)/2)+.5])'; %by twos (LOSO here)
kfolds = numel(unique(CVscheme));
HPacc = NaN(num_params,1);

for hpidx = 1:num_params
    CVguesses = NaN(size(cv_params.training_labels));
    for idx = 1:kfolds
        train_inds = CVscheme ~= idx;
        val_inds = CVscheme == idx;
        train_options = sprintf('-s 0 -t %i -c %f -g %f -q',t,2^C(hpidx),2^gamma(hpidx));
        hpmodel = libsvmtrain(cv_params.training_labels(train_inds),cv_params.fe_training_data(train_inds,:),train_options);
        CVguesses(val_inds) = ...
            libsvmpredict(cv_params.training_labels(val_inds),cv_params.fe_training_data(val_inds,:),hpmodel,predict_options);
    end
    HPacc(hpidx) = sum(CVguesses == cv_params.training_labels) / numel(cv_params.training_labels);
end

[~,best_model] = max(HPacc);
bestC = 2^C(best_model);
bestGamma = 2^gamma(best_model);

%use optimized box paramater, do full classification on left-out testing data
train_options = sprintf('-s 0 -t %i -c %f -g %f -q',t,bestC,bestGamma);
model = libsvmtrain(cv_params.training_labels,cv_params.fe_training_data,train_options);
label_predictions = libsvmpredict(cv_params.testing_labels,cv_params.fe_testing_data,model,predict_options);
label_predictions = cat(2,label_predictions,cv_params.testing_labels);

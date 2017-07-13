function label_predictions = ridge_logistic(cv_params,options)

%not built


% adjust_labels = min(cv_params.training_labels); %it wants labels in range 0-n...
% Ytrain = cv_params.training_labels - adjust_labels; %adjust training labels
% k = 0:1e-4:5e-3;
% num_k = numel(k);
% 
% CVscheme = floor(1:.5:[(numel(cv_params.training_labels)/2)+.5])'; %by twos (LOSO here)
% kfolds = numel(unique(CVscheme));
% HPacc = NaN(num_k,1);
% 
% for hpidx = 1:num_k
%     CVguesses = NaN(size(cv_params.training_labels));
%     for idx = 1:kfolds
%         train_inds = CVscheme ~= idx;
%         val_inds = CVscheme == idx;
%         Brg = ridge(Ytrain(train_inds),cv_params.fe_training_data(train_inds,:),k(hpidx),0);
%         CVguesses(val_inds) = round(glmval(Brg,cv_params.fe_training_data(val_inds,:),'logit'));
%     end
%     HPacc(hpidx) = sum(CVguesses == Ytrain) / numel(Ytrain);
% end
% 
% label_predictions = round(label_predictions) + adjust_labels; %round probabilities to 0-1 labels, adjust back to input labels
% label_predictions = cat(2,label_predictions,cv_params.testing_labels);
% 
% 
% 

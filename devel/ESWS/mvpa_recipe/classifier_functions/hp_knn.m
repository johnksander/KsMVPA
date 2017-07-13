function label_predictions = hp_knn(cv_params,options)
%knn with k optimization in training set, using LOSO CV

k_params = .5:.5:6; %range for k search
num_params = numel(k_params);
CVscheme = floor(1:.5:[(numel(cv_params.training_labels)/2)+.5])'; %by twos (LOSO here)
kfolds = numel(unique(CVscheme));
HPacc = NaN(num_params,1);

for hpidx = 1:num_params
    CVguesses = NaN(size(cv_params.training_labels));
    for idx = 1:kfolds
        train_inds = CVscheme ~= idx;
        val_inds = CVscheme == idx;
        hpmodel = fitcknn(cv_params.fe_training_data(train_inds,:),cv_params.training_labels(train_inds),'Distance','euclidean',...
            'NumNeighbors',round(2^k_params(hpidx)));
        CVguesses(val_inds) = predict(hpmodel,cv_params.fe_training_data(val_inds,:));
        
    end
    HPacc(hpidx) = sum(CVguesses == cv_params.training_labels) / numel(cv_params.training_labels);
end

[~,best_model] = max(HPacc);
bestK = round(2^k_params(best_model));

%use optimized K neighbors, do full classification on left-out testing data
model = fitcknn(cv_params.fe_training_data,cv_params.training_labels,'NumNeighbors',bestK,'Distance','euclidean');
label_predictions = predict(model,cv_params.fe_testing_data);
label_predictions = cat(2,label_predictions,cv_params.testing_labels);



% k_fold = 10; %you can set K to either LOSO equivalent or set-up CV yourself 
% k_params = .5:.5:6; %range for k search
% num_params = numel(k_params);
% HPacc = NaN(num_params,1);
% 
% for hpidx = 1:num_params
%     hpmodel = fitcknn(cv_params.fe_training_data,cv_params.training_labels,'Distance','euclidean',...
%         'NumNeighbors',round(2^k_params(hpidx)),'KFold',k_fold);
%     HPacc(hpidx) = 1 - kfoldLoss(hpmodel);    
% end
% 
% [~,best_model] = max(HPacc);
% bestK = round(2^k_params(best_model));
% 
% %use optimized K neighbors, do full classification on left-out testing data
% model = fitcknn(cv_params.fe_training_data,cv_params.training_labels,'NumNeighbors',bestK,'Distance','euclidean');
% label_predictions = predict(model,cv_params.fe_testing_data);
% label_predictions = cat(2,label_predictions,cv_params.testing_labels);



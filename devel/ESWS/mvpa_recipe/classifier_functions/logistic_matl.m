function label_predictions = logistic_matl(cv_params,options)
%matlab's basic logistic regression implementation

adjust_labels = min(cv_params.training_labels); %it wants labels in range 0-n...
Ytrain = cv_params.training_labels - adjust_labels; %adjust training labels
model = fitglm(cv_params.fe_training_data,Ytrain,'linear','Distribution','binomial','BinomialSize',1,'link','logit');
label_predictions = feval(model,cv_params.fe_testing_data);
label_predictions = round(label_predictions) + adjust_labels; %round probabilities to 0-1 labels, adjust back to input labels
label_predictions = cat(2,label_predictions,cv_params.testing_labels);

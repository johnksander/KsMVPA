function label_predictions = lasso_logistic(cv_params,options)

adjust_labels = min(cv_params.training_labels); %it wants labels in range 0-n...
Ytrain = cv_params.training_labels - adjust_labels; %adjust training labels
[Breg,FitInfo] = lassoglm(cv_params.fe_training_data,Ytrain,'binomial','NumLambda',25,'CV',10);
Lreg = FitInfo.Index1SE; %best lambda index
Breg = Breg(:,Lreg); %regularized betas
Breg = [FitInfo.Intercept(Lreg);Breg]; %new intercept
label_predictions = glmval(Breg,cv_params.fe_testing_data,'logit');
label_predictions = round(label_predictions) + adjust_labels; %round probabilities to 0-1 labels, adjust back to input labels
label_predictions = cat(2,label_predictions,cv_params.testing_labels);

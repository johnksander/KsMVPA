function label_predictions = RelVec(cv_params,options)


[PARAMETER,~,~] = RelVec_train_model(cv_params,options);
label_predictions = RelVec_predict(cv_params,options,PARAMETER);
label_predictions = [label_predictions,cv_params.testing_labels];

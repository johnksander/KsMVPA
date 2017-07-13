function label_predictions = BNmatl(cv_params,options)
%matlab's bayes naive 

%model = fitcnb(cv_params.fe_training_data,cv_params.training_labels,'Distribution','kernel'); %kernel support 
model = fitcnb(cv_params.fe_training_data,cv_params.training_labels); %no kernel support
[label_predictions] = predict(model,cv_params.fe_testing_data); %can also get posteriors & cost here 
label_predictions = [label_predictions,cv_params.testing_labels];



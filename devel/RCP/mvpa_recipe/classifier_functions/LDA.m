function label_predictions = LDA(cv_params,options)

model = fitcdiscr(cv_params.fe_training_data,cv_params.training_labels,...
    'DiscrimType','diagQuadratic','SaveMemory','off','FillCoeffs','off'); 
[label_predictions] = predict(model,cv_params.fe_testing_data);  
label_predictions = [label_predictions,cv_params.testing_labels];


%alternate discriminant types 
%linear
%diagQuadratic
%pseudoQuadratic


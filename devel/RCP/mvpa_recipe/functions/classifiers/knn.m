function label_predictions = knn(cv_params,options)

model = fitcknn(cv_params.fe_training_data,cv_params.training_labels,'NumNeighbors',options.knn_neighbors,'Distance','euclidean');
label_predictions = predict(model,cv_params.fe_testing_data);
label_predictions = cat(2,label_predictions,cv_params.testing_labels);

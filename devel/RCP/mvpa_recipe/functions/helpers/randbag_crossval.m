function [cv_params] = randbag_crossval(behavioral_data,beh_idx,lagged_data)

%[training_data,training_labels,testing_data,testing_labels] = randbag_crossval(behavioral_data,beh_idx,lagged_data )
%explicit output set-up

[brain_data,trial_labels] = select_trials(lagged_data,behavioral_data{beh_idx});


%holdout, Nobservations (groupVec will acount for observation grouping),percent2holdout

[train_logical, test_logical] = crossvalind('HoldOut',trial_labels,.25);

training_data = brain_data(train_logical,:);
training_labels = trial_labels(train_logical);

testing_data = brain_data(test_logical,:);
testing_labels = trial_labels(test_logical,:);

cv_params.training_data = training_data;
cv_params.training_labels = training_labels;
cv_params.testing_data = testing_data;
cv_params.testing_labels = testing_labels;


end


function cv_struct = divy_cv_info(run_index,lagged_data,behavioral_data,run_perms,cv_idx,beh_idx)

runs = unique(run_index);
train_idx = run_perms(cv_idx,:);
test_idx = setdiff(runs,train_idx);
train_logical = ismember(run_index,train_idx);
test_logical = ismember(run_index,test_idx);
training_data = lagged_data(train_logical,:);
testing_data = lagged_data(test_logical,:);
training_labels = behavioral_data{beh_idx}(train_logical);
testing_labels = behavioral_data{beh_idx}(test_logical);
%removed NaN trial labels & scans here.
[training_data,training_labels] = select_trials(training_data,training_labels);
[testing_data,testing_labels] = select_trials(testing_data,testing_labels);
%max_beh_rating = max(behavioral_data{beh_idx}); %for softmax scaling


%cv_struct.max_val = max_beh_rating;                            
cv_struct.train_idx = train_idx;
cv_struct.test_idx = test_idx;
cv_struct.train_logical = train_logical;
cv_struct.test_logical = test_logical;
cv_struct.training_data = training_data;
cv_struct.testing_data = testing_data;
cv_struct.training_labels = training_labels;
cv_struct.testing_labels = testing_labels;

function accuracies = fastperm_getacc(current_combo_test,options)
%input: num_perms x CV folds
%output: accuracy vector for each permutation
accuracies = NaN(options.num_perms2test,1);
for idx = 1:options.num_perms2test
    current_test = current_combo_test(idx,:)';
    current_test = vertcat(current_test{:});
    accuracies(idx) = sum(current_test(:,1) == current_test(:,2)) / numel(current_test(:,1)); %accuracy for current test
end




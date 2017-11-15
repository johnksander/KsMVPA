function [normalized_data] = cocktail_blank_normalize(data_matrix,run_index)




normalized_data = NaN(size(data_matrix));
run_nums = unique(run_index);
for idx = 1:numel(run_nums)
    curr_run = run_nums(idx);
    runmask = run_index == curr_run;
    normalized_data(runmask,:) = zscore(data_matrix(runmask,:));
    
end
%fprintf('data set to zero mean unit variance: run wise\r')

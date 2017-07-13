function [normalized_data] = normalize_data(data_matrix,run_index)

normalized_data = NaN(size(data_matrix));
run_nums = unique(run_index);
for idx = 1:numel(run_nums)
    curr_run = run_nums(idx);
    runmask = run_index == curr_run;
    normalized_data(runmask,:) = zscore(detrend(data_matrix(runmask,:)));

end
    fprintf('data detrended & set to zero mean unit variance: run wise\r')
        %zscore detrend 
end


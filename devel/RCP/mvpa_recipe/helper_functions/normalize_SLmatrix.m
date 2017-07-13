function data_matrix = normalize_SLmatrix(data_matrix,run_index)

run_nums = unique(run_index);
for idx = 1:numel(run_nums)
    curr_run = run_nums(idx);
    runmask = run_index == curr_run;
    data_matrix(runmask,:,:) = zscore(data_matrix(runmask,:,:),[],1);
end
%fprintf('searchlight matrix set to zero mean & unit variance: run wise\r')

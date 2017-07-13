function [zca_whitened,M,P] = zca_whiten(data_matrix,lambda)
% Perform ZCA whitening
% usage:
% my_eps = .5;
% data_cells = cellfun(@(x) zca_whiten(x,my_eps),data_cells,'UniformOutput',false);
% zca_whitened_data = NaN(size(data_matrix));
% 
% run_nums = unique(run_index);
% for idx = 1:numel(run_nums)
%     curr_run = run_nums(idx);
%     runmask = run_index == curr_run;
%     run_data = data_matrix(runmask,:);
%     ztrn_data = run_data - repmat(mean(run_data,2),1,numel(run_data(1,:)));
% 
%     [U,S,~] = svd(cov(ztrn_data'));
%     zca_whitened = U * diag(1./sqrt(diag(S) + lambda)) * U' * ztrn_data;
%     zca_whitened_data(runmask,:) = zca_whitened;
%     sprintf('data whitened with ZCA: run-wise')
% end


C = cov(data_matrix);
M = mean(data_matrix);
[V,D] = eig(C);
P = V * diag(sqrt(1./(diag(D) + lambda))) * V';
zca_whitened = bsxfun(@minus, data_matrix, M) * P;
function [updated_mask] = update_mask4badvoxels(data_matrix,curr_mask,options)


%badvox = isnan(data_matrix) | data_matrix == 0;
badvox = isnan(data_matrix);
badvox = sum(badvox,1);
disp(sprintf('--Removing %d Bad Voxels',sum(badvox > 0)))
%fprintf('       %d Voxels have a zero value\r',sum(data_matrix(:) == 0))
disp('       Only NaN voxels removed')
goodvox = badvox == 0;
updated_mask = zeros(size(curr_mask));
updated_mask(curr_mask) = goodvox;
updated_mask = logical(updated_mask);


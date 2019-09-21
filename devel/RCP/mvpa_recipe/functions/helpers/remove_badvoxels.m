function [fixed_data_matrix] = remove_badvoxels(data_matrix)
    badvox = isnan(data_matrix) | data_matrix == 0;
    badvox = sum(badvox,1);
    fprintf('\r--Removing %d Bad Voxels from data & ROI mask\r',sum(badvox > 0))
    goodvox = badvox == 0;
    fixed_data_matrix = data_matrix(:,goodvox);
end


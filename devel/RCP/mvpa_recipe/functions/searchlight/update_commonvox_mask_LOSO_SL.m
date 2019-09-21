function [updated_mask] = update_commonvox_mask_LOSO_SL(mask_data,roi_idx,file_data,options)

curr_mask = mask_data(:,:,:,roi_idx); %get mask
data_matrix = apply_mask2data(curr_mask,file_data); %mask data
[updated_mask] = update_mask4badvoxels(data_matrix,curr_mask,options); %remove 0 & nan voxels from ROI mask

end


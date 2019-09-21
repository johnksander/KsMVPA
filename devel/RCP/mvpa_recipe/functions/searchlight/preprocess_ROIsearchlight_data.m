function [data,updated_mask] = preprocess_ROIsearchlight_data( mask_data,roi_idx,file_data,run_index)
            
            data = NaN(size(file_data));

            curr_mask = mask_data(:,:,:,roi_idx); %get mask
            data_matrix = apply_mask2data(curr_mask,file_data); %mask data
            [updated_mask] = update_mask4badvoxels(data_matrix,curr_mask); %remove 0 & nan voxels from ROI mask
            data_matrix = remove_badvoxels(data_matrix); %remove 0 & nan voxels from data 
            data_matrix = normalize_data(data_matrix,run_index); %detrend & zscore data runwise
            
            for idx = 1:size(data,4)
                curr_scan = data(:,:,:,idx);
                curr_scan(updated_mask) = data_matrix(idx,:);
                data(:,:,:,idx) = curr_scan;
            end

end


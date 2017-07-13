function [data_matrix] = apply_mask2data(mask,file_data)

data_matrix = NaN(size(file_data,4),sum(mask(:)));
for scanidx = 1:numel(data_matrix(:,1));
    curr_scan = file_data(:,:,:,scanidx);
    data_matrix(scanidx,:) = curr_scan(mask);
end
end


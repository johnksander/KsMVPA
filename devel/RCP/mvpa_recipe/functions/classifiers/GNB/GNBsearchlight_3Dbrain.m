function brain_vol = GNBsearchlight_3Dbrain(data_matrix,mask,options)


num_timepoints = numel(data_matrix(:,1));
brain_vol = NaN([options.scan_vol_size num_timepoints]);
for scanidx = 1:numel(data_matrix(:,1));
    curr_scan = NaN(options.scan_vol_size);
    curr_scan(mask) = data_matrix(scanidx,:);
    brain_vol(:,:,:,scanidx) = curr_scan;
end
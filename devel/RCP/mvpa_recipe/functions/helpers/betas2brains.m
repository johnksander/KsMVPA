function brains = betas2brains(betas,curr_mask)


num_trials = numel(betas(:,1));
vol_size = [size(curr_mask) num_trials];
brains = NaN(vol_size);

for idx = 1:num_trials
    holder_brain = NaN(size(curr_mask));
    holder_brain(curr_mask) = betas(idx,:);
    brains(:,:,:,idx) = holder_brain;
end


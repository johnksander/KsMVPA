function conv_data = conv_TRwindow(data_matrix,run_index,k)


disp('WARNING: conv_TRwindow() is not a good choice, see comments')


num_runs = numel(unique(run_index));
num_voxels = size(data_matrix,2);
conv_data = nan(size(data_matrix));
smoothing_window = ones(1,k) ./ k;
for voxel_idx = 1:num_voxels, 
    for runwise_idx = 1:num_runs,
        this_run = run_index == runwise_idx;
        voxel_vector = data_matrix(this_run,voxel_idx);
        conv_data(this_run,voxel_idx) = conv(voxel_vector,smoothing_window,'same');
    end
end


%6/13/2016, this function doesn't give you what you want for lags > 2. For
%a lag of 3, this will happen 
% 
%     1.0000    1.3333
%     3.0000    3.0000
%     5.0000    5.0000
%     7.0000    7.0000
%     9.0000    9.0000

%   notice: mean([5 7 9]) is 7, so the onset of this lagged window is
%   actually index #4 of column 2 (col2(4) = 7), but the data starts at index 3 of column 1 (col1(3:5) = 5,7,9) 

% y = conv(voxel_vector,smoothing_window,'same');
% 
% v = [1:2:20]';
% z = conv(v,smoothing_window,'same');
% t = conv(v,smoothing_window,'full');
% 
% t = t(1:10);
% 
% conv([1:2:20]',smoothing_window,'valid');

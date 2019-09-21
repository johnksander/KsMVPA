function [averaged_data] = averagedata_over_TRwindow(data_matrix,run_index,num_delay)

%num delay value includes starting point, ie - 
%num delay = 3 will average over the starting TR + the next 2 TRs 


averaged_data = NaN(numel(data_matrix(:,1)),numel(data_matrix(1,:)),num_delay);

for runwise_idx = 1:numel(unique(run_index))
    for delay_idx = 1:num_delay
        % do num_delay, store it in an extra dimension
        td = data_matrix(run_index==runwise_idx,:);
        averaged_data(run_index==runwise_idx,:,delay_idx) = cat(1,td(delay_idx:end,:),repmat(td(end,:),(delay_idx - 1),1));      
        %instead of adding the mean runwise vox value to end, adding the last vox value 
        %so, ie - averaging over the last vox + 3 delay will just give you the last vox value 
    end
end
averaged_data = mean(averaged_data,3);


end


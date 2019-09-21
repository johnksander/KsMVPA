function lagged_data = HDRlag(options,data,run_index)
%1- averages over a window of TRs
%2- lags fmri data



num_runs = numel(unique(run_index));

%1- smooth over TR window
%-------------------------------------------------
if options.TR_avg_window > 1
    
    window_width = options.TR_avg_window;
    data2average = NaN(numel(data(:,1)),numel(data(1,:)),window_width);
    
    for idx = 1:num_runs
        run_data = data(run_index==idx,:); % store window elements in extra dimension
        for window_idx = 1:window_width
            % store window elements in extra dimension
            data2average(run_index==idx,:,window_idx) = [run_data(window_idx:end,:);NaN(window_idx-1,numel(run_data(1,:)))];
            %instead of adding the mean runwise vox value to end, adding NaNs
            %in this way, averaging over the last vox at 3 TR window will just give you the last vox value
        end
    end
    data = nanmean(data2average,3);
end


%2- lag data
%-------------------------------------------------
if  options.TR_delay > 0
    num_delay = options.TR_delay;
    num_delay = num_delay + 1;
    lagged_data = NaN(size(data));
    for idx = 1:num_runs
        run_data = data(run_index==idx,:);
        %lagged_data(run_index==idx,:) = cat(1,run_data(num_delay:end,:),repmat(mean(run_data),num_delay-1,1)); %fill extra TRs with mean voxel value over timecourse
        %lagged_data(run_index==idx,:) = [run_data(num_delay:end,:);repmat(run_data(end,:),num_delay-1,1)]; %fill extra TRs with last voxel value of run
        lagged_data(run_index==idx,:) = cat(1,run_data(num_delay:end,:),NaN(num_delay-1,numel(run_data(1,:)))); %06/14/2016: this is the way to go, especially for lacking fmri data @ end of run
        %fill extra TRs with NaN, so you don't mess up the last trial!!
    end
else
    %setting options.tr_delay to 0 wouldn't lag the data anyways, but the function gets stuck with anatomical data
    lagged_data = data;
end













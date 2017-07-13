function [compressed_matrix,compressed_beh] = temporal_compression_runwise(data_matrix,beh_matrix,run_index)


num_runs = numel(unique(run_index));

compressed_matrix = cell(num_runs,1);
compressed_beh = cell(num_runs,1);
for ridx = 1:num_runs
    runmask = run_index == ridx;
    data = data_matrix(runmask,:);
    behav = beh_matrix(runmask);
    [compressed_matrix{ridx},compressed_beh{ridx}] = Tcomp(data,behav);
end
compressed_matrix = cell2mat(compressed_matrix);
compressed_beh = cell2mat(compressed_beh);




function [comp_mat,comp_beh] = Tcomp(data,behav)
%regular temporal compression func 
trial_classes = unique(behav(~isnan(behav)));
comp_mat = NaN(numel(trial_classes),numel(data(1,:)));
comp_beh = unique(behav(~isnan(behav)));

for idx = 1:numel(trial_classes)
    curr_class = trial_classes(idx);
    trials2compress = behav == curr_class;
    trials2compress = data(trials2compress,:);
    comp_mat(idx,:) = mean(trials2compress); 
end








function [compressed_matrix,compressed_beh] = temporal_compression(data_matrix,beh_matrix,options)


trial_classes = unique(beh_matrix(~isnan(beh_matrix)));
compressed_matrix = NaN(numel(trial_classes),numel(data_matrix(1,:)));
compressed_beh = unique(beh_matrix(~isnan(beh_matrix)));

for idx = 1:numel(trial_classes)
    curr_class = trial_classes(idx);
    trials2compress = beh_matrix == curr_class;
    trials2compress = data_matrix(trials2compress,:);
    compressed_matrix(idx,:) = mean(trials2compress); 
end




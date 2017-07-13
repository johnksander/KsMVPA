function seed_thresholds = voxel_sig_threshold(group_accuracy_maps)
%map each searchlight seed's r/accuracy sigificance threshold from permutation distribution
%input: seed x permutation result matrix
%output: seed minimum r/accuracy value for signifiance (vector)


alpha = .001;


tind = [1:numel(group_accuracy_maps(1,:))] ./ numel(group_accuracy_maps(1,:));
[~,tind] = min(abs(tind - (1 - alpha)));
tind = min(tind); %in case there's a tie or something
group_accuracy_maps = sort(group_accuracy_maps,2); %watch out, this doubles group_accuracy_maps in memory 
seed_thresholds = group_accuracy_maps(:,tind);


%seed_thresholds = prctile(group_accuracy_maps,100-alpha,2); %gives inexact values



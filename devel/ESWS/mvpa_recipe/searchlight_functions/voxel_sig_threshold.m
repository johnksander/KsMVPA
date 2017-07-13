function seed_thresholds = voxel_sig_threshold(voxel_null)
%map each searchlight seed's r/accuracy sigificance threshold from permutation distribution
%input: seed x permutation result matrix
%output: seed minimum r/accuracy value for signifiance (vector)


alpha = .001;
tind = [1:numel(voxel_null(1,:))] ./ numel(voxel_null(1,:));
[~,tind] = min(abs(tind - (1 - alpha)));
tind = min(tind); %in case there's a tie or something
voxel_null = sort(voxel_null,2); %watch out, this doubles voxel_null in memory 
seed_thresholds = voxel_null(:,tind);


%seed_thresholds = prctile(voxel_null,100-alpha,2); %gives inexact values



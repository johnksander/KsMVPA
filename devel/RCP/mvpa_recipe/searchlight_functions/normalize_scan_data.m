function data = normalize_scan_data(data)

for il = 1:numel(data), %expect a cell array, with each cell a different run
    mu = nanmean(data{il},4); %mean across conditions for every voxel for this run
    sd = nanstd(data{il},[],4); %same sd calculation
    data{il} = bsxfun(@rdivide,bsxfun(@minus,data{il},mu),sd); %z-score
end

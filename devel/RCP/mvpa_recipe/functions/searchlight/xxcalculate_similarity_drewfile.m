function brain_data = xxcalculate_similarity_drewfile(normed_data,inds)

brain_data = nan(numel(inds),numel(normed_data{1}(1,1,1,:)),numel(normed_data)); %search_size X condition X run
search_size = numel(inds);
for idx = 1:numel(brain_data(1,:,1)), %condition loop
    for il = 1:numel(brain_data(1,1,:)), %run loop
        tbrain = normed_data{il}(:,:,:,idx);
        tbrain = tbrain(inds(~isnan(inds)));
        brain_data(:,idx,il) = cat(1,tbrain,...
            nan(search_size - numel(tbrain),1));
    end
end

brain_data = nanmean(brain_data,3)';
brain_data(:,isnan(sum(brain_data))) = [];
brain_data = pdist(brain_data,'euclidean');
%brain_data = reshape(brain_data,numel(brain_data(:,1,1)),[]);


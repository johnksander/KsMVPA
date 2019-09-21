function label_predictions = minpool(cv_params,options)

classes = unique(cv_params.training_labels);

%form pattern representations w/ brain data
bin_cells = cell(numel(classes),1);
for idx = 1:numel(classes)
    bin_cells{idx} = cv_params.fe_training_data(cv_params.training_labels == classes(idx),:);
end


dists = nan(numel(classes),numel(cv_params.fe_testing_data(:,1)));
for rei = 1:numel(classes),
    rdists = pdist2(bin_cells{rei},cv_params.fe_testing_data,'euclidean');
    dists(rei,:) = min(rdists);
end

[~,choices] = min(dists);
label_predictions = (choices+(min(classes)-1))';
label_predictions = cat(2,label_predictions,cv_params.testing_labels);
end


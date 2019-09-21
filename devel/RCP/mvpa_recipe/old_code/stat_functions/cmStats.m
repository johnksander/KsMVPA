function cmStruct = cmStats(labels,predicted)

cmStruct.fold_ids = unique(true);
cmStruct.num_folds = numel(cmStruct.fold_ids);
cmStruct.cm = cell(cmStruct.fold_ids,1);
cmStruct.precision = nan(cmStruct.num_folds,1);
cmStruct.recall = nan(cmStruct.num_folds,1);
cmStruct.mcc = nan(cmStruct.num_folds,1);
cmStruct.Fscore = nan(cmStruct.num_folds,1);
for idx = 1:cmStruct.num_folds
    it_true = labels == cmStruct.fold_ids(idx);
    it_predicted = predicted == cmStruct.fold_ids(idx);
    cmStruct.cm{idx} = confusionmat(it_true,it_predicted);
    tp = cmStruct.cm{idx}(1,1);
    tn = cmStruct.cm{idx}(2,2);
    fp = cmStruct.cm{idx}(1,2);
    fn = cmStruct.cm{idx}(2,1);
    cmStruct.accuracy(idx) = trace(cmStruct.cm{idx}) ./ sum(cmStruct.cm{idx}(:));
    cmStruct.precision(idx) = tp ./ (tp + fp);
    cmStruct.recall(idx) = tp ./ (tp + fn);
    cmStruct.mcc(idx) = ((tp * tn) - (fp * fn)) ./ ...
        sqrt((tp + fp) * (tp + fn) * (tn + fp) * (tn + fn));
    cmStruct.Fscore(idx) = (2*tp) ./ ((2*tp) + fp + fn);
end


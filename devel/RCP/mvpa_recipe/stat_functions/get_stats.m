
num_perms = 10000;
ci_range = 90;
behaviors = 1:4;
rois = {'left hippocampus', 'right hippocampus', 'left amy', 'right amy', 'left phc', 'right phc', 'left thalmus', 'right thalmus'};

roi_statistics.cm = cell(size(roi_statistics));
roi_statistics.mcc = nan(size(roi_statistics));
roi_statistics.acc = nan(size(roi_statistics));
roi_statistics.f = nan(size(roi_statistics));
for x = 1:size(roi_output,1),
    for y = 1:size(roi_output,2),
        for z = 1:size(roi_output,3),
            if ~isempty(roi_output{x,y,z}),
                it_stats = cmStats(roi_output{x,y,z}(:,2),roi_output{x,y,z}(:,1));
                roi_statistics.cm{x,y,z} = it_stats.cm{1};
                roi_statistics.mcc(x,y,z) = it_stats.mcc;
                roi_statistics.acc(x,y,z) = it_stats.accuracy;
                roi_statistics.f(x,y,z) = it_stats.Fscore;
            end
        end
    end
end

roi_statistics.acc(roi_statistics.acc==0)=NaN;
acc_means = nan(numel(behaviors),numel(rois));
acc_p_values = nan(numel(behaviors),numel(rois));
acc_ci = nan(2,numel(rois),numel(behaviors));
f_p_values = acc_p_values;
f_ci = acc_ci;
mcc_p_values = acc_p_values;
mcc_ci = acc_ci;
for idx = 1:numel(behaviors),
    acc_means(idx,:) = nanmean(roi_statistics.accuracy_mean(:,:,idx));
    [acc_p_values(idx,:),acc_ci(:,:,idx)] = roi_permutation_test(roi_statistics,'acc',idx,num_perms,ci_range,true);
    [f_p_values(idx,:),f_ci(:,:,idx)] = roi_permutation_test(roi_statistics,'f',idx,num_perms,ci_range,true);
    [mcc_p_values(idx,:),mcc_ci(:,:,idx)] = roi_permutation_test(roi_statistics,'mcc',idx,num_perms,ci_range,false);
end

save('minpool_LOSO_statistics','acc_means','acc_p_values','acc_ci');
%[p_values,ci] = roi_permutation_test(data_structure,f,behavior,num_perms,ci_range);

clear
clc
format compact

result_dir = '/home/acclab/Desktop/ksander/KsMVPA/Results/';
aname = 'LOSO_ROI_searchlight_followup_svm_rbf_noCBR';
ci_range = 90; %confidence interval
ci_low = 50 - ci_range/2;
ci_high = 100 - ci_low;

%load classification results
predictions = load(fullfile(result_dir,aname,[aname '_predictions.mat']));
options = predictions.options;
predictions = predictions.predictions;
classifier_name = strrep(func2str(options.classifier_type),'@',''); %just for nice output

%load null distribution
null_accuracies = load(fullfile(result_dir,[aname '_perm'],[aname '_perm_null.mat']));
null_accuracies = null_accuracies.null_accuracies;

for roi_idx = 1:numel(options.roi_list)
    
    real_accuracy = predictions(:,roi_idx);
    real_accuracy = vertcat(real_accuracy{:});
    real_accuracy = (sum(real_accuracy(:,1) == real_accuracy(:,2))) / numel(real_accuracy(:,1));
    
    p_val = (sum(null_accuracies(:,roi_idx) > real_accuracy) + 1) / (numel(null_accuracies(:,roi_idx)) + 1);
 
    ci = cat(1,prctile(null_accuracies,ci_low),prctile(null_accuracies,ci_high));
    ci = ci - mean(null_accuracies);
    
    disp(sprintf('\nROI: %s',options.rois4fig{roi_idx}))
    disp(sprintf('Classifier: %s\n',classifier_name))
    disp(sprintf('----accuracy = %.2f%%',real_accuracy*100))
    disp(sprintf('----C.I. = %.2f%% - %.2f%%',(real_accuracy*100) + (ci*100)))
    disp(sprintf('----empirical chance = %.2f%%',mean(null_accuracies)*100))
    disp(sprintf('----p = %.4f',p_val))
    
    
end

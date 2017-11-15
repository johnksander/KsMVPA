clear
clc
format compact

result_dir = '/data/netapp/jksander/KsMVPA/Results/';
aname = 'LOSO_ROI_searchlight_followup_gender2_gnb';
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

%set up output file
output_log = fullfile(options.save_dir,'stats_results.txt');
if exist(output_log) > 0
    delete(output_log) %fresh start
end

for roi_idx = 1:numel(options.roi_list)
    
    real_accuracy = predictions(:,roi_idx);
    real_accuracy = vertcat(real_accuracy{:});
    real_accuracy = (sum(real_accuracy(:,1) == real_accuracy(:,2))) / numel(real_accuracy(:,1));
    
    p_val = (sum(null_accuracies(:,roi_idx) > real_accuracy) + 1) / (numel(null_accuracies(:,roi_idx)) + 1);
    
    ci = cat(1,prctile(null_accuracies,ci_low),prctile(null_accuracies,ci_high));
    ci = ci - mean(null_accuracies);
    
    txtappend(output_log,sprintf('\nROI: %s',options.rois4fig{roi_idx}))
    txtappend(output_log,sprintf('\nClassifier: %s\n',classifier_name))
    txtappend(output_log,sprintf('\n----accuracy = %.2f',real_accuracy*100))
    txtappend(output_log,sprintf('\n----C.I. = %.2f - %.2f',(real_accuracy*100) + (ci*100)))
    txtappend(output_log,sprintf('\n----empirical chance = %.2f',mean(null_accuracies)*100))
    txtappend(output_log,sprintf('\n----p = %.4f\n',p_val))
    
end

%---cleanup-------------------
driverfile = mfilename;
backup_jobcode(driverfile,options)
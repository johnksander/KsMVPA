function output = summarize_mvpa(mvpa_structure,options)
mvpa_size = size(mvpa_structure);
%mvpa structure format, for every cell: col1 = class guess, col2 = actual label, col3 = run index
cm_cells = cell(mvpa_size);
level_matrix = nan(mvpa_size);
chance_matrix = nan(mvpa_size);
mean_accuracy = nan(mvpa_size);
mean_Fscore = nan(mvpa_size);
MCC = nan(mvpa_size);
cm_acc = NaN(mvpa_size); 
for sub_idx = 1:mvpa_size(1),
    if ismember(options.subjects(sub_idx),options.exclusions) == 1
        %Don't do anything
    else 
        for roi_idx = 1:mvpa_size(2),
            for beh_idx = 1:mvpa_size(3),
                this_data = mvpa_structure{sub_idx,roi_idx,beh_idx};
                curr_confmat = confusionmat(this_data(:,2),this_data(:,1));
                cm_cells{sub_idx,roi_idx,beh_idx} = curr_confmat;
                level_matrix(sub_idx,roi_idx,beh_idx) = size(cm_cells{sub_idx,roi_idx,beh_idx},1);
                chance_matrix(sub_idx,roi_idx,beh_idx) = 1./level_matrix(sub_idx,roi_idx,beh_idx);
                %number_of_stimuli = numel(this_data(:,1));
                %mean_accuracy(sub_idx,roi_idx,beh_idx) = sum(diag(cm_cells{sub_idx,roi_idx,beh_idx})) ./...
                %sum(cm_cells{sub_idx,roi_idx,beh_idx}(~eye(level_matrix(sub_idx,roi_idx,beh_idx))));
                cm_acc(sub_idx,roi_idx,beh_idx) = trace(curr_confmat) / (sum(curr_confmat(:)));
                classlist = unique(this_data(:,2));
                [~,~,~,~,~,Fscore,~,~,~] = compute_accuracy_F(this_data(:,2),this_data(:,1),classlist);
                [TP,FP,FN,TN] = confmat_summary(this_data(:,2),this_data(:,1));
                curr_MCCstat = calcMCC(TP,FP,FN,TN);
                %stats = cfmatrix2(this_data(:,2),this_data(:,1), classlist, 0, 1)
                %stats = confusionmatStats(cm_cells{sub_idx,roi_idx,beh_idx});
%                 if sum(Fscore > 1) > 0
%                     keyboard
%                 elseif sum(cm_acc(sub_idx,roi_idx,beh_idx) > 1) > 0
%                     keyboard
%                 end
                %mean_accuracy(sub_idx,roi_idx,beh_idx) = options.cv_summary_statistic(stats.accuracy);
                MCC(sub_idx,roi_idx,beh_idx) = curr_MCCstat;
                mean_accuracy(sub_idx,roi_idx,beh_idx) = sum(this_data(:,1) == this_data(:,2)) ./ numel(this_data(:,1));
                mean_Fscore(sub_idx,roi_idx,beh_idx) = options.cv_summary_statistic(Fscore);
            end
        end
    end
end
output.cm = cm_cells;
output.levels = level_matrix;
output.chance = chance_matrix;
output.cm_acc = cm_acc;
output.accuracy_mean = mean_accuracy;
output.MCC = MCC;
output.Fscore_mean = mean_Fscore;



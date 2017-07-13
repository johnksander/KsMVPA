function [sel_data,sel_labels] = select_trials_normdata(data,labels)
select_rows = ~isnan(labels);
sel_labels = labels(select_rows);
sel_data = zscore(data(select_rows,:));
end


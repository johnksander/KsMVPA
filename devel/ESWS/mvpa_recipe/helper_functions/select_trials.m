function [sel_data,sel_labels] = select_trials(data,labels)

select_rows = ~isnan(labels);
sel_labels = labels(select_rows);
if numel(data(:,1)) ~= numel(sel_labels) %data also needs to be selected
    sel_data = data(select_rows,:);
elseif numel(data(:,1)) == numel(sel_labels) %data already selected (i.e. only estimated trials present)
    sel_data = data;    
end


end


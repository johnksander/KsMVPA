function [sel_data,sel_labels] = select_trials(data,labels)


sz = size(data);

if numel(sz) == 2 %got a nice 2D matrix
    
    select_rows = ~isnan(labels);
    sel_labels = labels(select_rows);
    if numel(data(:,1)) ~= numel(sel_labels) %data also needs to be selected
        sel_data = data(select_rows,:);
    elseif numel(data(:,1)) == numel(sel_labels) %data already selected (i.e. only estimated trials present)
        sel_data = data;
    end
    
    
elseif numel(sz) == 4 %nevermind...
    
    select_rows = ~isnan(labels);
    sel_labels = labels(select_rows);
    if sz(4) ~= numel(sel_labels) %data also needs to be selected
        sel_data = data(:,:,:,select_rows);
    elseif sz(4) == numel(sel_labels) %data already selected (i.e. only estimated trials present)
        sel_data = data;
    end
    
end


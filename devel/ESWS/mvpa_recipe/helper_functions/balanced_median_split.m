function [split_data] = balanced_median_split(data)

split_data = NaN(size(data));
possible_splits = cell(2,2);
split_balance = NaN(2,1);
%row 1 = low, row 2 = high

%find balanced median splits for all conditons
%--------------------------------------------
for cidx = 1:numel(data(1,:));
    rating_data = data(:,cidx);
    
    med_ratdata = nanmedian(rating_data);
    splita_low = find(rating_data < med_ratdata);
    splita_high = find(rating_data >= med_ratdata);
    splitb_low = find(rating_data <= med_ratdata);
    splitb_high = find(rating_data > med_ratdata);
    possible_splits{1,1} = splita_low;
    possible_splits{1,2} = splita_high;
    possible_splits{2,1} = splitb_low;
    possible_splits{2,2} = splitb_high;
    
    for sidx = 1:numel(possible_splits(:,2))
        split_balance(sidx) = abs(numel(possible_splits{sidx,1}) - numel(possible_splits{sidx,2}));
    end
    
    [best_split,~] = find(split_balance == min(split_balance));
    
    if numel(best_split) == 2
        best_split = 1;
    end
    
    if best_split == 1
        [low_rows,~] = find(rating_data < med_ratdata);
        [high_rows,~] = find(rating_data >= med_ratdata);
    end
    
    if best_split == 2
        [low_rows,~] = find(rating_data <= med_ratdata);
        [high_rows,~] = find(rating_data > med_ratdata);
    end
    
    rating_data(low_rows) = 0;
    rating_data(high_rows) = 1;
    
    split_data(:,cidx) = rating_data;
    
end

end


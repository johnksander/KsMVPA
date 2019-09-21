function accuracies = get_accuracy(cell_array)

accuracies = cellfun(@(x) sum(x(:,1) == x(:,2)) ./ numel(x(:,1)),cell_array);
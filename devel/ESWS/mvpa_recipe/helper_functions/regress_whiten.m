function [regressed_data] = regress_whiten(data_matrix,MCQDmatrix,run_index,options)

if numel(MCQDmatrix(1,:)) > 1
    disp(sprintf('regress_whiten only takes 1 column vector of trials'))
    keyboard
end

regressed_data = NaN(size(data_matrix));

for run = unique(run_index)'
    run_datamat = data_matrix(find(run_index==run),:);
    beh_rating = MCQDmatrix(find(run_index==run));
    beh_actual = find(~isnan(beh_rating));
    beh_rating(end) = beh_rating(beh_actual(end));
    beh_actual = find(~isnan(beh_rating)); 
    for jl = 1:numel(beh_rating)
        if isnan(beh_rating(jl)) 
            % replace it
            beh_rating(jl) = beh_rating(beh_actual(min(find(beh_actual>jl))));
        else
            % do nothing, it's already a value
        end
    end
    beh_rating_lagged = [beh_rating(2:end); beh_rating(end)];
    for jl = 1:numel(run_datamat(1,:)),
        [~,~,resid_data] = regress(run_datamat(1:end ,jl),beh_rating_lagged);
        run_datamat(:,jl) = resid_data;
    end
    regressed_data(find(run_index==run),:) = run_datamat;
end

sprintf('autocorrelation removed with regression: run-wise')
end


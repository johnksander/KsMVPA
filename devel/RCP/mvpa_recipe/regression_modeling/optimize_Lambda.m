function opt_Lambda = optimize_Lambda(Lopt_pkg,cv_params)

X_int = Lopt_pkg.X(:,1);
Lopt_pkg.X = Lopt_pkg.X(:,2:end); %take out the intercept

rsqmat = NaN(numel(unique(Lopt_pkg.cv_idcs)),numel(Lopt_pkg.lambda_range));

parfor curr_lval_itr = 1:numel(Lopt_pkg.lambda_range)
    
    Lval = Lopt_pkg.lambda_range(curr_lval_itr);
    curr_SV_rsqs = NaN(1,numel(unique(Lopt_pkg.cv_idcs)));
    
    for cross_val = 1:numel(unique(Lopt_pkg.cv_idcs))
        
        train_fold = Lopt_pkg.cv_idcs ~= cross_val;
        test_fold = ~train_fold;
        
        trainX = Lopt_pkg.X(train_fold,:);
        trainX = [X_int(train_fold) trainX]; %re-add intercept
        train_labels = Lopt_pkg.y(train_fold);
        
        testX = Lopt_pkg.X(test_fold,:);
        test_labels = Lopt_pkg.y(test_fold);
        
        m = numel(trainX(:,1));
%         hx = trainX*Lopt_pkg.theta; %07292015: dropped transpose from theta- fixed dim mismatch error
%         
%         gradient = ((hx-train_labels)' * trainX / m)' + Lval .* Lopt_pkg.theta .* ...
%             [0; ones(length(Lopt_pkg.theta)-1,1)] ./ m;
%         Replace this section with "normal equation" & least mean squares 
        predicted_labels = testX* gradient(2:end); %ignore first b/c it's the intercept beta, right?
        predicted_labels = predicted_labels + gradient(1); % re-add intercept
        
        TSS = sumsqr(test_labels - mean(test_labels));
        RSS = sumsqr(test_labels - predicted_labels);
        r_sq = (TSS-RSS)/TSS;
        curr_SV_rsqs(cross_val) = r_sq;
    end
    
    rsqmat(:,curr_lval_itr) = curr_SV_rsqs';
end

opt_Lambda = mean(rsqmat,1)';
opt_Lambda = find(opt_Lambda == max(opt_Lambda));

if numel(opt_Lambda) > 1
    opt_Lambda = opt_Lambda(1);
end

opt_Lambda = Lopt_pkg.lambda_range(opt_Lambda);
%disp('Lambda optimized')
end


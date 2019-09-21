function tvals = betaTvals(options,voxel_data,Xt,Betas)

DFe = numel(Xt(:,1)) - numel(Xt(1,:));
switch options.LSSintercept
    case 'on'
        DFe = DFe + 1; %if you have an intercept!!
end
yhat = Xt * Betas;
SSE = sum((voxel_data - yhat) .^2);
MSE = SSE / DFe;
varB = MSE' * diag((Xt' * Xt)^-1)';
stdErr = sqrt(varB)';
tvals = Betas ./ stdErr;




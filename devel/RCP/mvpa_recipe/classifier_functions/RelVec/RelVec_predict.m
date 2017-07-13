function label_predictions = RelVec_predict(cv_params,options,PARAMETER)

%11/8/2015: don't use training data w/ linear basis kernel: ionly need for guassian b/c it's "data parameterized"

w_infer = zeros(numel(cv_params.fe_testing_data(1,:)),1);
w_infer(PARAMETER.Relevant)	= PARAMETER.Value;


switch options.RVint
    case 'off'
        label_predictions = cv_params.fe_testing_data*w_infer;
    case 'on'
        label_predictions = cv_params.fe_testing_data*w_infer + PARAMETER.bias;
end


switch options.RVcsum_pred %cumulative subject prediction 
    case 'on'
        label_predictions = SB2_Sigmoid(label_predictions);
        cpred = double(mean(label_predictions) > 0.5);
        label_predictions = repmat(cpred,numel(label_predictions),1);
    case 'off'
        label_predictions = double(SB2_Sigmoid(label_predictions)>0.5);
end
%for gaussian prior:
%label_predictions = double(label_predictions > 0.5);



% %-------------------------------
% % code for guassian basis RVM
% PHI = RelVec_compute_basis(cv_params.fe_testing_data,cv_params.fe_training_data(PARAMETER.Relevant,:));
% y_rvm	= PHI*PARAMETER.Value; %+ bias;
% label_predictions =  double(SB2_Sigmoid(y_rvm)>0.5);
% %-------------------------------








%
% [weights, used, bias, marginal, alpha, beta, gamma] = ...
%     SB1_RVM(X,t,initAlpha,initBeta,kernel_,width,useBias,maxIts,monIts);
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% %
% % Load Ripley's test set
% %
% load synth.te
% synth	= synth(randperm(size(synth,1)),:);
% Xtest	= synth(1:Nt,1:2);
% ttest	= synth(1:Nt,3);
% %
% % Compute RVM over test data and calculate error
% %
% PHI	= SB1_KernelFunction(Xtest,X(used,:),kernel_,width);
% y_rvm	= PHI*weights + bias;
% errs	= sum(y_rvm(ttest==0)>0) + sum(y_rvm(ttest==1)<=0);
% SB1_Diagnostic(1,'RVM CLASSIFICATION test error: %.2f%%\n', errs/Nt*100)
%
% %
% % Set up initial hyperparameters - precise settings should not be critical
% %
% initAlpha	= (1/N)^2;
% % Set beta to zero for classification
% initBeta	= 0;
% %
% % "Train" a sparse Bayes kernel-based model (relevance vector machine)
% %
% [weights, used, bias, marginal, alpha, beta, gamma] = ...
%     SB1_RVM(X,t,initAlpha,initBeta,kernel_,width,useBias,maxIts,monIts);

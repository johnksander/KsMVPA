function [PARAMETER, HYPERPARAMETER, DIAGNOSTIC] = RelVec_train_model(cv_params,options)
%SETTINGS	= SB2_ParameterSettings;
%OPTIONS	= SB2_UserOptions;
RV_settings = options.RV_settings;
RV_options = options.RV_options;
N = numel(cv_params.fe_training_data(1,:));



basis = cv_params.fe_training_data;
switch options.RVint
    case 'on'
        basis = [basis ones(numel(cv_params.training_labels),1)]; %add bias term (intercept)
end

[PARAMETER, HYPERPARAMETER, DIAGNOSTIC] = ...
    SparseBayes('Bernoulli', basis, cv_params.training_labels, RV_options, RV_settings);
%Gaussian
%Bernoulli

switch options.RVint
    case 'on'
        PARAMETER.bias = 0;
        indexBias	= find(PARAMETER.Relevant==N+1);
        if ~isempty(indexBias)
            PARAMETER.bias = PARAMETER.Value(indexBias);
            PARAMETER.Relevant(indexBias)	= [];
            PARAMETER.Value(indexBias)	= [];
        end
        
        
        
        if isempty(PARAMETER.Relevant) & isempty(PARAMETER.Value)
            %in case bias term soaks up all relevance
            basis = cv_params.fe_training_data;
            basis = basis - PARAMETER.bias;
            B = PARAMETER.bias;
            [PARAMETER, HYPERPARAMETER, DIAGNOSTIC] = ...
                SparseBayes('Bernoulli', basis, cv_params.training_labels, RV_options, RV_settings);
            PARAMETER.bias = B;
        end
end
%currently:
% a) intercept
% b) model reesitmated if bias is only relevance vector


end
%
%
% %SETTINGS	= SB2_ParameterSettings;
% %OPTIONS	= SB2_UserOptions;
% RV_settings = options.RV_settings;
% RV_options = options.RV_options;
% N = numel(cv_params.training_data(1,:));
%
% %basis = RelVec_compute_basis(cv_params.fe_training_data,cv_params.fe_training_data);
%
%
% basis = cv_params.fe_training_data;
% basis = [basis ones(numel(cv_params.training_labels),1)]; %add bias term (intercept)
%
% [PARAMETER, HYPERPARAMETER, DIAGNOSTIC] = ...
%     SparseBayes('Bernoulli', basis, cv_params.training_labels, RV_options, RV_settings);
%
%
% PARAMETER.bias = 0;
% indexBias	= find(PARAMETER.Relevant==N+1);
% if ~isempty(indexBias)
%     PARAMETER.bias = PARAMETER.Value(indexBias);
%     PARAMETER.Relevant(indexBias)	= [];
%     PARAMETER.Value(indexBias)	= [];
% end
%
%
%
% if isempty(PARAMETER.Relevant) & isempty(PARAMETER.Value)
%     %in case bias term soaks up all relevance
%     basis = cv_params.fe_training_data;
%     basis = basis - PARAMETER.bias;
%     B = PARAMETER.bias;
%     [PARAMETER, HYPERPARAMETER, DIAGNOSTIC] = ...
%         SparseBayes('Bernoulli', basis, cv_params.training_labels, RV_options, RV_settings);
%     PARAMETER.bias = B;
% end
%
% %currently:
% % a) intercept
% % b) model reesitmated if bias is only relevance vector
%

%-------------------------------
% code for guassian basis RVM
% RV_settings = options.RV_settings;
% RV_options = options.RV_options;
% N = numel(cv_params.training_data(1,:));

% basis = RelVec_compute_basis(cv_params.fe_training_data,cv_params.fe_training_data);
% RV_options.iterations = 10;
% [PARAMETER, HYPERPARAMETER, DIAGNOSTIC] = ...
%     SparseBayes('Bernoulli', basis, cv_params.training_labels, RV_options, RV_settings);
%
%-------------------------------



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

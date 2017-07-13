function Xt = LSS_run_design_matrix(trial_onsets,TOI,options)
%make design matrix for LSS
%step 1, create impulse functions for TOI trials & alternate trial types 
%step 2, convolve impulse functions with hrf for design matrix 

hrf = spm_hrf(2); % 2 is TR time(s)

%make regressor impulse functions
num_reg = numel(unique(trial_onsets(~isnan(trial_onsets))));
other_trial_types = unique(trial_onsets(~isnan(trial_onsets)));
other_trial_types(other_trial_types == TOI) = [];

% 07/10/2016
%TOI, trials of a different type, so on. 
%The default is to load all trials, then add rememebered or whatever (all others would be forgotten)
%If options.trialtypes is an empty cell, you'll just have one regressor (all trials).

Xt = zeros(numel(trial_onsets),num_reg);
Xt(trial_onsets == TOI,1) = 1; %TOI onset first col 

for idx = 1:numel(other_trial_types) %loop will not run if options.trialtypes is an empty cell
    regressor_col = idx + 1; %already did the first one 
    Xt(trial_onsets == other_trial_types(idx),regressor_col) = 1;
end


%convolve impulse functions with hrf 
for conv_idx = 1:num_reg
    
    reg = Xt(:,conv_idx);
    reg = conv(reg,hrf,'full');
    reg = reg(1:numel(trial_onsets)); %cut added function
    Xt(:,conv_idx) = reg;
    
end








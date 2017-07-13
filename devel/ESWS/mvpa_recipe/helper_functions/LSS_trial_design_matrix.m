function Xt = LSS_trial_design_matrix(options,trial_onsets,trial_inds,trialidx)
%make design matrix for LSS
%step 1, create impulse functions for TOI, trials other than TOI of same type, alternate trial types 
%step 2, convolve impulse functions with hrf for design matrix 

hrf = spm_hrf(2); % 2 is TR time(s)

%make regressor impulse functions
num_reg = numel(options.trialtypes) + 2;
TOI_type = trial_onsets(trial_inds(trialidx));
other_trial_types = unique(trial_onsets(~isnan(trial_onsets)));
other_trial_types(other_trial_types == TOI_type) = [];

% 06/08/2016
%TOI, then all trials of same type , trials of a different type, then all others.
%The default is to load all trials, then add rememebered or whatever (all others would be forgotten)
%so, plus one for non-TOI type trials, plus two for all others. If options.trialtypes is an empty 
%cell, you'll just have two regressors. One for the trial, another for all other trials 

Xt = zeros(numel(trial_onsets),num_reg);
Xt(trial_inds(trialidx),1) = 1; %TOI onset first col 
Xt(trial_onsets == TOI_type & ~Xt(:,1),2) = 1; %everything but TOI & is the same type as TOI


for idx = 1:numel(other_trial_types) %loop will not run if options.trialtypes is an empty cell
    
    regressor_col = idx + 2; %already did the first two 
    Xt(trial_onsets == other_trial_types(idx),regressor_col) = 1;
    
end


%convolve impulse functions with hrf 
for conv_idx = 1:num_reg
    
    reg = Xt(:,conv_idx);
    reg = conv(reg,hrf,'full');
    reg = reg(1:numel(trial_onsets)); %cut added function
    Xt(:,conv_idx) = reg;
    
end








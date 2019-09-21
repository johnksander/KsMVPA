function perm_labels = enc2ret_permuting(labels,run_index,options)
%permute trial labelings within encoding runs, and within retreival runs
%this should be done seperately for fairness (and like.. class counts etc)

enc_trials = ismember(run_index,options.enc_runs);
enc_labels = labels(enc_trials);

ret_trials = ismember(run_index,options.ret_runs);
ret_labels = labels(ret_trials);

perm_labels = NaN(numel(labels),options.num_perms);
for idx = 1:options.num_perms
    %encoding labels 
    perm_labels(enc_trials,idx) = enc_labels(randperm(numel(enc_labels))); %set permutation order
    %retrieval labels 
    perm_labels(ret_trials,idx) = ret_labels(randperm(numel(ret_labels))); %set permutation order
end
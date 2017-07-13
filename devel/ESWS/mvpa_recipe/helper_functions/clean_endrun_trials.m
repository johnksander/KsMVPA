function data = clean_endrun_trials(data,trials2cut,idx)
%remove trials without proper fmri data (options.remove_endrun_trials)
%inputs are: sujbect data, trials2cut matrix, subject index 

if ~isempty(trials2cut) %start cutting
    trials2cut = trials2cut(:,idx);
    data = data(~trials2cut,:);
end


function label_matrix = oldMC_label_matrix(labels)
%For "old MC" scheme: binary decision models for
%each partitioning of "one label vs the rest". 
%Input--- column label vector, or matrix of column vecors (i.e. perm testing).
%Output--- trials x N classes (x N label vectors) label matrix for the 
%binary decisions. 

%The output's N classes dim is orgnaized by sorted label values,
%this is needed to match expected format in classifier function (i.e. label
%"1" is first, label "2" is second, etc)


num_label_vecs = numel(labels(1,:)); %should really only be > 1 for perm testing
num_obs = numel(labels(:,1));
classes = unique(labels);
classes = sort(classes); %ensure these are sorted
n_class = numel(classes);

rest_label = 9999; %label for "the rest" in this scheme, reserved
if sum(classes == rest_label) > 0,error('label 9999 is reserved in old MC');end

label_matrix = NaN(num_obs,n_class,num_label_vecs);


for idx = 1:n_class
    target_class = classes(idx); %pick a class
    target_obs = ismember(labels,target_class); %corresponding trials
    
    target_labels = NaN(size(labels)); %new label vector
    target_labels(target_obs) = target_class;
    target_labels(~target_obs) = rest_label; %1 vs rest
    %train old MC model, LDA struct keeps the label names 
    label_matrix(:,idx,:) = target_labels;
end
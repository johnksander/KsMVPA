function label_matrix = oldMC_label_matrix(labels)
%For "old MC" scheme: binary decision models for
%each pairwise combination of labels (note: can't do 1 v rest because 
%LDA needs better class balancing, setting uniform priors doesn't cut it).

%Input--- column label vector, or matrix of column vecors (i.e. perm testing).
%Output--- trials x N pairs (x N label vectors) label matrix for the 
%binary decisions. Output will include NaN for trials not included in a
%given binary pair: this is fine for comparing to a prediction matrix
%because you can just subtract the number of nans from that calculation

%Note: no balance check needed here because this func is for testing labels


classes = sort(unique(labels));
class_pairs = nchoosek(classes,2);
n_pairs = numel(class_pairs(:,1));
num_label_vecs = numel(labels(1,:)); %should really only be > 1 for perm testing
num_obs = numel(labels(:,1));

label_matrix = NaN(num_obs,n_pairs,num_label_vecs);

for idx = 1:n_pairs
    target_pair = class_pairs(idx,:); %pick a binary pair 
    target_obs = ismember(labels,target_pair); %corresponding trials
    
    target_labels = NaN(size(labels)); %new label vector
    target_labels(target_obs) = labels(target_obs); %put the pair labels back in 
    %train old MC model, LDA struct keeps the label names 
    label_matrix(:,idx,:) = target_labels;
end



%depreciated: need to balance the class set better for LDA, just setting 
%uniform priors doesn't do it 
% 
% num_label_vecs = numel(labels(1,:)); %should really only be > 1 for perm testing
% num_obs = numel(labels(:,1));
% classes = unique(labels);
% classes = sort(classes); %ensure these are sorted
% n_class = numel(classes);
% 
% rest_label = 9999; %label for "the rest" in this scheme, reserved
% if sum(classes == rest_label) > 0,error('label 9999 is reserved in old MC');end
% 
% label_matrix = NaN(num_obs,n_class,num_label_vecs);
% 
% 
% for idx = 1:n_class
%     target_class = classes(idx); %pick a class
%     target_obs = ismember(labels,target_class); %corresponding trials
%     
%     target_labels = NaN(size(labels)); %new label vector
%     target_labels(target_obs) = target_class;
%     target_labels(~target_obs) = rest_label; %1 vs rest
%     %train old MC model, LDA struct keeps the label names 
%     label_matrix(:,idx,:) = target_labels;
% end
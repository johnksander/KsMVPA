function RDM = RSA_constructRDM(brain_data,options)


switch options.RDM_dist_metric
    case 'spearman'
        RDM = pdist2(brain_data,brain_data,'spearman'); %this gives "dissimilarity" 1 - spearman
        %RDM = corr(brain_data','type','Spearman','rows','pairwise'); %this gives regular spearman (similarity matrix)
    case 'kendall'
        RDM = pdist2(brain_data,brain_data,'spearman'); %this gives "dissimilarity" 1 - spearman
        %the brain data really isn't ever going to have ties, it's the model(s) that'll have that issue
        %just have options.options.RDM_dist_metric = 'kendall' do spearman here to avoid creating another 
        %options field to specify that brain RDMs get computed with spearman, but the models compared with kendall etc.. 
    case 'euclid'
        RDM = pdist2(brain_data,brain_data,'euclidean');

end



%RDM = corr(brain_data','type','Spearman','rows','pairwise'); %this gives regular spearman
%RDM = 1 - RDM;

%empties = cellfun(@isempty,brain_data); %replace exclusions with nan data
%brain_data(empties) = {NaN(1,size(brain_data{1},2))};
% brain_data = cell2mat(brain_data);
% RDM = corr(brain_data','type','Spearman');
% empties = ~isnan(RDM(:,1)); %clean up excluded subjects
% RDM = RDM(rem,:);
% rem = ~isnan(RDM(1,:));
% RDM = RDM(:,rem);

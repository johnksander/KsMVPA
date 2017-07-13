function matched_inds = GNBmatch_subinds2data(subject_inds,subject_brain_data)
%take subject inds, make inds match the number of scans per subject. 
%Specalized for {timepoint x vox x searchlight} GNB searchlight data.
%Exclusions must be omitted from both inputs  


matched_inds = num2cell(subject_inds);
matched_inds = cellfun(@(x,y) repmat(x,numel(y(:,1,1)),1),matched_inds,subject_brain_data,'UniformOutput', false);
matched_inds = cell2mat(matched_inds);
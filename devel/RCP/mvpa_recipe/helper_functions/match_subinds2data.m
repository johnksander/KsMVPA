function matched_inds = match_subinds2data(subject_inds,subject_brain_data)
%take subject inds with exclusions omitted, make inds match 
%the number of scans per subject 

emptycells = cellfun(@isempty,subject_brain_data);
subject_brain_data = subject_brain_data(~emptycells); %remove excluded subjects from cell array
matched_inds = num2cell(subject_inds);
matched_inds = cellfun(@(x,y) repmat(x,numel(y(:,1)),1),matched_inds,subject_brain_data,'UniformOutput', false);
matched_inds = cell2mat(matched_inds);
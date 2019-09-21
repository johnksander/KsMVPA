function updatedPDFP = PreprocDataFP_handler(options,currPDFP,mode)

%A: save functionality
%1. load preproc data filepointers, if present. Make a new one, if not.
%2. resolve if preproc data is updating a PDFP roi slot, or adding a new slot
%3. output reconciled preproc data filepointer

%B: load functionality
%1. %check mask FNs against preproc data FP paths
%2. %only take specified rois



PDFP_fn = fullfile(options.preproc_data_dir,'preproc_data_file_pointers.mat');


switch mode
    case 'save'
        
        if exist(PDFP_fn,'file') == 2 %update preproc data filepointers
            preproc_data_file_pointers = load(PDFP_fn);
            preproc_data_file_pointers = preproc_data_file_pointers.preproc_data_file_pointers;
            %safegaurd against preproc excluisions
            first_valid_sub = cellfun(@isempty,preproc_data_file_pointers);
            first_valid_sub = ~first_valid_sub(:,1);
            first_valid_sub = find(first_valid_sub,1,'first');
            %get existing roi names
            existing_rois = preproc_data_file_pointers(first_valid_sub,:)'; %pulling first valid subject
            existing_rois = regexp(existing_rois, [options.preproc_data_dir '/'], 'split');
            existing_rois = vertcat(existing_rois{:});
            existing_rois = existing_rois(:,2);
            existing_rois = regexp(existing_rois,['_' num2str(options.subjects(first_valid_sub)) '.mat'], 'split'); %remove first valid subject's number ID
            existing_rois = vertcat(existing_rois{:});
            existing_rois = existing_rois(:,1);
            %get current ROI names
            curr_rois = currPDFP(first_valid_sub,:)'; %pulling first valid subject
            curr_rois = regexp(curr_rois, [options.preproc_data_dir '/'], 'split');
            curr_rois = vertcat(curr_rois{:});
            curr_rois = curr_rois(:,2);
            curr_rois = regexp(curr_rois,['_' num2str(options.subjects(first_valid_sub)) '.mat'], 'split'); %remove first valid subject's number ID
            curr_rois = vertcat(curr_rois{:});
            curr_rois = curr_rois(:,1);
            %check if preproc data is new & needs to be added, or if it's updating an existing roi
            rois2add = ~ismember(curr_rois,existing_rois)';
            %if there's new rois, add them to preproc data filepointers
            if sum(rois2add) > 0
                updatedPDFP = [preproc_data_file_pointers currPDFP(:,rois2add)];
            elseif sum(rois2add) == 0
                updatedPDFP = preproc_data_file_pointers; %no rois to add, only updating existing files 
            end
            
        else %preproc data filepointers doesn't exist already, make a new one
            updatedPDFP = currPDFP;
            
        end
        
    case 'load'

        preproc_data_file_pointers = load(PDFP_fn);
        preproc_data_file_pointers = preproc_data_file_pointers.preproc_data_file_pointers;
        %safegaurd against preproc excluisions
        first_valid_sub = cellfun(@isempty,preproc_data_file_pointers);
        first_valid_sub = ~first_valid_sub(:,1);
        first_valid_sub = find(first_valid_sub,1,'first');
        %get existing roi names
        existing_rois = preproc_data_file_pointers(first_valid_sub,:)'; %pulling first valid subject
        existing_rois = regexp(existing_rois, [options.preproc_data_dir '/'], 'split');
        existing_rois = vertcat(existing_rois{:});
        existing_rois = existing_rois(:,2);
        existing_rois = regexp(existing_rois,['_' num2str(options.subjects(first_valid_sub)) '.mat'], 'split'); %remove first valid subject's number ID
        existing_rois = vertcat(existing_rois{:});
        existing_rois = existing_rois(:,1);
        %get specified roi names
        specified_rois = regexp(options.roi_list, '.nii', 'split'); %make labels for saved preproc data based on real mask FN
        specified_rois = vertcat(specified_rois{:});
        specified_rois = specified_rois(:,1);
        %only take specified rois & reorder PDFP to match specification
        rois2take = NaN(1,numel(specified_rois));
        for checkidx = 1:numel(specified_rois)
            rois2take(checkidx) = find(strcmp(specified_rois{checkidx},existing_rois));
        end
        updatedPDFP = preproc_data_file_pointers(:,rois2take);
end
















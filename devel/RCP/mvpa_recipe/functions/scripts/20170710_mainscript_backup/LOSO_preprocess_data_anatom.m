function preproc_data_file_pointers = LOSO_preprocess_data_anatom(options)


%run_index = make_runindex(options.scans_per_run); %make run index
preproc_data_file_pointers = cell(numel(options.subjects),numel(options.roi_list));
fprintf(':::Preprocessing LOSO anatomical data:::\r')


ROI_commonvoxels = cell((numel(options.subjects)-numel(options.exclusions)),numel(options.roi_list)); %preallocate cell array for all subjs roi data

for idx = 1:numel(options.subjects),
    if ismember(options.subjects(idx),options.exclusions) == 0
        disp(sprintf('Now starting masking with subject %g',options.subjects(idx)))
        
        subj_dir = fullfile(options.SPManatom_dir,sprintf('%02i',options.subjects(idx)));
        
      
        %Load in scans
        my_files = dir(fullfile(subj_dir,options.scan_ft)); %get filenames
        my_files = {fullfile(subj_dir,my_files.name)};
        file_data = load_fmridata(my_files,options); %load data
        
        
        %Load in Masks
        mask_data = cell(numel(options.roi_list),1);
        for maskidx = 1:numel(options.roi_list),
            my_files = {fullfile(options.mask_dir,options.roi_list{maskidx})};
            mask_data{maskidx} = logical(load_fmridata(my_files,options));
        end
        mask_data = cat(4,mask_data{:});
        
        
        for roi_idx = 1:numel(options.roi_list)
            curr_mask = mask_data(:,:,:,roi_idx); %mask data
            data_matrix = apply_mask2data(curr_mask,file_data); %mask data
            ROI_commonvoxels{idx,roi_idx} = data_matrix;
        end
        
    end
end


for roi_idx = 1:numel(options.roi_list)
    ROI_commonvoxels(:,roi_idx) = remove_badvoxels4cells(ROI_commonvoxels(:,roi_idx)); %remove nan & 0 voxels across ROI
end



for idx = 1:numel(options.subjects)
    if ismember(options.subjects(idx),options.exclusions) == 0
        
        for roi_idx = 1:numel(options.roi_list)
            
            data_matrix = cell2mat(ROI_commonvoxels(idx,roi_idx));
            data_matrix = zscore(data_matrix); %only zscore for anatoms
            
            
            %data_matrix = normalize_data(data_matrix,run_index); %detrend & zscore data runwise
            %NOTE: cpm_T0 script I was working from had regress whitening error w/ pulling data from cells
            %data_matrix = regress_whiten(data_matrix,MCQDmatrix,run_index,options); %whiten w/ regression
            %NOTE2: ROIS w/ regression whitening appear to have
            %been regressed w/ different behavioral files & overwritten w/o differentiation
            %NOTE3: use ratings for ALL valence (i.e. every trial) for regression whitening
            
            %my_eps = .5;
            %zca_whitened = zca_whiten(data_matrix,eps,run_index); %ZCA whitening
            
            
            preproc_data_file_pointers{idx,roi_idx} = fullfile(options.preproc_data_dir,sprintf('%s_%i.mat',options.rois4fig{roi_idx},options.subjects(idx)));
            save(preproc_data_file_pointers{idx,roi_idx},'data_matrix'); %save ROI so we don't have to preprocess next time 'round
            sprintf('subject #%i ROI #%i/%i saved',idx,roi_idx,numel(options.roi_list))
            %01162016: you might have to change data_matrix topreprocessed_scans for the new toolbox
        end
    end
end

save(fullfile(options.preproc_data_dir,'preproc_data_file_pointers'),'preproc_data_file_pointers');
save(fullfile(options.preproc_data_dir,'options'),'options');


function preproc_data_file_pointers = preprocess_ROI_from_SL(options)
%preprocess an ROI from already preprocessed searchlight data

preproc_data_file_pointers = cell(numel(options.subjects),numel(options.roi_list));
roiFNlabels = regexp(options.roi_list, '.nii', 'split'); %make labels for saved preproc data based on real mask FN
roiFNlabels = vertcat(roiFNlabels{:});
roiFNlabels = roiFNlabels(:,1);
fprintf(':::Preprocessing ROI data from already preprocessed searchlight data:::\r')

subject_fmri_filepointers = load(fullfile(options.preproc_data_dir,'preproc_data_file_pointers'));
subject_fmri_filepointers = subject_fmri_filepointers.preproc_data_file_pointers;

%overwrite this options field because subfunctions here need this info... not awesome but w/e
options.preproc_data_dir = strrep(options.preproc_data_dir,'searchlight','ROI'); 
mkdir(options.preproc_data_dir)

ROI_data = cell((numel(options.subjects)-numel(options.exclusions)),numel(options.roi_list)); %preallocate cell array for all subjs roi data

%Load in Masks
mask_data = cell(numel(options.roi_list),1);
for maskidx = 1:numel(options.roi_list),
    my_files = {fullfile(options.mask_dir,options.roi_list{maskidx})};
    mask_data{maskidx} = logical(load_fmridata(my_files,options));
end
mask_data = cat(4,mask_data{:});

%load subject scan data
for idx = 1:numel(options.subjects),
    if ismember(options.subjects(idx),options.exclusions) == 0
        disp(sprintf('Now starting masking with subject %g',options.subjects(idx)))
        
        
        
        searchlight_brain_data = load(subject_fmri_filepointers{idx}); %load preprocessed fmri data (valid voxels already determined)
        searchlight_brain_data = searchlight_brain_data.preprocessed_scans;
        
%         subj_dir = fullfile(options.SPMdata_dir,[options.SPMsubj_dir sprintf('%02i',options.subjects(idx))]);
%         file_data = cell(numel(options.runfolders),1); %preall cell array for load_fmridata
%         
%         %Load in scans
%         for runidx = 1:numel(options.runfolders)
%             my_files = prepare_fp(options,subj_dir,options.runfolders{runidx},options.scan_ft); %get filenames
%             file_data{runidx} = load_fmridata(my_files,options); %load data
%         end
%         file_data = cat(4,file_data{:}); % cat data into matrix
        
        for roi_idx = 1:numel(options.roi_list)
            curr_mask = mask_data(:,:,:,roi_idx); %get mask data
            ROI_data{idx,roi_idx} = apply_mask2data(curr_mask,searchlight_brain_data); %mask fmri data
        end
    end
end


% for roi_idx = 1:numel(options.roi_list)
%     ROI_data(:,roi_idx) = remove_badvoxels4cells(ROI_data(:,roi_idx)); %remove nan & 0 voxels across ROI
% end


for idx = 1:numel(options.subjects)
    if ismember(options.subjects(idx),options.exclusions) == 0
        %run_index = make_runindex(options,idx); %run index is weird with estimated HDR, only one scan per trial
        
        for roi_idx = 1:numel(options.roi_list)
            
            data_matrix = cell2mat(ROI_data(idx,roi_idx));
            %data_matrix = normalize_data(data_matrix,run_index); %detrend & zscore data runwise
            %fprintf('SKIPPED: runwise zscore & detrend\r')
            
            %NOTE: cpm_T0 script I was working from had regress whitening error w/ pulling data from cells
            %data_matrix = regress_whiten(data_matrix,MCQDmatrix,run_index,options); %whiten w/ regression
            %NOTE2: ROIS w/ regression whitening appear to have
            %been regressed w/ different behavioral files & overwritten w/o differentiation
            %NOTE3: use ratings for ALL valence (i.e. every trial) for regression whitening
            
            %my_eps = .5;
            %zca_whitened = zca_whiten(data_matrix,eps,run_index); %ZCA whitening
            
            preproc_data_file_pointers{idx,roi_idx} = ...
                fullfile(options.preproc_data_dir,sprintf('%s_%i.mat',roiFNlabels{roi_idx},options.subjects(idx)));
            save(preproc_data_file_pointers{idx,roi_idx},'data_matrix'); %save ROI so we don't have to preprocess next time 'round
            sprintf('subject #%i ROI #%i/%i saved',idx,roi_idx,numel(options.roi_list))
            
        end
    end
end

preproc_data_file_pointers = PreprocDataFP_handler(options,preproc_data_file_pointers,'save'); %reconcile filepointers
save(fullfile(options.preproc_data_dir,'preproc_data_file_pointers'),'preproc_data_file_pointers');


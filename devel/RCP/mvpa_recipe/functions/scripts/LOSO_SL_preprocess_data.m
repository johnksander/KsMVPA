function preproc_data_file_pointers = LOSO_SL_preprocess_data(options)

roiFNlabels = regexp(options.roi_list, '.nii', 'split'); %make labels for saved preproc data based on real mask FN
roiFNlabels = vertcat(roiFNlabels{:});
roiFNlabels = roiFNlabels(:,1);

%run_index = make_runindex(options); %make run index
preproc_data_file_pointers = cell(numel(options.subjects),numel(options.roi_list));
fprintf(':::Preprocessing LOSO data:::\r')

%Load in Masks
mask_data = cell(numel(options.roi_list),1);
for maskidx = 1:numel(options.roi_list)
    my_files = {fullfile(options.mask_dir,options.roi_list{maskidx})};
    mask_data{maskidx} = logical(load_fmridata(my_files,options));
end

commonvox_maskdata = cat(4,mask_data{:});

for idx = 1:numel(options.subjects),
    if ismember(options.subjects(idx),options.exclusions) == 0
        disp(sprintf('\nLoading subject %g fMRI data',options.subjects(idx)))
        
        subj_dir = fullfile(options.SPMdata_dir,[options.SPMsubj_dir num2str(options.subjects(idx))]);
        file_data = cell(numel(options.runfolders),1); %preall cell array for load_fmridata
        
        %Load in scans
        for runidx = 1:numel(options.runfolders)
            my_files = prepare_fp(options,subj_dir,options.runfolders{runidx},options.scan_ft); %get filenames
            file_data{runidx} = load_fmridata(my_files,options); %load data
        end
        file_data = cat(4,file_data{:}); % cat data into matrix
        
        for roi_idx = 1:numel(options.roi_list)
            %punch out bad subject voxels from commonvoxel mask
            commonvox_maskdata(:,:,:,roi_idx) = update_commonvox_mask_LOSO_SL(commonvox_maskdata,roi_idx,file_data,options);
        end
        
    end
end

disp(sprintf('\nSaving common voxel masks \n'))

for roi_idx = 1:numel(options.roi_list) %make new commonvox mask files
    dummy_scan = load_nii(fullfile(options.mask_dir,options.roi_list{maskidx}));
    dummy_scan.img = commonvox_maskdata(:,:,:,roi_idx);
    maskfile_sv = fullfile(options.preproc_data_dir,['commonvox_' options.roi_list{roi_idx}]);
    save_nii(dummy_scan,maskfile_sv)
end


for idx = 1:numel(options.subjects)
    if ismember(options.subjects(idx),options.exclusions) == 0
        
        %run_index = make_runindex(options,idx);%run index is weird with estimated HDR, only one scan per trial
        disp(sprintf('\nPreprocessing and saving subject %g fMRI data',options.subjects(idx)))
        
        %reload in scans, storing them from previous loop caused memory error
        subj_dir = fullfile(options.SPMdata_dir,[options.SPMsubj_dir num2str(options.subjects(idx))]);
        file_data = cell(numel(options.runfolders),1); %preall cell array for load_fmridata
        for runidx = 1:numel(options.runfolders)
            my_files = prepare_fp(options,subj_dir,options.runfolders{runidx},options.scan_ft); %get filenames
            file_data{runidx} = load_fmridata(my_files,options); %load data
        end
        file_data = cat(4,file_data{:}); % cat data into matrix
        
        
        for roi_idx = 1:numel(options.roi_list)
            
            preprocessed_scans = NaN(size(file_data));
            curr_mask = commonvox_maskdata(:,:,:,roi_idx); %get mask
            data_matrix = apply_mask2data(curr_mask,file_data); %mask data
            %data_matrix = normalize_data(data_matrix,run_index); %detrend & zscore data runwise
            fprintf('SKIPPED: runwise zscore & detrend\r')
            
            for scanidx = 1:size(preprocessed_scans,4)
                curr_scan = preprocessed_scans(:,:,:,scanidx);
                curr_scan(curr_mask) = data_matrix(scanidx,:);
                preprocessed_scans(:,:,:,scanidx) = curr_scan;
            end
            
            preproc_data_file_pointers{idx,roi_idx} =...
                fullfile(options.preproc_data_dir,sprintf('%s_%i.mat',roiFNlabels{roi_idx},options.subjects(idx)));
            save(preproc_data_file_pointers{idx,roi_idx},'preprocessed_scans','-v7.3'); %save ROI so we don't have to preprocess next time 'round
            sprintf('subject #%i ROI %i/%i saved',idx,roi_idx,numel(options.roi_list))
            
        end
    end
end

preproc_data_file_pointers = PreprocDataFP_handler(options,preproc_data_file_pointers,'save'); %reconcile filepointers 
save(fullfile(options.preproc_data_dir,'preproc_data_file_pointers'),'preproc_data_file_pointers');

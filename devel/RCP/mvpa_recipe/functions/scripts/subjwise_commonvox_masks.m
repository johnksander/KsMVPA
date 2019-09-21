function file_pointers = subjwise_commonvox_masks(options)

file_pointers = cell(numel(options.subjects),numel(options.roi_list));
fprintf(':::Creating subject-wise commonvox masks:::\r')

output_dir = fullfile(options.preproc_data_dir,'subjwise_commonvox_masks');
if ~isdir(output_dir)
    mkdir(output_dir)
end


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

        subjwise_maskdata = NaN(size(commonvox_maskdata));
        disp(sprintf('Saving common voxel masks'))
        for roi_idx = 1:numel(options.roi_list)
            %punch out bad subject voxels from commonvoxel mask
            subjwise_maskdata(:,:,:,roi_idx) = update_commonvox_mask_LOSO_SL(commonvox_maskdata,roi_idx,file_data,options);
            dummy_scan = load_nii(fullfile(options.mask_dir,options.roi_list{maskidx}));
            dummy_scan.img = subjwise_maskdata(:,:,:,roi_idx);
            maskfile_sv = fullfile(output_dir,['commonvox_' num2str(options.subjects(idx)) '_' options.roi_list{roi_idx}]);
            save_nii(dummy_scan,maskfile_sv)
            file_pointers{idx,roi_idx} = maskfile_sv;
        end
        
    end
end


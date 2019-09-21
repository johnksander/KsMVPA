function preproc_data_file_pointers = preprocess_data(options)
%Preprocess data for MCQD; accepts a structure containg options (produced
%by set_options.m)

run_index = make_runindex(options.scans_per_run); %make run index
preproc_data_file_pointers = cell(numel(options.subjects),numel(options.roi_list));
fprintf(':::Preprocessing data:::\r')
for idx = 1:numel(options.subjects),
    fprintf('Preprocessing subject %i\r',idx)
    if ismember(options.subjects(idx),options.exclusions) == 0,
        
        run_index = getTOIrunindex(options,idx);%run index is weird with estimated HDR, only one scan per trial
        subj_dir = fullfile(options.SPMdata_dir,[options.SPMsubj_dir sprintf('%02i',options.subjects(idx))]);
           
        %load in behavioral data
        behavioral_data = cell(numel(options.behavioral_file_list),1);
        for beh_idx = 1:numel(options.behavioral_file_list),
            BehFname = [options.behavioral_file_list{beh_idx} sprintf('%02i',options.subjects(idx)) '.txt'];
            my_files = prepare_fp(options,options.TRfile_dir,BehFname);
            beh_matrix = load_behav_data(my_files,options);
            behavioral_data{beh_idx} = beh_matrix;
        end
        
        file_data = cell(numel(options.runfolders),1); %preall cell array for load_fmridata
        
        %Load in scans
        for runidx = 1:numel(options.runfolders),
            my_files = prepare_fp(options,subj_dir,options.runfolders{runidx},options.scan_ft); %get filenames
            file_data{runidx} = load_fmridata(my_files); %load data
        end
        file_data = cat(4,file_data{:}); % cat data into matrix
        
        %Load in Masks
        mask_data = cell(numel(options.roi_list),1);
        for maskidx = 1:numel(options.roi_list),
            my_files = {fullfile(options.mask_dir,options.roi_list{maskidx})};
            mask_data{maskidx} = logical(load_fmridata(my_files));
        end
        mask_data = cat(4,mask_data{:});
        
        %MCQDmatrix = behavioral_data{1}; %use ratings for ALL valence (i.e. every trial) for regression whitening
        
        for roi_idx = 1:numel(options.roi_list),
            curr_mask = mask_data(:,:,:,roi_idx); %mask data
            data_matrix = apply_mask2data(curr_mask,file_data); %mask data
            data_matrix = remove_badvoxels(data_matrix); %remove 0 & nan voxels
            data_matrix = normalize_data(data_matrix,run_index); %detrend & zscore data runwise
            %NOTE: cpm_T0 script I was working from had regress whitening error w/ pulling data from cells
            %data_matrix = regress_whiten(data_matrix,MCQDmatrix,run_index,options); %whiten w/ regression
            %NOTE2: ROIS w/ regression whitening appear to have
            %been regressed w/ different behavioral files & overwritten w/o differentiation
            
            preproc_data_file_pointers{idx,roi_idx} = fullfile(options.preproc_data_dir,sprintf('%s_%i.mat',options.roi_list{roi_idx},idx));
            save(preproc_data_file_pointers{idx,roi_idx},'data_matrix'); %save ROI so we don't have to preprocess next time 'round
            sprintf('subject #%i ROI #%i/%i saved',idx,roi_idx,numel(options.roi_list))
        end
        
    end
end

save(fullfile(options.preproc_data_dir,'preproc_data_file_pointers'),'preproc_data_file_pointers');




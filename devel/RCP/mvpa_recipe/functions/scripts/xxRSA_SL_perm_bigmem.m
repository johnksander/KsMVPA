function [voxel_null,roi_seed_inds] = xxRSA_SL_perm_bigmem(options)

%07/11/2017: This script function is retired. Probably works fine, using it
%with RSA_SL_bigmem() to create new script function. Doing this to
%ensure everything's compatible with most recently run toolbox
%configuration. 


%GOALS:::
%   0. Initialize variables
%   1. make hypothesis matrix
%   2. load behavioral data
%   3. load brain data & determine valid LOSO voxels
%   4. map searchlight indicies
%   5. create sliceable searchlight data matrix
%   6. set permutation order for searchlight course
%   7. slice searchlights & assemble RDM
%   8. Test RDM

%0. Initialize variables
voxel_null = cell(numel(options.roi_list),1);
roi_seed_inds = cell(numel(options.roi_list),1);
valid_subs = ~ismember(options.subjects,options.exclusions)';
vol_size = options.scan_vol_size; %just make var name easier
trials2cut = find_endrun_trials(options); %find behavioral trials without proper fmri data
output_log = fullfile(options.save_dir,'stats_output_log.txt');
special_progress_tracker = fullfile(options.save_dir,'stats_SPT.txt');
rng('shuffle') %just for fun

%1. hypothesis matrix
Hmat = options.subjects(valid_subs); %kick out exclusions at the beginning
Hmat(Hmat < 200) = 1;
Hmat(Hmat > 200) = 2;
Hmat = Hmat' * Hmat;
num_conds = numel(Hmat(:,1)); %for permuting conditions
Hmat(Hmat ~= 2) = 1; %low disimilarity
Hmat(Hmat == 2) = 0; %high disimilarity
%reduce to upper triangular vector
mat2vec_mask = logical(triu(ones(size(Hmat)),1));
Hmat = Hmat(mat2vec_mask);

%2. load behavioral data
subject_behavioral_data = cell(numel(options.subjects),numel(options.behavioral_file_list));
for idx = 1:numel(options.subjects)
    if ismember(options.subjects(idx),options.exclusions) == 1
        %Don't do anything
    else
        for beh_idx = 1:numel(options.behavioral_file_list),
            BehFname = [options.behavioral_file_list{beh_idx} '_' num2str(options.subjects(idx)) '.txt'];
            my_files = prepare_fp(options,options.TRfile_dir,BehFname);
            beh_matrix = load_behav_data(my_files,options);
            beh_matrix = beh_matrix(:,options.which_behavior); %select behavioral rating
            switch options.rawdata_type
                case 'SPMbm'
                    beh_matrix = make_runindex(options);
            end
            switch options.behavioral_transformation %add EA/US split here
                case 'balanced_median_split'
                    beh_matrix = balanced_median_split(beh_matrix);
                case 'best_versus_rest'
                    %not implemented?
                case 'origin_split'
                    if options.subjects(idx) < 200
                        beh_matrix(~isnan(beh_matrix)) = 1; %US
                    elseif options.subjects(idx) > 200
                        beh_matrix(~isnan(beh_matrix)) = 2; %EA
                    end
            end
            beh_matrix = clean_endrun_trials(beh_matrix,trials2cut,idx); %remove behavioral trials without proper fmri data
            subject_behavioral_data{idx,beh_idx} = beh_matrix; %subject_behavioral data NOT to be altered after this point
        end
    end
end

%3. load brain data & determine valid LOSO voxels
%Load in Masks
mask_data = cell(numel(options.roi_list),1);
for maskidx = 1:numel(options.roi_list)
    my_files = {fullfile(options.mask_dir,options.roi_list{maskidx})};
    mask_data{maskidx} = logical(load_fmridata(my_files,options));
end
commonvox_maskdata = cat(4,mask_data{:});
subject_brain_data = NaN([vol_size sum(options.trials_per_run) numel(options.subjects)]);
for idx = 1:numel(options.subjects),
    if ismember(options.subjects(idx),options.exclusions) == 0
        disp(sprintf('\nLoading subject %g fMRI data',options.subjects(idx)))
        %get data directory and preallocate file data array
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
        subject_brain_data(:,:,:,:,idx) = file_data; %5D: x,y,z,trials,subjects
    end
end

%Remove exclusions from both brain & behavior data (not preallocating extra empty searchlight matricies for exclusions)
subject_behavioral_data = subject_behavioral_data(valid_subs,:);
subject_brain_data = subject_brain_data(:,:,:,:,valid_subs);
trials2cut = trials2cut(:,valid_subs); %don't frank this up

%Begin loops
update_logfile(':::Starting searchlight RSA:::',output_log)
for roi_idx = 1:numel(options.roi_list)
    if exist(special_progress_tracker) > 0
        delete(special_progress_tracker) %fresh start for new ROI
    end
    message = sprintf('\nROI: %s\n',options.rois4fig{roi_idx});
    update_logfile(message,output_log)
    %4. map searchlight indicies
    update_logfile('Finding searchlight indicies',output_log)
    %--- Precalculate searchlight indices
    [searchlight_inds,seed_inds] = preallocate_searchlights(commonvox_maskdata(:,:,:,roi_idx),options.searchlight_radius); %grow searchlight sphere @ every included voxel
    update_logfile(['--Total valid searchlights: ' num2str(numel(seed_inds))],output_log)
    update_logfile('Searchlight indexing complete',output_log)
    %5. create sliceable searchlight data matrix
    update_logfile('Creating searchlight matrix',output_log)
    searchlight_brain_data = bigmem_searchlight_wrapper(subject_brain_data,vol_size,searchlight_inds);
    update_logfile('Searchlight matrix complete',output_log)
    
    %6. set permutation order for searchlight course
    perm_matrix = NaN(num_conds,options.num_perms);
    for pmat_idx = 1:options.num_perms
        perm_matrix(:,pmat_idx) = randperm(num_conds)'; %set permutation order
    end
    
    %7. slice searchlights & assemble RDM
    searchlight_results = NaN(numel(seed_inds),options.num_perms);%easier results-to-roi file mapping
    parfor searchlight_idx = 1:numel(seed_inds) %parfor
        
        current_searchlight = searchlight_brain_data(:,:,searchlight_idx,:);
        current_searchlight = squeeze(current_searchlight); %squeeze function has it's own line here just to make sure matlab slices subject_roi_files and doesn't broadcast it
        current_searchlight = squeeze(num2cell(current_searchlight,[1 2]));
        
        CVbeh_data = cell(size(subject_behavioral_data));
        
        for subject_idx = 1:sum(valid_subs) %all exclusions already taken care of
            CVbeh_data(subject_idx,:) = subject_behavioral_data(subject_idx,:); %pass behavioral data
            run_index = make_runindex(options); %make run index
            data_matrix = current_searchlight{subject_idx};
            data_matrix = HDRlag(options,data_matrix,run_index); %lag data, average over window (if specified)
            data_matrix = clean_endrun_trials(data_matrix,trials2cut,subject_idx);%remove trials without proper fmri data
            [data_matrix,CVbeh_data{subject_idx}] = select_trials(data_matrix,CVbeh_data{subject_idx});%select trials
            %normalization/termporal compression
            switch options.trial_temporal_compression
                case 'on'
                    [data_matrix,CVbeh_data{subject_idx}] = temporal_compression(data_matrix,CVbeh_data{subject_idx},options);
                case 'off'
                    %data_matrix = zscore(data_matrix); %normalize subject-wise
            end
            current_searchlight{subject_idx} = data_matrix;
        end
        
        current_searchlight = cell2mat(current_searchlight);
        switch options.feature_selection
            case 'pca_only'
                current_searchlight = RSA_pca(current_searchlight,options);
        end
        current_searchlight = zscore(current_searchlight); %normalize across "conditions"
        
        %8. Test RDM (can include behavior loop here)
        RDM = RSA_constructRDM(current_searchlight,options);
        perm_results = NaN(1,options.num_perms);
        for permidx = 1:options.num_perms
            permRDM = RSA_permuteRDM(RDM,perm_matrix(:,permidx));
            permRDM = permRDM(mat2vec_mask);
            %RDM = RSA_ranktransform(RDM); %still needs to be fixed for ties
            %RDM = atanh(RDM); %this isn't going to work with 1 - spearman, gives complex numbers...
            perm_results(permidx) = corr(permRDM,Hmat,'type','Spearman','tail','right');
        end
        searchlight_results(searchlight_idx,:) = perm_results;
        
        switch options.parforlog %parfor progress tracking
            case 'on'
                txtappend(special_progress_tracker,'1\n')
                SPT_fid = fopen(special_progress_tracker,'r');
                progress = fscanf(SPT_fid,'%i');
                fclose(SPT_fid);
                if mod(sum(progress),floor(numel(seed_inds) * .005)) == 0 %.5 percent
                    progress = (sum(progress) /  numel(seed_inds)) * 100;
                    message = sprintf('Permutation testing %.1f percent complete',progress);
                    update_logfile(message,output_log)
                end
        end
    end%searchlight parfor loop
    voxel_null{roi_idx} = searchlight_results;
    roi_seed_inds{roi_idx} = seed_inds;
end
update_logfile('---analysis complete---',output_log)



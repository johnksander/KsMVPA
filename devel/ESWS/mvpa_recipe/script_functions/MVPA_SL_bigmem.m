function [brain_cells,searchlight_results] = MVPA_SL_bigmem(options)


%GOALS:::
%   0. Initialize variables
%   1. load behavioral data
%   2. load brain data & determine valid LOSO voxels
%   3. map searchlight indicies
%   4. create sliceable searchlight data matrix
%   5. slice searchlights & assemble RDM
%   6. cross validate


%0. Initialize variables
brain_cells = cell(numel(options.roi_list));
valid_subs = ~ismember(options.subjects,options.exclusions)';
vol_size = options.scan_vol_size; %just make var name easier
trials2cut = find_endrun_trials(options); %find behavioral trials without proper fmri data
output_log = fullfile(options.save_dir,'output_log.txt');
special_progress_tracker = fullfile(options.save_dir,'SPT.txt');
switch options.CVscheme
    case 'TwoOut'
        subs2LO = options.subjects(valid_subs); %cross validation indicies
        subs2LO = {subs2LO(subs2LO < 200), subs2LO(subs2LO > 200)};
        subs2LO = combvec(subs2LO{1},subs2LO{2});
    case 'OneOut'
        subs2LO = options.subjects(valid_subs); %cross validation indicies
end


%1. load behavioral data
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

%2. load brain data & determine valid LOSO voxels
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
update_logfile(':::Starting searchlight MVPA:::',output_log)
for roi_idx = 1:numel(options.roi_list)
    if exist(special_progress_tracker) > 0
        delete(special_progress_tracker) %fresh start for new ROI
    end
    message = sprintf('ROI: %s\n',options.rois4fig{roi_idx});
    update_logfile(message,output_log)
    %3. map searchlight indicies
    update_logfile('Finding searchlight indicies',output_log)
    %--- Precalculate searchlight indices
    [searchlight_inds,seed_inds] = preallocate_searchlights(commonvox_maskdata(:,:,:,roi_idx),options.searchlight_radius); %grow searchlight sphere @ every included voxel
    update_logfile('Searchlight indexing complete',output_log)
    update_logfile(['--Total valid searchlights: ' num2str(numel(seed_inds))],output_log)
    %4. create sliceable searchlight data matrix
    update_logfile('Creating searchlight matrix',output_log)
    searchlight_brain_data = bigmem_searchlight_wrapper(subject_brain_data,vol_size,searchlight_inds);
    update_logfile('Searchlight matrix complete',output_log)
    %initalize output brain
    output_brain = nan(vol_size(1),vol_size(2),vol_size(3),numel(options.behavioral_file_list));
    [seed_x,seed_y,seed_z] = ind2sub(vol_size(1:3),seed_inds);
    %easier results-to-roi file mapping
    searchlight_results = NaN(numel(seed_inds),1); %only store mean accuracy for searchlight CV
    %5. slice searchlights & assemble RDM
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
        
        %set up inds for leave out CV scheme
        subject_inds = options.subjects(valid_subs)'; %kick out exclusions so dims match below
        subject_inds = match_subinds2data(subject_inds,current_searchlight); %make subject inds match the data (num scans etc)
        CVbeh_data = cell2mat(CVbeh_data); %now everything can be a matrix
        current_searchlight = cell2mat(current_searchlight); %now everything can be a matrix
        current_searchlight = zscore(current_searchlight); %!!!!normalize across "conditions"!!!!
        
        %6. cross validate (can add behavior loop here)
        cv_guesses = cell(numel(subs2LO(1,:)),1);
        for test_sub_combo = 1:numel(subs2LO(1,:))
            cv_params = struct();%initialize stucture for parfor loop
            %subject logicals
            testing_subject = subs2LO(:,test_sub_combo);
            training_subjects = ~ismember(subject_inds,testing_subject);
            testing_subject = ~training_subjects; %just to make it explicit
            %data and labels
            training_data = current_searchlight(training_subjects,:);
            testing_data = current_searchlight(testing_subject,:);
            training_labels = CVbeh_data(training_subjects);
            testing_labels = CVbeh_data(testing_subject);
            [testing_data,testing_labels] = select_trials(testing_data,testing_labels);
            [training_data,training_labels] = select_trials(training_data,training_labels);
            switch options.feature_selection
                case 'off'
                    cv_params.fe_testing_data = testing_data; %put data straight into fe_x, avoid duplicating data matricies
                    cv_params.fe_training_data = training_data;
                case 'pca_only'
                    %1a. make cv_params struct for pca_kmeans function
                    cv_params.testing_data = testing_data;
                    cv_params.training_data = training_data;
                    [cv_params.fe_training_data, cv_params.fe_testing_data] = pca_only(cv_params,options); %run through pca
                    %1b. Feature select based on training data
                    %                 [wd,M,P] = zca_whiten(training_data,options.lambda);
                    %                 trained_centroids = runkmeans(wd,curr_num_centroids,options.k_iterations);
                    %                 fe_training_data = extract_brain_features(training_data,trained_centroids,M,P);
                    %                 fe_testing_data = extract_brain_features(testing_data,trained_centroids,M,P);
                    %2a. make cv_params struct for classifier function
                    %                 cv_params.fe_training_data = fe_training_data;
                    %                 cv_params.fe_testing_data = fe_testing_data;
            end
            cv_params.training_labels = training_labels;
            cv_params.testing_labels = testing_labels;
            %2b. Insert classifier
            cv_guesses{test_sub_combo} = options.classifier_type(cv_params,options);
        end
        cv_guesses = vertcat(cv_guesses{:});
        searchlight_results(searchlight_idx) = sum(cv_guesses(:,1) == cv_guesses(:,2)) / numel(cv_guesses(:,1));
        
        switch options.parforlog %parfor progress tracking
            case 'on'
                txtappend(special_progress_tracker,'1\n')
                SPT_fid = fopen(special_progress_tracker,'r');
                progress = fscanf(SPT_fid,'%i');
                fclose(SPT_fid);
                if mod(sum(progress),floor(numel(seed_inds) * .005)) == 0 %.5 percent
                    progress = (sum(progress) /  numel(seed_inds)) * 100;
                    message = sprintf('Searchlight MVPA %.1f percent complete',progress);
                    update_logfile(message,output_log)
                end
        end
    end%searchlight parfor loop
    searchlight_results = [seed_inds,searchlight_results]; %include results' searchlight seed location (lin index)
    output_brain = results2output_brain(searchlight_results(:,2),[1:numel(seed_inds)],output_brain,seed_x,seed_y,seed_z,options);
    brain_cells{roi_idx} = output_brain;
end
update_logfile('---analysis complete---',output_log)



function [brain_cells,permutation_results] = xxRSA_searchlight_perm(options,sig_searchlights)


%GOALS:::
%   0. Initialize variables
%   1. make hypothesis matrix
%   2. load behavioral data
%   3. load brain data & determine valid LOSO voxels
%   4. map searchlight indicies
%   5. create sliceable searchlight data matrix
%   6. slice searchlights & assemble RDM
%   7. Test RDM


%0. Initialize variables
num_permutations = 100000;
brain_cells = cell(numel(options.roi_list));
valid_subs = ~ismember(options.subjects,options.exclusions)';
vol_size = options.scan_vol_size; %just make var name easier
trials2cut = find_endrun_trials(options); %find behavioral trials without proper fmri data
output_log = fullfile(options.save_dir,'permoutput_log.txt');

%1. hypothesis matrix
Hmat = options.subjects(valid_subs); %kick out exclusions at the beginning
Hmat(Hmat < 200) = 1;
Hmat(Hmat > 200) = 2;
Hmat = Hmat' * Hmat;
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

[seed_x,seed_y,seed_z] = ind2sub(vol_size,sig_searchlights);
searchlight_inds = cell(1,numel(sig_searchlights));
for idx = 1:numel(sig_searchlights)
    searchlight_inds{idx} = draw_searchlight(vol_size,seed_x(idx),seed_y(idx),seed_z(idx),options.searchlight_radius);
    searchlight_inds{idx} = find(searchlight_inds{idx});
end
searchlight_inds = cell2mat(searchlight_inds);

subject_brain_data = NaN(sum(options.trials_per_run),numel(searchlight_inds(:,1)),numel(sig_searchlights),numel(options.subjects));
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
        subject_brain_data(:,:,:,idx) = bigmem_searchlight_wrapper(file_data,vol_size,searchlight_inds);
    end
end

%Remove exclusions from both brain & behavior data (not preallocating extra empty searchlight matricies for exclusions)
subject_behavioral_data = subject_behavioral_data(valid_subs,:);
subject_brain_data = subject_brain_data(:,:,:,valid_subs);
trials2cut = trials2cut(:,valid_subs); %don't frank this up

%Begin loops
update_logfile(':::Starting searchlight RSA permutation testing:::',output_log)
for roi_idx = 1:numel(options.roi_list)
    message = sprintf('\nROI: %s\n',options.rois4fig{roi_idx});
    update_logfile(message,output_log)
    %initalize output brain
    output_brain = nan(vol_size(1),vol_size(2),vol_size(3),numel(options.behavioral_file_list));
    %easier results-to-roi file mapping
    permutation_results = NaN(numel(sig_searchlights),1);
    update_logfile('Starting RDM permutation testing',output_log)
    %6. slice searchlights & assemble RDM
    parfor searchlight_idx = 1:numel(sig_searchlights) %parfor
        rng('shuffle')
        current_searchlight = subject_brain_data(:,:,searchlight_idx,:);
        current_searchlight = squeeze(current_searchlight); %squeeze function has it's own line here just to make sure matlab slices subject_roi_files and doesn't broadcast it
        current_searchlight = squeeze(num2cell(current_searchlight,[1 2]));
        
        CVbehavioral_data = cell(size(subject_behavioral_data));
        for subject_idx = 1:sum(valid_subs) %all exclusions already taken care of
            CVbehavioral_data(subject_idx,:) = subject_behavioral_data(subject_idx,:); %pass behavioral data
            run_index = make_runindex(options); %make run index
            data_matrix = current_searchlight{subject_idx};
            data_matrix = HDRlag(options,data_matrix,run_index); %lag data, average over window (if specified)
            data_matrix = clean_endrun_trials(data_matrix,trials2cut,subject_idx);%remove trials without proper fmri data
            switch options.feature_selection
                case 'pca_only'
                    data_matrix = RSA_pca(data_matrix,options);
            end
            %normalization/termporal compression
            switch options.trial_temporal_compression
                case 'on'
                    [data_matrix,CVbehavioral_data{subject_idx}] = temporal_compression(data_matrix,CVbehavioral_data{subject_idx},options);
                case 'off'
                    %data_matrix = zscore(data_matrix); %normalize subject-wise
            end
            [data_matrix,~] = select_trials(data_matrix,CVbehavioral_data{subject_idx});%select trials
            current_searchlight{subject_idx} = data_matrix;
        end
        
        current_searchlight = cell2mat(current_searchlight);
        current_searchlight = zscore(current_searchlight); %normalize across "conditions"
        nulldist = NaN(num_permutations,1);
        for permidx = 1:num_permutations
            %6. Test RDM (can include behavior loop here)
            permuted_order = randperm(numel(current_searchlight(:,1)))';
            permuted_searchlight = current_searchlight(permuted_order,:);
            RDM = RSA_constructRDM(permuted_searchlight,options);
            RDM = RDM(mat2vec_mask);
            %RDM = RSA_ranktransform(RDM); %still needs to be fixed for ties
            RDM = atanh(RDM); %this isn't going to work with 1 - spearman, gives complex numbers...
            nulldist(permidx) = corr(RDM,Hmat,'type','Spearman','tail','right');
        end
        %find real p value
        RDM = RSA_constructRDM(current_searchlight,options);
        RDM = RDM(mat2vec_mask);
        %RDM = RSA_ranktransform(RDM); %still needs to be fixed for ties
        RDM = atanh(RDM); %this isn't going to work with 1 - spearman, gives complex numbers...
        realr = corr(RDM,Hmat,'type','Spearman','tail','right');
        pvalue = (sum(nulldist > realr) + 1) ./ (num_permutations + 1); %adjust for 0 p-values
        permutation_results(searchlight_idx) = pvalue;
    end%searchlight parfor loop
    permutation_results = [sig_searchlights,permutation_results]; %include results' searchlight seed location (lin index)
    %output_brain = results2output_brain(permuation_results(:,2),[1:numel(seed_inds)],output_brain,seed_x,seed_y,seed_z,options);
    %add this in later with multiple comparisons correction or something 
    brain_cells{roi_idx} = output_brain;
end
update_logfile('---analysis complete---',output_log)



function sphere_voxels = draw_searchlight(vs,x,y,z,searchlight_radius)

[emptyx, emptyy, emptyz] = meshgrid(1:vs(2),1:vs(1),1:vs(3));
sphere_voxels = logical((emptyx - y(1)).^2 + ...
    (emptyy - x(1)).^2 + (emptyz - z(1)).^2 ...
    <= searchlight_radius.^2); %adds a logical searchlight mask centered on the coordinates sphere_x/y/z_coord






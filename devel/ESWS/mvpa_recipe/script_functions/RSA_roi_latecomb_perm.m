function permuted_group_fits = RSA_roi_latecomb_perm(subject_file_pointers,options)

%gonna try some "late combination of evidence", average subject brain data
%RDMs and compare against grand stimli info RDM


%GOALS:::
%   0. Initialize variables
%   1. load behavioral data
%   2. load premade stimuli RDM
%   3. load brain data & assemble RDM
%   4. aggregate group brain data RDMs into RSMs and permute the ordering
%      ----note: use valid permutation order, only permute the grand matrix
%      entries which were possible.(i.e. a subject could have seen)
%   5. Test RDMs


switch options.behavioral_transformation %add EA/US split here
    case 'origin_split'
        num_groups = 2;
    otherwise
        disp('ERROR: only configured for between groups analysis')
        return
end
if numel(numel(options.roi_list)) > 1
    disp('ERROR: option for multiple ROIs depreciated in this script')
    return
elseif strcmpi(options.RDM_dist_metric,'spearman') == 0
    disp('ERROR: spearman is the only distance metric coded for here')
    disp('averaging r values needs fisher transform, which requires RSMs... this is kinda hardcoded')
    return
end

%0.    Initialize variables
rng('shuffle') %just for fun
valid_subs = ~ismember(options.subjects,options.exclusions)';
trials2cut = find_endrun_trials(options); %find behavioral trials without proper fmri data
%output_coeffs = cell(numel(options.subjects),numel(options.roi_list),numel(options.behavioral_file_list));
subject_behavioral_data = cell(numel(options.subjects),numel(options.behavioral_file_list));
subject_stim_info = cell(numel(options.subjects),1);
for idx = 1:numel(options.subjects)
    if ismember(options.subjects(idx),options.exclusions) == 0
        for beh_idx = 1:numel(options.behavioral_file_list),
            %   1. load behavioral data
            BehFname = [options.behavioral_file_list{beh_idx} '_' num2str(options.subjects(idx)) '.txt'];
            my_files = prepare_fp(options,options.TRfile_dir,BehFname);
            beh_matrix = load_behav_data(my_files,options);
            beh_matrix = beh_matrix(:,options.which_behavior); %select behavioral rating
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
                    switch options.rawdata_type
                        case 'anatom'
                            if options.subjects(idx) < 200
                                beh_matrix = 1; %US
                            elseif options.subjects(idx) > 200
                                beh_matrix = 2; %EA
                            end
                    end
            end
            beh_matrix = clean_endrun_trials(beh_matrix,trials2cut,idx); %remove behavioral trials without proper fmri data
            subject_behavioral_data{idx,beh_idx} = beh_matrix; %subject_behavioral data NOT to be altered after this point
            %   2. load premade stimuli RDMs
            stim_info_Fname = sprintf('%s_RDM_stiminfo_%i.mat',options.dataset,options.subjects(idx));
            stim_info_Fname = fullfile(options.TRfile_dir,stim_info_Fname);
            stim_info = load(stim_info_Fname);
            stim_info = stim_info.stimIDs;
            stim_info = clean_endrun_trials(stim_info,trials2cut,idx); %remove trials without proper fmri data
            subject_stim_info{idx} = stim_info;
        end
    end
end


%   2. load premade stimuli RDM
master_model_RDM = sprintf('%s_RDM_%s.mat',options.dataset,options.model2test);
master_model_RDM = load(fullfile(options.TRfile_dir,master_model_RDM));
master_model_RDM = master_model_RDM.RDM; %DO NOT modify after this point!
mat2vec_mask = logical(triu(ones(size(master_model_RDM)),1));%logical for upper triangular vector


%Begin loops
fprintf(':::Starting region-of-interest RSA:::\r')
for roi_idx = 1:numel(options.roi_list)
    subject_brain_RDMs = cell(numel(options.subjects),1);
    CVbeh_data = cell(size(subject_behavioral_data));
    disp(sprintf('loading brain data for roi #%i %s',roi_idx,options.rois4fig{roi_idx}))
    for subject_idx = 1:numel(options.subjects)
        if ismember(options.subjects(subject_idx),options.exclusions) == 0
            %   3. load brain data & assemble RDM
            CVbeh_data(subject_idx,:) = subject_behavioral_data(subject_idx,:); %pass behavioral data
            run_index = make_runindex(options); %make run index
            data_matrix = load(subject_file_pointers{subject_idx,roi_idx});
            data_matrix = data_matrix.data_matrix;
            data_matrix = HDRlag(options,data_matrix,run_index); %lag data, average over window (if specified)
            data_matrix = clean_endrun_trials(data_matrix,trials2cut,subject_idx);%remove behavioral trials without proper fmri data
            [data_matrix,CVbeh_data{subject_idx}] = select_trials(data_matrix,CVbeh_data{subject_idx});%select trials
            run_index = clean_endrun_trials(run_index,trials2cut,subject_idx);%match run index to valid fmri trials
            %normalization/termporal compression
            switch options.normalize_space
                case 'on'
                    for ridx = 1:numel(unique(run_index))
                        curr_run = unique(run_index);
                        curr_run = run_index == curr_run(ridx);
                        data_matrix(curr_run,:) = bsxfun(@minus,data_matrix(curr_run,:),mean(data_matrix(curr_run,:))); %mean subtract voxel-wise
                        data_matrix(curr_run,:) = minmax_normdata(data_matrix(curr_run,:)); %minmax normalize voxel-wise
                    end
            end
            switch options.trial_temporal_compression
                case 'on'
                    [data_matrix,CVbeh_data{subject_idx}] = temporal_compression(data_matrix,CVbeh_data{subject_idx},options);
                case 'runwise'
                    [data_matrix,CVbeh_data{subject_idx}] = temporal_compression_runwise(data_matrix,CVbeh_data{subject_idx},run_index);
                case 'off'
                    %data_matrix = zscore(data_matrix); %normalize subject-wise
            end
            
            switch options.normalize_space
                case 'on'
                    data_matrix = bsxfun(@minus,data_matrix,mean(data_matrix,2)); %mean subtract across space
                    data_matrix = minmax_normdata(data_matrix'); %min/max scale across space
                    data_matrix = data_matrix'; %transpose b/c function works row-wise
            end
            
            switch options.cocktail_blank
                case 'runwise' %watch out for this if you try to combine with spatial normalization...
                    data_matrix = cocktail_blank_normalize(data_matrix,run_index);
                    disp('voxels set to zero mean & unit variance: run wise')
                case 'off'
                    disp('WARNING: skipping cocktail blank removal')
            end
            
            brainRDM = RSA_constructRDM(data_matrix,options); %make brain RDM
            subject_brain_RDMs{subject_idx} = brainRDM;
            
        end
    end
end

stim_model_RSM = atanh(1-master_model_RDM); %convert stimuli model to similarity matrix likewise...
stim_model_RSM = stim_model_RSM(mat2vec_mask);
%what a headache that is...
%vectorize and stuff below, keep this the same for permutation testing
%stim_model_RDM = stim_model_RDM(mat2vec_mask); %vectorize


disp('--------------------------------------------------------------------')


%   4. aggregate group brain data RDMs into RSMs and permute the ordering
%      ----note: use valid permutation order, only permute the grand matrix
%      entries which were possible (i.e. a subject could have seen). 

subjectIDs = cellfun(@unique,subject_behavioral_data);
groupIDs = unique(subjectIDs);
permuted_group_fits = NaN(options.num_perms,num_groups);
for group_idx = 1:num_groups
    disp(sprintf('Calculating permuted RSMs for group #%i of %i',group_idx,num_groups))
    group_subjects = find(subjectIDs == groupIDs(group_idx));
    permuted_RSMs = NaN(sum(mat2vec_mask(:)),options.num_perms); %store vectorized permuted RSMs
    for permidx = 1:options.num_perms 
        if mod(permidx,1000) == 0
            disp(sprintf('----RSM #%i/%i complete',permidx,options.num_perms))
        end
        currRSM = NaN([size(master_model_RDM),numel(group_subjects)]);
        for subject_idx = 1:numel(group_subjects) %loop through and put each subject's RDM entries where they belong..
            subjectRSM = subject_brain_RDMs{group_subjects(subject_idx)};
            subjectRSM = atanh(1-subjectRSM); %convert to similarity matrix and normalize coefficients
            subject_stims = subject_stim_info{group_subjects(subject_idx)};
            permuted_order = randperm(numel(subject_stims)); %only permute the entries valid for this subject
            permuted_stims = subject_stims(permuted_order); %pass permuted entries to dealing function
            currRSM(:,:,subject_idx) = RSA_deal_RDMentries(currRSM(:,:,subject_idx),subjectRSM,permuted_stims);
        end
        %now aggregate
        currRSM = nanmean(currRSM,3); %mean of normalized cooeficients
        permuted_RSMs(:,permidx) = currRSM(mat2vec_mask);
    end
    %   5. Test RDMs
    permuted_group_fits(:,group_idx) = corr(permuted_RSMs,stim_model_RSM,'type','Spearman','rows','pairwise');    
end



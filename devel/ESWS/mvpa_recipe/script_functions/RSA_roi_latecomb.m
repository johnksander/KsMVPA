function group_fits = RSA_roi_latecomb(subject_file_pointers,options)

%gonna try some "late combination of evidence", average subject brain data
%RDMs and compare against grand stimli info RDM


%GOALS:::
%   0. Initialize variables
%   1. load behavioral data
%   2. load premade stimuli RDM
%   3. load brain data & assemble RDM
%   4. aggregate group brain data RDMs into RSMs
%   5. Test RDMs


switch options.behavioral_transformation %add EA/US split here
    case 'origin_split'
        num_groups = 2;
        group_fits = NaN(num_groups,1); %fits
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
    subject_brain_RDMS = cell(numel(options.subjects),1);
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
            subject_brain_RDMS{subject_idx} = brainRDM;
            
        end
    end
end


%   4. aggregate grouyp brain data RDMs into RSMs
subjectIDs = cellfun(@unique,subject_behavioral_data);
groupIDs = unique(subjectIDs);
groupRSMs = cell(num_groups,1);
for group_idx = 1:num_groups
    group_subjects = find(subjectIDs == groupIDs(group_idx));
    RSMs = NaN([size(master_model_RDM),numel(group_subjects)]);
    for subject_idx = 1:numel(group_subjects) %loop through and put each subject's RDM entries where they belong..
        subjectRSM = subject_brain_RDMS{group_subjects(subject_idx)};
        subjectRSM = atanh(1-subjectRSM); %convert to similarity matrix and normalize coefficients
        subject_stims = subject_stim_info{group_subjects(subject_idx)};
        RSMs(:,:,subject_idx) = RSA_deal_RDMentries(RSMs(:,:,subject_idx),subjectRSM,subject_stims);
    end
    %now aggregate
    groupRSMs{group_idx} = nanmean(RSMs,3); %mean of normalized cooeficients
end


stim_model_RSM = atanh(1-master_model_RDM); %convert stimuli model to similarity matrix likewise...
%what a headache that is...
%vectorize and stuff below, keep this the same for permutation testing
%stim_model_RDM = stim_model_RDM(mat2vec_mask); %vectorize


%   5. Test RDMs

for group_idx = 1:num_groups
    
    brainRDM = groupRSMs{group_idx};
    brainRDM = brainRDM(mat2vec_mask); %vectorize upper triangular
    missing_entries = isnan(brainRDM); %not all parwise combinations of stimuli shown within subjects...
    brainRDM = brainRDM(~missing_entries);
    stimRSM = stim_model_RSM(mat2vec_mask);
    stimRSM = stimRSM(~missing_entries);
    
    %   5. Test RDM
    switch options.RDM_dist_metric
        case 'spearman'
            group_fits(group_idx) = corr(brainRDM,stimRSM,'type','Spearman');
    end
end
    
    
%     
%     %   5. permutation test of RDM 
%     brainRDM = groupRSMs{group_idx};
%     permutedRDMs = cell(options.num_perms,1);
%     for permidx = 1:options.num_perms
%         curr_order = randperm(numel(brainRDM(:,1)))'; %set permutation order
%         permutedRDMs{permidx} = RSA_permuteRDM(brainRDM,curr_order);
%     end
%     %take upper triangular of permuted RDMs
%     permutedRDMs = cellfun(@(x) x(mat2vec_mask),permutedRDMs,'UniformOutput',false);
%     permutedRDMs = cat(2,permutedRDMs{:});
%     switch options.RDM_dist_metric
%         case 'spearman'
%             perm_results(:) = corr(RDM,permutedRDMs,'type','Spearman','rows','pairwise');
%             %fisher Z transformed
%     end
%     
%     
%     
%     
%     %   8. slice searchlights & assemble RDM
%     searchlight_results = NaN(numel(seed_inds),options.num_perms);%easier results-to-roi file mapping
%     for searchlight_idx = 1:numel(seed_inds)
%         
%         current_searchlight = searchlight_brain_data(:,:,searchlight_idx);
%         RDM = RSA_constructRDM(current_searchlight,options);
%         RDM = RDM(mat2vec_mask); %take upper triangular vector
%         perm_results = NaN(1,options.num_perms); %make sure the dimensions are gonna match nicely
%         
%         %   9. test RDM
%         switch options.RDM_dist_metric
%             case 'spearman'
%                 perm_results(:) = atanh(corr(RDM,permutedRDMs,'type','Spearman'));
%                 %fisher Z transformed
%         end
%         
%         %  10. store permuted RDM fits to behavioral RDM
%         searchlight_results(searchlight_idx,:) = perm_results;
%         
%         switch options.parforlog %parfor progress tracking
%             case 'on'
%                 txtappend(special_progress_tracker,'1\n')
%                 progress = load(special_progress_tracker);
%                 if mod(sum(progress),numel(seed_inds) * .005) == 0 %.5 percent
%                     progress = (sum(progress) /  numel(seed_inds)) * 100;
%                     message = sprintf('Searchlight RSA permutations %.1f percent complete',progress);
%                     update_logfile(message,output_log)
%                 end
%         end
%     end%searchlight loop
%     voxel_null{subject_idx,roi_idx} = searchlight_results;
%     
%     
%     
%     
% end





%     %Remove exclusions from both brain & behavior data
%     subject_inds = options.subjects(valid_subs)';
%     CVbeh_data = CVbeh_data(valid_subs,:);
%     subject_brain_data = subject_brain_data(valid_subs);
%     subject_behavior_models = subject_behavior_models(valid_subs);
%     %set up inds for leave out CV scheme
%     subject_inds = match_subinds2data(subject_inds,subject_brain_data); %make subject inds match the data (num scans etc)
%     CVbeh_data = cell2mat(CVbeh_data); %now everything can be a matrix
%     subject_brain_data = cell2mat(subject_brain_data); %now everything can be a matrix
%     %subject_brain_data = zscore(subject_brain_data); %!!!!normalize across "conditions"!!!!
%     fprintf('WARNING: skipping cocktail blank removal\r')
%
%     for beh_idx = 1:numel(options.behavioral_file_list) %Cycle through valence levels, performing classification on each
%         curr_behavioral_data = CVbeh_data(:,beh_idx);
%         disp(sprintf('roi #%i: classifying subjects for behavior level #%i ',roi_idx,beh_idx))
%
%         parfor test_sub_combo = 1:numel(subs2LO(1,:))
%             %subjects already excluded, don't need if statment here
%             cv_params = struct();%initialize stucture for parfor loop
%             %subject logicals
%             testing_subject = subs2LO(:,test_sub_combo);
%             training_subjects = ~ismember(subject_inds,testing_subject);
%             testing_subject = ~training_subjects; %just to make it explicit
%             %class labels
%             training_labels = curr_behavioral_data(training_subjects);
%             testing_labels = curr_behavioral_data(testing_subject);
%             %testing/training data
%             training_data = subject_brain_data(training_subjects,:); %prevent subject_brain_data from broadcasting (update, it's broadcasting here dummy)
%             testing_data = subject_brain_data(testing_subject,:);
%             %select trials
%             [testing_data,testing_labels] = select_trials(testing_data,testing_labels);
%             [training_data,training_labels] = select_trials(training_data,training_labels);
%
%             switch options.feature_selection
%                 case 'off'
%
%                     cv_params.fe_testing_data = testing_data; %put data straight into fe_x, avoid duplicating data matricies
%                     cv_params.fe_training_data = training_data;
%
%                 case 'pca_only'
%                     %1a. make cv_params struct for pca_kmeans function
%                     cv_params.testing_data = testing_data;
%                     cv_params.training_data = training_data; %avoid duplicating roi matricies if possible
%                     [cv_params.fe_training_data, cv_params.fe_testing_data] = pca_only(cv_params,options); %run through pca
%                     %1b. Feature select based on training data
%                     %                 [wd,M,P] = zca_whiten(training_data,options.lambda);
%                     %                 trained_centroids = runkmeans(wd,curr_num_centroids,options.k_iterations);
%                     %                 fe_training_data = extract_brain_features(training_data,trained_centroids,M,P);
%                     %                 fe_testing_data = extract_brain_features(testing_data,trained_centroids,M,P);
%                     %2a. make cv_params struct for classifier function
%                     %                 cv_params.fe_training_data = fe_training_data;
%                     %                 cv_params.fe_testing_data = fe_testing_data;
%             end
%             cv_params.training_labels = training_labels;
%             cv_params.testing_labels = testing_labels;
%             %2b. Insert classifier
%             cv_guesses = options.classifier_type(cv_params,options);
%             %cv_guesses = cat_cv_inds({cv_guesses});
%             output_coeffs{test_sub_combo,roi_idx,beh_idx} = cv_guesses;
%         end
%     end
%end



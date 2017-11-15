function output_coeffs = RSA_roi(subject_file_pointers,options)

%GOALS:::
%   0. Initialize variables
%   1. load behavioral data
%   2. load premade stimuli RDMs
%   3. make hypothesis matrix
%   4. load brain data & assemble RDM
%   5. Test RDM

%0.    Initialize variables
valid_subs = ~ismember(options.subjects,options.exclusions)';
trials2cut = find_endrun_trials(options); %find behavioral trials without proper fmri data
output_coeffs = cell(numel(options.subjects),numel(options.roi_list),numel(options.behavioral_file_list));
subject_behavioral_data = cell(numel(options.subjects),numel(options.behavioral_file_list));
subject_behavior_models = cell(numel(options.subjects),1);
for idx = 1:numel(options.subjects)
    if ismember(options.subjects(idx),options.exclusions) == 1
        %Don't do anything
    else
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
            mdlFname = sprintf('%s_RDM_%s_%i.mat',options.dataset,options.model2test,options.subjects(idx));
            mdlFname = fullfile(options.TRfile_dir,mdlFname);
            beh_mdl = load(mdlFname);
            beh_mdl = beh_mdl.RDM;
            beh_mdl = clean_endrun_trials(beh_mdl,trials2cut,idx); %remove behavioral trials without proper fmri data
            beh_mdl = clean_endrun_trials(beh_mdl',trials2cut,idx); %now do it the other way, remove corresponding other dimension
            subject_behavior_models{idx} = beh_mdl;
        end
    end
end


%Begin loops
fprintf(':::Starting region-of-interest RSA:::\r')
for roi_idx = 1:numel(options.roi_list)
    subject_brain_data = cell(numel(options.subjects),1);
    CVbeh_data = cell(size(subject_behavioral_data));
    disp(sprintf('loading brain data for roi #%i %s',roi_idx,options.rois4fig{roi_idx}))
    for subject_idx = 1:numel(options.subjects)
        if ismember(options.subjects(subject_idx),options.exclusions) == 0
            %   4. load brain data & assemble RDM
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
            
            
            
            subject_brain_data{subject_idx} = data_matrix;
            
            behaviorRDM = subject_behavior_models{subject_idx};
            mat2vec_mask = logical(triu(ones(size(behaviorRDM)),1));%reduce to upper triangular vector
            behaviorRDM = behaviorRDM(mat2vec_mask);
            
            brainRDM = RSA_constructRDM(data_matrix,options); %make brain RDM
            brainRDM = brainRDM(mat2vec_mask); %vectorize
            
            %   5. Test RDM
            switch options.RDM_dist_metric
                case 'spearman'
                    model_fit = corr(brainRDM,behaviorRDM,'type','Spearman');
                    model_fit = atanh(model_fit); %fisher Z transform
            end
            
            output_coeffs{subject_idx} = model_fit;
            
        end
    end
    
end
keyboard

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



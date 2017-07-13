function predictions = L2SO_roi_parfor_mvpa(subject_file_pointers,options)

%GOALS:::
%   0. Initialize variables and load behavioral data
%   1. Feature select
%   2. Fit models
%   3. Predict/decode

%0. Initialize variables
%make all combinations of 1 US subject & 1 EA subject
L2Ocombos = options.subjects(~ismember(options.subjects,options.exclusions));
L2Ocombos = {L2Ocombos(L2Ocombos < 200), L2Ocombos(L2Ocombos > 200)};
L2Ocombos = combvec(L2Ocombos{1},L2Ocombos{2});
predictions = cell(numel(L2Ocombos(1,:)),numel(options.roi_list),numel(options.behavioral_file_list));
%find behavioral trials without proper fmri data
trials2cut = find_endrun_trials(options);
%load all behavioral data for all subjs
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
        end
    end
end


%Begin loops
fprintf(':::MVPA data:::\r')
for roi_idx = 1:numel(options.roi_list)
    subject_brain_data = cell(numel(options.subjects),1);
    CVbeh_data = cell(size(subject_behavioral_data));
    disp(sprintf('loading brain data for roi #%i %s',roi_idx,options.rois4fig{roi_idx}))
    %load all brain data
    for subject_idx = 1:numel(options.subjects)
        if ismember(options.subjects(subject_idx),options.exclusions) == 1
            %Don't do anything
        else
            CVbeh_data(subject_idx,:) = subject_behavioral_data(subject_idx,:); %pass behavioral data
            run_index = make_runindex(options,subject_idx); %make run index
            load(subject_file_pointers{subject_idx,roi_idx});
            data_matrix = HDRlag(options,data_matrix,run_index); %lag data, average over window (if specified)
            data_matrix = clean_endrun_trials(data_matrix,trials2cut,subject_idx);%remove behavioral trials without proper fmri data
            [data_matrix,CVbeh_data{subject_idx}] = select_trials(data_matrix,CVbeh_data{subject_idx});%select trials
            %normalization/termporal compression
            switch options.trial_temporal_compression
                case 'on'
                    [data_matrix,CVbeh_data{subject_idx}] = temporal_compression(data_matrix,CVbeh_data{subject_idx},options);
                case 'runwise'
                    run_index = clean_endrun_trials(run_index,trials2cut,subject_idx);%match run index to valid fmri trials
                    [data_matrix,CVbeh_data{subject_idx}] = temporal_compression_runwise(data_matrix,CVbeh_data{subject_idx},run_index);
                case 'off'
                    %data_matrix = zscore(data_matrix); %normalize subject-wise
            end
            subject_brain_data{subject_idx} = data_matrix;
        end
    end
    
    
    %set up inds for leave 2 out
    subject_inds = options.subjects';
    subject_inds = subject_inds(~ismember(subject_inds,options.exclusions)); %kick out exclusions so dims match below
    subject_inds = match_subinds2data(subject_inds,subject_brain_data); %make subject inds match the data (num scans etc)
    subject_brain_data = cell2mat(subject_brain_data); %now everything can be a matrix
    subject_brain_data = zscore(subject_brain_data); %!!!!normalize across "conditions"!!!!

    for beh_idx = 1:numel(options.behavioral_file_list) %Cycle through valence levels, performing classification on each
        curr_behavioral_data = cell2mat(CVbeh_data(:,beh_idx));
        disp(sprintf('roi #%i: classifying subjects for behavior level #%i ',roi_idx,beh_idx))
        
        parfor test_sub_combo = 1:numel(L2Ocombos(1,:))
            %subjects already excluded, don't need if statment here
            training_data = subject_brain_data; %prevent subject_brain_data from broadcasting (update, it's broadcasting here dummy)
            testing_data = subject_brain_data;
            testing_labels = curr_behavioral_data;
            training_labels = curr_behavioral_data;
            %ok now do cv loop
            cv_params = struct();%initialize stucture for parfor loop
            testing_subject = L2Ocombos(:,test_sub_combo);
            training_subjects = ~ismember(subject_inds,testing_subject);
            testing_subject = ~training_subjects; %just to make it explicit
            training_data = training_data(training_subjects,:);
            testing_data = testing_data(testing_subject,:);
            testing_labels = testing_labels(testing_subject);
            training_labels = training_labels(training_subjects);
            [testing_data,testing_labels] = select_trials(testing_data,testing_labels);
            [training_data,training_labels] = select_trials(training_data,training_labels);
            switch options.feature_selection
                case 'off'
                    
                    cv_params.fe_testing_data = testing_data; %put data straight into fe_x, avoid duplicating data matricies
                    cv_params.fe_training_data = training_data;
                    
                case 'pca_only'
                    %1a. make cv_params struct for pca_kmeans function
                    cv_params.testing_data = testing_data;
                    cv_params.training_data = training_data; %avoid duplicating roi matricies if possible
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
            cv_guesses = options.classifier_type(cv_params,options);
            %cv_guesses = cat_cv_inds({cv_guesses});
            predictions{test_sub_combo,roi_idx,beh_idx} = cv_guesses;
        end
    end
end



function predictions = twofold_roi_parfor_mvpa(subject_file_pointers,options)

%GOALS:::
%   0. get twofold subject combos
%   1. Initialize variables and load behavioral data
%   2. Feature select
%   3. Fit models
%   4. Predict/decode


%make 1000 combinations of 8 US subjects & 8 EA subjects (save for perm testing)
%   twofold_combos = twofoldESWScombos(options);
%   save(fullfile(options.mvpa_datadir,'twofold_subject_combos20160519'),'twofold_combos')

%load preset twofold subject combos 
twofold_combos = load(fullfile(options.mvpa_datadir,'twofold_subject_combos20160519'));
twofold_combos = twofold_combos.twofold_combos;
disp(sprintf('\nLoading preset twofold subject combinations\n'));

%1. Initialize vars 
predictions = cell(numel(twofold_combos(1,:)),numel(options.roi_list),numel(options.behavioral_file_list));
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
                        beh_matrix(~isnan(beh_matrix)) = 0; %US
                    elseif options.subjects(idx) > 200
                        beh_matrix(~isnan(beh_matrix)) = 1; %EA
                    end
                    
                    switch options.rawdata_type
                        case 'anatom'
                            if options.subjects(idx) < 200
                                beh_matrix = 0; %US
                            elseif options.subjects(idx) > 200
                                beh_matrix = 1; %EA
                            end
                    end
                    
            end
            subject_behavioral_data{idx,beh_idx} = beh_matrix;
        end
    end
end

switch  options.trial_temporal_compression
    case 'on'
        untransformed_behavior = subject_behavioral_data;
        %create a copy for trial compression
        %compression function transforms subject_behavioral_data, gets messed up when it cycles to the next roi
end


%Begin loops
fprintf(':::MVPA data:::\r')
for roi_idx = 1:numel(options.roi_list)
    subject_brain_data = cell(numel(options.subjects),1);
    disp(sprintf('loading brain data for roi #%i %s',roi_idx,options.rois4fig{roi_idx}))
    %load all brain data
    for subject_idx = 1:numel(options.subjects)
        if ismember(options.subjects(subject_idx),options.exclusions) == 1
            %Don't do anything
        else
            load(subject_file_pointers{subject_idx,roi_idx});
            
            run_index = make_runindex(options,idx); %make run index
            data_matrix = zscore(data_matrix); %normalize subject-wise (see comment mess below)
            
            switch options.lag_type
                case 'single'
                case 'average'
                    data_matrix = conv_TRwindow(data_matrix,run_index,options.running_average_window);
            end
            
            lagged_data = HDRlag(data_matrix,run_index,options.tr_delay); %lag data
            
            switch options.trial_temporal_compression %termporal compression
                case 'on'
                    [lagged_data,subject_behavioral_data{subject_idx}] = temporal_compression(lagged_data,untransformed_behavior{subject_idx},options);
            end
            
            subject_brain_data{subject_idx} = lagged_data; %return data to brain data array
            
            
            
            %subject_brain_data{subject_idx} = zscore(lagged_data); %NEED TO NORMALIZE EACH SUBJECT!!!
            %09/07/15: across run normalization for each roi added to preallocate searchlight rois function (shouldn't normalize after lagging anyways, extra filler TR data added in lagging procedure)
            %10/7/15: on second thought, data was normalizedrun-wise in preprocessing- we'll need to normalize whole subject data here (takes care of train-to-test normalization
            %11/2/15: subject-wise normalization removed from preprocess (preallocate) searchlight rois function. This is taken care of here before lagging
            
            
        end
    end
    
    %set up inds for leave 2 out
    subject_inds = options.subjects';
    subject_inds = subject_inds(~ismember(subject_inds,options.exclusions)); %kick out exclusions so dims match below
    
    %04/08/15: setting curr_num_centroids moved to pca_kmeans function
    
    for beh_idx = 1:numel(options.behavioral_file_list) %Cycle through valence levels, performing classification on each
        curr_behavioral_data = subject_behavioral_data(:,beh_idx);
        disp(sprintf('roi #%i: classifying subjects for behavior level #%i ',roi_idx,beh_idx))
        
        parfor test_sub_combo = 1:numel(twofold_combos(1,:)) 
            %subjects already excluded, don't need if statment here
            %put everything into matricies beforehand, just so I can be cautious with indexing (logicial vectors are a diff size)
            training_data = subject_brain_data; %prevent subject_brain_data from broadcasting
            testing_data = cell2mat(training_data); %avoid doubling up on the matrix here, just use the training data
            training_data = cell2mat(training_data);
            testing_labels = cell2mat(curr_behavioral_data);
            training_labels = cell2mat(curr_behavioral_data);
            %ok now do cv loop
            cv_params = struct();%initialize stucture for parfor loop
            testing_subject = twofold_combos(:,test_sub_combo);
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



function predictions = LOSO_roi_mvpa(subject_file_pointers,options)

%GOALS:::
%   0. Initialize variables and load behavioral data
%   1. Feature select
%   2. Fit models
%   3. Predict/decode

%0. Initialize variables
predictions = cell(numel(options.subjects),numel(options.roi_list),numel(options.behavioral_file_list));

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
            subject_brain_data{subject_idx} = lagged_data;
            
            
            %subject_brain_data{subject_idx} = zscore(lagged_data); %NEED TO NORMALIZE EACH SUBJECT!!!
            %09/07/15: across run normalization for each roi added to preallocate searchlight rois function (shouldn't normalize after lagging anyways, extra filler TR data added in lagging procedure)
            %10/7/15: on second thought, data was normalizedrun-wise in preprocessing- we'll need to normalize whole subject data here (takes care of train-to-test normalization
            %11/2/15: subject-wise normalization removed from preprocess (preallocate) searchlight rois function. This is taken care of here before lagging
            
            
        end
    end
    
    %04/08/15: setting curr_num_centroids moved to pca_kmeans function
    
    for beh_idx = 1:numel(options.behavioral_file_list) %Cycle through valence levels, performing classification on each
        curr_behavioral_data = subject_behavioral_data(:,beh_idx);
        disp(sprintf('roi #%i: classifying subjects for behavior level #%i ',roi_idx,beh_idx))
        
        for idx = 1:numel(options.subjects)
            if ismember(options.subjects(idx),options.exclusions) == 1
                %Don't do anything
            else
                testing_subject = idx;
                training_subjects = find(~ismember(1:numel(options.subjects),testing_subject));
                testing_data = subject_brain_data{testing_subject};
                training_data = cell2mat(subject_brain_data(training_subjects));
                testing_labels = curr_behavioral_data{testing_subject};
                training_labels = cell2mat(subject_behavioral_data(training_subjects'));
                [testing_data,testing_labels] = select_trials(testing_data,testing_labels);
                [training_data,training_labels] = select_trials(training_data,training_labels);
                %1a. make cv_params struct for pca_kmeans function
                cv_params.testing_data = testing_data;
                cv_params.training_data = training_data;
                cv_params.fe_testing_data = testing_data;
                cv_params.fe_training_data = training_data;
                %[cv_params.fe_training_data, cv_params.fe_testing_data] = pca_only(cv_params,options);
                %1b. Feature select based on training data
                %                 [wd,M,P] = zca_whiten(training_data,options.lambda);
                %                 trained_centroids = runkmeans(wd,curr_num_centroids,options.k_iterations);
                %                 fe_training_data = extract_brain_features(training_data,trained_centroids,M,P);
                %                 fe_testing_data = extract_brain_features(testing_data,trained_centroids,M,P);
                %2a. make cv_params struct for classifier function
                %                 cv_params.fe_training_data = fe_training_data;
                %                 cv_params.fe_testing_data = fe_testing_data;
                cv_params.training_labels = training_labels;
                cv_params.testing_labels = testing_labels;
                %2b. Insert classifier
                cv_guesses = options.classifier_type(cv_params,options);
                %cv_guesses = cat_cv_inds({cv_guesses});
                predictions{testing_subject,roi_idx,beh_idx} = cv_guesses;
            end
        end
    end
end



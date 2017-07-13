function predictions = LOSO_roi_mvpa_v3(subject_file_pointers,options,roi_number)

%GOALS:::
%   0. Initialize variables and load behavioral data
%   1. Feature select
%   2. Fit models
%   3. Predict/decode

%0. Initialize variables
run_index = make_runindex(options.scans_per_run); %make run index
runs = unique(run_index);
num_runs = numel(runs);
predictions = cell(numel(options.subjects),numel(options.roi_list),numel(options.behavioral_file_list));


%load all behavioral data for all subjs
subject_behavioral_data = cell(numel(options.subjects),numel(options.behavioral_file_list));
for idx = 1:numel(options.subjects)
    if ismember(options.subjects(idx),options.exclusions) == 1
        %Don't do anything
    else
        subj_dir = fullfile(options.home_dir,[options.main_dir sprintf('%02i',options.subjects(idx))]);
        for beh_idx = 1:numel(options.behavioral_file_list),
            my_files = prepare_fp(subj_dir,'model_parametric',options.behavioral_file_list{beh_idx});
            MCQDmatrix = load_behav_data(my_files);
            MCQDmatrix = MCQDmatrix(:,options.which_behavior); %select behavioral rating
            switch options.behavioral_transformation
                case 'balanced_median_split'
                    MCQDmatrix = balanced_median_split(MCQDmatrix);
                case 'best_versus_rest'
                    
                otherwise
            end
            subject_behavioral_data{idx,beh_idx} = MCQDmatrix;
        end
    end
end


%Begin loops
fprintf(':::MVPA data:::\r')
for roi_idx = roi_number,
    subject_brain_data = cell(numel(options.subjects),1);
    disp(sprintf('loading brain data for roi #%i',roi_idx))
    %load all brain data
    for subject_idx = 1:numel(options.subjects)
        if ismember(options.subjects(subject_idx),options.exclusions) == 1
            %Don't do anything
        else
            data_matrix = load(subject_file_pointers{subject_idx,roi_idx});
            data_matrix = data_matrix.data_matrix; %take it out of a structure
            lagged_data = HDRlag(data_matrix,run_index,options.tr_delay); %lag data
            subject_brain_data{subject_idx} = lagged_data;
        end
    end
    
    %04/08/15: setting curr_num_centroids moved to pca_kmeans function
    
    
    for beh_idx = 1:numel(options.behavioral_file_list) %Cycle through valence levels, performing classification on each
        curr_behavioral_data = subject_behavioral_data(:,beh_idx);
        disp(sprintf('roi #%i: classifying subjects for valence #%i ',roi_idx,beh_idx))
        
        for idx = 1:numel(options.subjects)
            if ismember(options.subjects(idx),options.exclusions) == 1
                %Don't do anything
            else
                testing_subject = idx;
                training_subjects = options.subjects(~ismember(options.subjects,testing_subject));
                testing_data = subject_brain_data{testing_subject};
                training_data = cell2mat(subject_brain_data(training_subjects));
                testing_labels = curr_behavioral_data{testing_subject};
                training_labels = cell2mat(subject_behavioral_data(training_subjects'));
                [testing_data,testing_labels] = select_trials(testing_data,testing_labels);
                [training_data,training_labels] = select_trials(training_data,training_labels);
                %1a. make cv_params struct for pca_kmeans function
                cv_params.testing_data = testing_data;
                cv_params.training_data = training_data;
                [cv_params.fe_training_data, cv_params.fe_testing_data] = pca_kmeansv2(cv_params,options);
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
                cv_guesses = cat_cv_inds({cv_guesses});
                predictions{testing_subject,roi_idx,beh_idx} = cv_guesses{:};
            end
        end
        message = sprintf(' Finished beh %i of ROI num %i',beh_idx,roi_number);
        message = [datestr(now,31) message];
        txtappend(['LOSOv3_progress.txt'],message)
    end
    
    message = sprintf(' Finished ROI num #%i',roi_number);
    message = [datestr(now,31) message];
    txtappend(['LOSOv3_progress.txt'],message)
    
end



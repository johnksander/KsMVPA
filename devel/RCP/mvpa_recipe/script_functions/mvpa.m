function predictions = mvpa(subject_file_pointers,options)
%GOALS:::
%   0. Initialize variables and load behavioral data
%   1. Feature select
%   2. Fit models
%   3. Predict/decode

%0. Initialize variables
run_index = make_runindex(options.scans_per_run); %make run index
runs = unique(run_index);
num_runs = numel(runs);
run_perms = nchoosek(runs,num_runs-1); %form all possible scan run permutations
run_perms = run_perms - min(runs) + 1; %correct permutation index
predictions = cell(numel(options.subjects),numel(options.roi_list),numel(options.behavioral_file_list));

%Begin loops
fprintf(':::MVPA data:::\r')
for idx = 1:numel(options.subjects)
    if ismember(options.subjects(idx),options.exclusions) == 1
        %Don't do anything
    else
        disp(sprintf('starting subject #%i',idx))
        %0. load in behavioral data
        behavioral_data = cell(numel(options.behavioral_file_list),1);
        for beh_idx = 1:numel(options.behavioral_file_list),
            BehFname = [options.behavioral_file_list{beh_idx} sprintf('%02i',options.subjects(idx)) '.txt'];
            my_files = prepare_fp(options,options.TRfile_dir,BehFname);
            beh_matrix = load_behav_data(my_files,options);
            beh_matrix = beh_matrix(:,options.which_behavior); %select behavioral rating
            switch options.behavioral_transformation
                case 'balanced_median_split'
                    beh_matrix = balanced_median_split(beh_matrix);
                case 'best_versus_rest'
                    
                otherwise
            end
            behavioral_data{beh_idx} = beh_matrix;
        end
        %Loop through ROIs -- Consider this for a searchlight loop
        for roi_idx = 1:numel(options.roi_list)
            load(subject_file_pointers{idx,roi_idx}); %load preprocessed ROI
            
            %04/08/15: setting curr_num_centroids moved to pca_kmeans function
            
            switch options.lag_type
                case 'single'
                case 'average'
                    data_matrix = conv_TRwindow(data_matrix,run_index,options.running_average_window);
                    %lagged_data = averagedata_over_TRwindow(data_matrix,run_index,options.tr_delay);
            end
            lagged_data = HDRlag(data_matrix,run_index,options.tr_delay);
            %Loop through behavior
            switch options.crossval_method
                case 'runwise'
                    
                    for beh_idx = 1:numel(options.behavioral_file_list),
                        %0. Insert crossvalidation loop
                        cv_guesses = cell(num_runs,1);
                        for cv_idx = 1:num_runs,
                            cv_params = divy_cv_info(run_index,lagged_data,behavioral_data,run_perms,cv_idx,beh_idx);
                            %1. Feature select based on training data
                            %                     [wd,M,P] = zca_whiten(cv_params.training_data,options.lambda);
                            %                     trained_centroids = runkmeans(wd,curr_num_centroids,options.k_iterations);
                            %                     cv_params.fe_training_data = extract_brain_features(cv_params.training_data,trained_centroids,M,P);
                            %                     cv_params.fe_testing_data = extract_brain_features(cv_params.testing_data,trained_centroids,M,P);
                            [cv_params.fe_training_data, cv_params.fe_testing_data] = pca_kmeans(cv_params,options);
                            %2. Insert classifier
                            
                            cv_guesses{cv_idx} = options.classifier_type(cv_params,options);
                        end
                        cv_guesses = cat_cv_inds(cv_guesses);
                        predictions{idx,roi_idx,beh_idx} = cat(1,cv_guesses{:});
                        %cv_guesses is col1 = guesses, col2 = labels, col3 = run index
                    end
                    
                    
                    
                case 'random_bag'
                    for beh_idx = 1:numel(options.behavioral_file_list)
                        cv_guesses = cell(options.randbag_itr,1); %needs to be reworked
                        for cv_idx = 1:options.randbag_itr
                            cv_params = randbag_crossval(behavioral_data,beh_idx,lagged_data);
                            [cv_params.fe_training_data, cv_params.fe_testing_data] = pca_kmeans(cv_params,options);
                            cv_guesses{cv_idx} = options.classifier_type(cv_params,options);
                            %disp(sprintf('Iteration %i/%i complete',cv_idx,options.randbag_itr))
                            predictions{idx,roi_idx,beh_idx} = cat(1,cv_guesses{:});
                        end
                    end
                    
                    
            end
            disp(sprintf('roi #%i complete for all valence',roi_idx))
        end
    end
end




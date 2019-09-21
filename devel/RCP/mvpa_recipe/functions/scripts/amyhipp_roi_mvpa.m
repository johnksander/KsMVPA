function predictions = amyhipp_roi_mvpa(subject_file_pointers,options)
%GOALS:::
%   0. Initialize variables and load behavioral data
%   1. Feature select
%   2. Fit modelss
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
        subj_dir = fullfile(options.home_dir,[options.main_dir sprintf('%02i',options.subjects(idx))]);
        behavioral_data = cell(numel(options.behavioral_file_list),1);
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
            behavioral_data{beh_idx} = MCQDmatrix;
        end
        %Loop through ROIs -- Consider this for a searchlight loop
        for roi_idx = 1:2 %hardcoded Left/right
            
            if roi_idx == 1
                rois2load = [1 3];
            elseif roi_idx == 2
                rois2load = [2 4];
            end
            
            concatenated_rois = [];
            
            for loadidx = 1:numel(rois2load) 
                load(subject_file_pointers{idx,rois2load(loadidx)}); %load preprocessed ROI 
                concatenated_rois = horzcat(concatenated_rois,data_matrix);
            end
            data_matrix = concatenated_rois;
            %04/08/15: setting curr_num_centroids moved to pca_kmeans function
            
            switch options.lag_type
                case 'single'
                case 'average'
                    data_matrix = conv_TRwindow(data_matrix,run_index,options.running_average_window);
                    %lagged_data = averagedata_over_TRwindow(data_matrix,run_index,options.tr_delay);
            end
            lagged_data = HDRlag(data_matrix,run_index,options.tr_delay);
            %Loop through behavior
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
                    [cv_params.fe_training_data, cv_params.fe_testing_data] = pca_kmeansv2(cv_params,options);
                    %2. Insert classifier
                    
                    cv_guesses{cv_idx} = options.classifier_type(cv_params,options);
                end
                cv_guesses = cat_cv_inds(cv_guesses);
                predictions{idx,roi_idx,beh_idx} = cat(1,cv_guesses{:});
            end
            disp(sprintf('roi #%i complete for all valence',roi_idx))
        end
    end
    message = sprintf(' Finished subject #%i',idx);
    message = [datestr(now,31) message];
    txtappend(['amyhipp_progress.txt'],message)
end




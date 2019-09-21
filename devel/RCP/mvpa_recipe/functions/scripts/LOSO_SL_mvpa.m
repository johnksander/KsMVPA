function brain_cells = LOSO_SL_mvpa(preprocessed_SLroi_files,preproc_data_file_pointers,options)

brain_cells = cell(numel(options.roi_list));

%GOALS:::
%   0. Initialize variables and load behavioral data
%   1. Load preprocessed searchlight roi data
%   2. Feature select
%   3. Fit models
%   4. Predict/decode

%0. Initialize variables
%run_index = make_runindex(options.scans_per_run); %make run index
%runs = unique(run_index);
subject_dirs = preprocessed_SLroi_files.subject_dirs;

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
            end
            subject_behavioral_data{idx,beh_idx} = beh_matrix;
        end
    end
end


%Begin loops
fprintf(':::Starting searchlight LOSO MVPA:::\r')


for roi_idx = 1:numel(options.roi_list)
    
    disp(sprintf('\nROI: %s\n',options.rois4fig{roi_idx}))
    
    %load ROI general info from searchlight preprocessing, sort into original vars
    SLdata_info = load(preprocessed_SLroi_files.SLdata_info{roi_idx});
    %searchlight_inds = SLdata_info.searchlight_inds; %not used?
    seed_inds = SLdata_info.seed_inds;
    SLdata_info = SLdata_info.SLdata_info;
    %initalize output brain
    vol_size = load(preproc_data_file_pointers{1,roi_idx}); %just use first subj as template
    vol_size = size(vol_size.preprocessed_scans);
    output_brain = nan(vol_size(1),vol_size(2),vol_size(3),numel(options.behavioral_file_list));
    [seed_x,seed_y,seed_z] = ind2sub(vol_size(1:3),seed_inds);
    
    
    %loop through searchlight roi chunk-files
    for searchlight_roifile_idx = 1:SLdata_info.total_numfiles
        if mod(searchlight_roifile_idx,20) == 0
            disp(sprintf('Initializing searchlight file #%i/%i',searchlight_roifile_idx,SLdata_info.total_numfiles))
        end
        
        %load all every subject's chunk-file
        subject_roi_files = cell(numel(options.subjects),1);
        for subject_idx = 1:numel(options.subjects)
            if ismember(options.subjects(subject_idx),options.exclusions) == 1
                %Don't do anything
            else
                subject_fileID = ['SLrois_' num2str(options.subjects(subject_idx)) '_' num2str(searchlight_roifile_idx)];
                load(fullfile(subject_dirs{subject_idx,roi_idx},subject_fileID)); %load SLroi_file
                subject_roi_files{subject_idx} = SLroi_file;
            end
        end
        
        
        for searchlight_idx = 1:numel(SLroi_file.inds)%prevents indexing error translating back to original inds, uses last loaded SLroi_file- assumes all subjects have same chunk-file inds
            
            subject_brain_data = cell(numel(options.subjects),1);
            for subject_idx = 1:numel(options.subjects)
                if ismember(options.subjects(subject_idx),options.exclusions) == 1
                    %Don't do anything
                else
                    run_index = make_runindex(options,idx); %make run index
                    data_matrix = subject_roi_files{subject_idx}.searchlights(:,:,searchlight_idx);
                    data_matrix = zscore(data_matrix);
                    if isequal(options.classifier_type,@RelVec)
                        data_matrix = minmax_normdata(data_matrix);
                    end
                    switch options.lag_type
                        case 'single'
                        case 'average'
                            data_matrix = conv_TRwindow(data_matrix,run_index,options.running_average_window);
                            %lagged_data = averagedata_over_TRwindow(data_matrix,run_index,options.tr_delay);
                    end
                    lagged_data = HDRlag(data_matrix,run_index,options.tr_delay); %lag data
                    subject_brain_data{subject_idx} = lagged_data;
                    %subject_brain_data{subject_idx} = zscore(lagged_data); %NEED TO NORMALIZE EACH SUBJECT!!!
                    %09/07/15: across run normalization for each roi added to
                    %preallocate searchlight rois function (shouldn't normalize after lagging anyways, extra filler TR data added in lagging procedure)
                    %10/7/15: on second thought, data was normalizedrun-wise in preprocessing- we'll need to normalize whole subject data here (takes care of train-to-test normalization
                end
            end
            
            
            %04/08/15: setting curr_num_centroids moved to pca_kmeans function
            
            
            for beh_idx = 1:numel(options.behavioral_file_list) %Cycle through valence levels, performing classification on each
                
                curr_behavioral_data = subject_behavioral_data(:,beh_idx);
                %disp(sprintf('roi #%i: classifying subjects for valence #%i ',roi_idx,beh_idx))
                
                predictions = cell(numel(options.subjects),1);
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
                        %cv_guesses = options.classifier_type(cv_params,options);
                        %cv_guesses = cat_cv_inds({cv_guesses}); removed 09/13/15, not sure if it's still useful
                        predictions{testing_subject} = options.classifier_type(cv_params,options);
                    end
                end
                predictions = vertcat(predictions{:});
                il = SLroi_file.inds(searchlight_idx); %this is pulling from the last loaded subject chunk-file, assumes chunk-file inds are the same across subjects
                output_brain(seed_x(il),seed_y(il),seed_z(il),beh_idx) = sum(predictions(:,1) == predictions(:,2)) / numel(predictions(:,1));
                
            end
        end
    end
    brain_cells{roi_idx} = output_brain;
end

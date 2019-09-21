
% load('MVPA_SL_knn_1p5_ASGM10_braincells.mat')
% options = set_bigmem_options2linus(options);
% [~,maxSL] = max(searchlight_results(:,2));
% maxSL = searchlight_results(maxSL,1);
maxSL = 132661;

%load steps 0 through 1


[x,y,z] = ind2sub(vol_size,maxSL);
[emptyx, emptyy, emptyz] = meshgrid(1:vol_size(2),1:vol_size(1),1:vol_size(3));
searchlight_inds = logical((emptyx - y(1)).^2 + ...
    (emptyy - x(1)).^2 + (emptyz - z(1)).^2 ...
    <= options.searchlight_radius.^2); %adds a logical searchlight mask centered on the coordinates sphere_x/y/z_coord


current_searchlight = cell(numel(options.subjects),1);
for idx = 1:numel(options.subjects),
    if ismember(options.subjects(idx),options.exclusions) == 0
        disp(sprintf('\nLoading subject %g fMRI data',options.subjects(idx)))
        %get data directory and preallocate file data array
        subj_dir = fullfile(options.SPMdata_dir,[options.SPMsubj_dir num2str(options.subjects(idx))]);
        file_data = cell(numel(options.runfolders),1); %preall cell array for load_fmridata
        %Load in scans
        for runidx = 1:numel(options.runfolders)
            my_files = prepare_fp(options,subj_dir,options.runfolders{runidx},options.scan_ft); %get filenames
            file_data{runidx} = load_fmridata(my_files,options); %load data
        end
        file_data = cat(4,file_data{:}); % cat data into matrix
        current_searchlight{idx} = apply_mask2data(searchlight_inds,file_data);
    end
end

CVbeh_data = cell(size(subject_behavioral_data));

for subject_idx = 1:sum(valid_subs) %all exclusions already taken care of
    CVbeh_data(subject_idx,:) = subject_behavioral_data(subject_idx,:); %pass behavioral data
    run_index = make_runindex(options); %make run index
    data_matrix = current_searchlight{subject_idx};
    data_matrix = HDRlag(options,data_matrix,run_index); %lag data, average over window (if specified)
    data_matrix = clean_endrun_trials(data_matrix,trials2cut,subject_idx);%remove trials without proper fmri data
    [data_matrix,CVbeh_data{subject_idx}] = select_trials(data_matrix,CVbeh_data{subject_idx});%select trials
    %normalization/termporal compression
    switch options.trial_temporal_compression
        case 'on'
            [data_matrix,CVbeh_data{subject_idx}] = temporal_compression(data_matrix,CVbeh_data{subject_idx},options);
        case 'off'
            %data_matrix = zscore(data_matrix); %normalize subject-wise
    end
    current_searchlight{subject_idx} = data_matrix;
end
%save('testerSL','current_searchlight')

%set up inds for leave out CV scheme
subject_inds = options.subjects(valid_subs)'; %kick out exclusions so dims match below
subject_inds = match_subinds2data(subject_inds,current_searchlight); %make subject inds match the data (num scans etc)
CVbeh_data = cell2mat(CVbeh_data); %now everything can be a matrix
current_searchlight = cell2mat(current_searchlight); %now everything can be a matrix
current_searchlight = zscore(current_searchlight); %!!!!normalize across "conditions"!!!!

%8. cross validate (can add behavior loop here)
cv_guesses = cell(numel(subs2LO(1,:)),1);
for test_sub_combo = 1:numel(subs2LO(1,:))
    cv_params = struct();%initialize stucture for parfor loop
    %subject logicals
    testing_subject = subs2LO(:,test_sub_combo);
    training_subjects = ~ismember(subject_inds,testing_subject);
    testing_subject = ~training_subjects; %just to make it explicit
    %data and labels
    training_data = current_searchlight(training_subjects,:);
    testing_data = current_searchlight(testing_subject,:);
    training_labels = CVbeh_data(training_subjects);
    testing_labels = CVbeh_data(testing_subject);
    [testing_data,testing_labels] = select_trials(testing_data,testing_labels);
    [training_data,training_labels] = select_trials(training_data,training_labels);
    switch options.feature_selection
        case 'off'
            cv_params.fe_testing_data = testing_data; %put data straight into fe_x, avoid duplicating data matricies
            cv_params.fe_training_data = training_data;
        case 'pca_only'
            %1a. make cv_params struct for pca_kmeans function
            cv_params.testing_data = testing_data;
            cv_params.training_data = training_data;
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
    cv_guesses{test_sub_combo} = options.classifier_type(cv_params,options);
end
cv_guesses = vertcat(cv_guesses{:});


for idx = 1:numel(options.roi_list)
    roi_pred = (sum(cv_guesses(:,1) == cv_guesses(:,2))) / numel(cv_guesses(:,1));
    disp(sprintf('%s classification accuracy %.2f%% \n',options.rois4fig{idx},(roi_pred*100))) 
end









% 
% saved_searchlights = load('SLinds_1p5thr10');
% searchlight_inds = saved_searchlights.searchlight_inds;
% seed_inds = saved_searchlights.seed_inds;
% %save('SLinds_1p5thr10','searchlight_inds','seed_inds')

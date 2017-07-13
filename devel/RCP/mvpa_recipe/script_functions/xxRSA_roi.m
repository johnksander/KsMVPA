function RSAoutput = xxRSA_roi(subject_file_pointers,options)

%07/10/2017: This script function is retired. Using it
%with MVPA_GNB_SL_bigmem() to create new script function. Doing this to
%ensure everything's compatible with most recently run toolbox
%configuration. 



%GOALS:::
%   0. Initialize variables and load behavioral data
%   1. make hypothesis matrix
%   3. load brain data & assemble RDM
%   4. Test RDM

%0. Initialize variables
subject_behavioral_data = cell(numel(options.subjects),numel(options.behavioral_file_list));
roiRDMs = cell(1,numel(options.roi_list));
p_values = NaN(1,numel(options.roi_list));
CIs = NaN(2,numel(options.roi_list));
hyp_similarity = NaN(1,numel(options.roi_list));
%load all behavioral data for all subjs
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


%1. hypothesis matrix
Hmat = options.subjects(~ismember(options.subjects,options.exclusions)); %kick out exclusions at the beginning
Hmat(Hmat < 200) = 1;
Hmat(Hmat > 200) = 2;
Hmat = Hmat' * Hmat;
Hmat(Hmat ~= 2) = 1; %similar (within group)
Hmat(Hmat == 2) = 0; %dissimilar
%note, 1 = similar here because we're not doing "disimilarity matricies", just similarity matricies

%alternate hypotheses
%Hmat(Hmat ~= 1) = 0;
%-------
%Hmat(Hmat == 4) = 0;
%Hmat(Hmat == 2) = .5;  

%Begin loops
fprintf(':::RSA data:::\r')
for roi_idx = 1:numel(options.roi_list)
    subject_brain_data = cell(numel(options.subjects),1);
    roi_subject_trials = cell(size(subject_behavioral_data));
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
                case 'off'
                    [lagged_data,roi_subject_trials{subject_idx}] = select_trials(lagged_data,subject_behavioral_data{subject_idx});
            end
            
            
            subject_brain_data{subject_idx} = lagged_data; %return data to brain data array
            
            
            
            %subject_brain_data{subject_idx} = zscore(lagged_data); %NEED TO NORMALIZE EACH SUBJECT!!!
            %09/07/15: across run normalization for each roi added to preallocate searchlight rois function (shouldn't normalize after lagging anyways, extra filler TR data added in lagging procedure)
            %10/7/15: on second thought, data was normalizedrun-wise in preprocessing- we'll need to normalize whole subject data here (takes care of train-to-test normalization
            %11/2/15: subject-wise normalization removed from preprocess (preallocate) searchlight rois function. This is taken care of here before lagging
            
            
        end
    end
    
   keyboard
    %04/08/15: setting curr_num_centroids moved to pca_kmeans function
    
    for beh_idx = 1:numel(options.behavioral_file_list) %Cycle through valence levels, performing classification on each
        curr_behavioral_data = subject_behavioral_data(:,beh_idx);
        %disp(sprintf('roi #%i: classifying subjects for behavior level #%i ',roi_idx,beh_idx))
        
        brain_data = cell2mat(subject_brain_data);
        switch options.feature_selection
            case 'pca_only'
                brain_data = RSA_pca(brain_data,options);
        end
        RDM = RSA_constructRDM(brain_data,options);
        %make a figure
        figure(roi_idx)
        figRDM = RDM;
        figRDM(logical(eye(size(figRDM)))) = 0;
        imagesc(figRDM)
        title(options.rois4fig{roi_idx})
        roiRDMs{roi_idx} = figRDM; %store for output
        %now do an actual analysis 
        RDM = RDM(~logical(eye(size(RDM))));
        RDM = atanh(RDM);
        testHmat = Hmat(~logical(eye(size(Hmat))));
        result = corr(RDM,testHmat,'type','Spearman');
        disp(sprintf('roi: %s, spearman-to-hypothesis = %.3f',options.rois4fig{roi_idx},result));
        %do statistics
        num_perms = 1;
        ci_range = 90;
        nulldist = NaN(num_perms,1);
        rng('shuffle')
        for permidx = 1:num_perms
            if mod(permidx,1000) == 0;disp(sprintf('permutation %i/%i',permidx,num_perms));end
            pMat = randperm(numel(testHmat))';
            pMat = testHmat(pMat);
            nulldist(permidx) = corr(RDM,pMat,'type','Spearman');
        end
        p_values(roi_idx) = (sum(nulldist > result) + 1) ./ (num_perms + 1); %adjust for 0 p-values
        ci_low = 50 - ci_range/2;
        ci_high = 100 - ci_low;
        CIs(:,roi_idx) = cat(1,prctile(nulldist,ci_low),prctile(nulldist,ci_high));
        hyp_similarity(roi_idx) = result;
    end
end

RSAoutput.roiRDMs = roiRDMs;
RSAoutput.Hmat = Hmat;
RSAoutput.hyp_similarity = hyp_similarity;
RSAoutput.p_values = p_values;
RSAoutput.CIs = CIs;





        
        
%         
%         %subjects already excluded, don't need if statment here
%         cv_params = struct();%initialize stucture for parfor loop
%         testing_subjects = twofold_combos(:,test_sub_combo);
%         training_subjects = ~ismember(subject_inds,testing_subjects) & ~isnan(subject_inds); %protect against exclusions
%         testing_subjects = ismember(subject_inds,testing_subjects);
%         training_data = subject_brain_data; %prevent subject_brain_data from broadcasting
%         training_data = cell2mat(training_data(training_subjects));
%         testing_data = subject_brain_data; %prevent subject_brain_data from broadcasting
%         testing_data = cell2mat(testing_data(testing_subjects));
%         testing_labels = cell2mat(true_labels(testing_subjects)); %give true label to testing subjects
%         training_labels = cell2mat(permd_labels(training_subjects)); %give permuted labels to training subjects
%         [testing_data,testing_labels] = select_trials(testing_data,testing_labels);
%         [training_data,training_labels] = select_trials(training_data,training_labels);
%         
%         
%         
%         parfor test_sub_combo = 1:numel(L2Ocombos(1,:))
%             %subjects already excluded, don't need if statment here
%             %put everything into matricies beforehand, just so I can be cautious with indexing (logicial vectors are a diff size)
%             training_data = subject_brain_data; %prevent subject_brain_data from broadcasting
%             testing_data = cell2mat(training_data); %avoid doubling up on the matrix here, just use the training data
%             training_data = cell2mat(training_data);
%             testing_labels = cell2mat(curr_behavioral_data);
%             training_labels = cell2mat(curr_behavioral_data);
%             %ok now do cv loop
%             cv_params = struct();%initialize stucture for parfor loop
%             testing_subject = L2Ocombos(:,test_sub_combo);
%             training_subjects = ~ismember(subject_inds,testing_subject);
%             testing_subject = ~training_subjects; %just to make it explicit
%             training_data = training_data(training_subjects,:);
%             testing_data = testing_data(testing_subject,:);
%             testing_labels = testing_labels(testing_subject);
%             training_labels = training_labels(training_subjects);
%             [testing_data,testing_labels] = select_trials(testing_data,testing_labels);
%             [training_data,training_labels] = select_trials(training_data,training_labels);
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
%             predictions{test_sub_combo,roi_idx,beh_idx} = cv_guesses;

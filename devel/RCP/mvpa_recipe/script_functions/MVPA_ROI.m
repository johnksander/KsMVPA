function predictions = MVPA_ROI(subject_file_pointers,options)

%10/15/2017:
%This was adapted from LOSO_roi_mvpa(), since mvpa() was suuuper depreciated.

%GOALS:::
%   0. Initialize variables and load behavioral data
%   1. Feature select
%   2. Fit models
%   3. Predict/decode

%0. Initialize variables
predictions = cell(numel(options.subjects),numel(options.roi_list),numel(options.behavioral_file_list));
trials2cut = find_endrun_trials(options); %find behavioral trials without proper fmri data
switch options.CVscheme
    case 'none'
        CV.testing_runs = options.ret_runs';
        CV.training_runs = options.enc_runs';
        CV.kfolds = numel(CV.testing_runs(1,:));
    case 'oddeven'
        CV.testing_runs = [options.ret_runs(1:2:end)',options.ret_runs(2:2:end)'];
        CV.testing_runs = [CV.testing_runs,fliplr(CV.testing_runs)];
        CV.training_runs = [options.enc_runs(1:2:end)',options.enc_runs(2:2:end)'];
        CV.training_runs = [CV.training_runs,CV.training_runs]; %could put this in like, CVruns.train & CVruns.test
        CV.kfolds = numel(CV.testing_runs(1,:));
    case 'TwoOut'
        subs2LO = options.subjects(valid_subs); %cross validation indicies
        subs2LO = {subs2LO(subs2LO < 200), subs2LO(subs2LO > 200)};
        subs2LO = combvec(subs2LO{1},subs2LO{2});
    case 'OneOut'
        subs2LO = options.subjects(valid_subs); %cross validation indicies
end
output_log = fullfile(options.save_dir,'output_log.txt');
special_progress_tracker = fullfile(options.save_dir,'SPT.txt');
%1a. load behavioral data
subject_behavioral_data = cell(numel(options.subjects),numel(options.behavioral_file_list));
subject_run_index = cell(numel(options.subjects),numel(options.behavioral_file_list));
%stim order isn't needed here
%subject_stim_order = cell(numel(options.subjects),1);
for idx = 1:numel(options.subjects)
    if ~ismember(options.subjects(idx),options.exclusions)
        for beh_idx = 1:numel(options.behavioral_file_list),
            BehFname = [options.behavioral_file_list{beh_idx} '_' num2str(options.subjects(idx)) '.txt'];
            my_files = prepare_fp(options,options.TRfile_dir,BehFname);
            beh_matrix = load_behav_data(my_files,options);
            trialtype_matrix = NaN(size(beh_matrix(:,4))); %this shoudld've always been up here... repetitive down there
            %stim_order = NaN(size(beh_matrix(:,8))); %always going to be the 8th column in these TR files
            switch options.behavioral_transformation %hardcoding this sorta
                case 'Rmemory_retrieval'
                    retrieval_trials = ismember(beh_matrix(:,3),options.ret_runs) & ~isnan(beh_matrix(:,4));
                    correctRtrials = beh_matrix(:,5) == 1 & beh_matrix(:,6) == 1; %only correct "remember" responses
                    trialtype_matrix(retrieval_trials & correctRtrials) = ...
                        beh_matrix(retrieval_trials & correctRtrials,4); %take valence for retrieval R trials
                    %                     stim_order(retrieval_trials & correctRtrials) = ...
                    %                         beh_matrix(retrieval_trials & correctRtrials,8);
                case 'encoding_valence'
                    encoding_trials = ismember(beh_matrix(:,3),options.enc_runs) & ~isnan(beh_matrix(:,4));
                    trialtype_matrix(encoding_trials) = beh_matrix(encoding_trials,4); %only take valence ratings during encoding
                    %stim_order(encoding_trials) = beh_matrix(encoding_trials,8); %not sure I'd ever need this...
                case 'retrieval_valence'
                    retrieval_trials = ismember(beh_matrix(:,3),options.ret_runs) & ~isnan(beh_matrix(:,4));
                    retrieval_lures = ismember(beh_matrix(:,3),options.ret_runs) & beh_matrix(:,4) == 0;
                    trialtype_matrix(retrieval_trials) = beh_matrix(retrieval_trials,4); %only take valence ratings during encoding
                    %stim_order(retrieval_trials) = beh_matrix(retrieval_trials,8);
                    %think about whether you want to include lures in valence RDM at all (or coded back in as neutral trials)
                    trialtype_matrix(retrieval_lures) = NaN; %they don't have a memory component, pretty different I'm excluding
                    %stim_order(retrieval_lures) = NaN; %they're already nans in the TR file, but just for consistency..
                case 'enc2ret_valence'
                    %take all encoding valence
                    encoding_trials = ismember(beh_matrix(:,3),options.enc_runs) & ~isnan(beh_matrix(:,4));
                    trialtype_matrix(encoding_trials) = beh_matrix(encoding_trials,4); %only take valence ratings during encoding
                    %take retrieval target valence
                    retrieval_trials = ismember(beh_matrix(:,3),options.ret_runs) & ~isnan(beh_matrix(:,4));
                    retrieval_lures = ismember(beh_matrix(:,3),options.ret_runs) & beh_matrix(:,4) == 0;
                    trialtype_matrix(retrieval_trials) = beh_matrix(retrieval_trials,4); %only take valence ratings during encoding
                    %think about whether you want to include lures in valence RDM at all (or coded back in as neutral trials)
                    trialtype_matrix(retrieval_lures) = NaN; %they don't have a memory component, pretty different I'm excluding
                    
            end
            
            switch options.treat_special_stimuli %special treatment...
                case 'faces_and_scenes'
                    special_trials = beh_matrix(:,7);
                    special_trials(special_trials == 2) = -1; %make scene trials a neg val
                    trialtype_matrix(~isnan(trialtype_matrix)) = ...
                        trialtype_matrix(~isnan(trialtype_matrix)) .* special_trials(~isnan(trialtype_matrix));
                    %now all the scenes are negative, faces are positive.
                    %Temporal compression functions will treat them seperately
            end
            
            %remove behavioral trials without proper fmri data
            trialtype_matrix = clean_endrun_trials(trialtype_matrix,trials2cut,idx); %remove behavioral trials without proper fmri data
            %stim_order = clean_endrun_trials(stim_order,trials2cut,idx);
            %store treated behavioral data
            subject_behavioral_data{idx,beh_idx} = trialtype_matrix; %subject_behavioral data NOT to be altered after this point
            %subject_stim_order{idx} = stim_order;
            subject_run_index{idx,beh_idx} = beh_matrix(:,3); %store subject run index for all trials
        end
    end
end
%clear stim_order %just to b safe..


%Begin loops
update_logfile(':::ROI MVPA:::\n',output_log)

for roi_idx = 1:numel(options.roi_list)
    %subject_brain_data = cell(numel(options.subjects),1);
    message = sprintf('loading brain data for roi #%i %s',roi_idx,options.rois4fig{roi_idx});
    update_logfile(message,output_log)
    
    %load all brain data
    for subject_idx = 1:numel(options.subjects)
        if ~ismember(options.subjects(subject_idx),options.exclusions)
            
            update_logfile(['starting subject # ' num2str(options.subjects(subject_idx))],output_log)
            %---load/pass subject data
            CVbeh_data = subject_behavioral_data{subject_idx};  %pass behavioral data
            run_index = subject_run_index{subject_idx}; %get run index
            brain_data = load(subject_file_pointers{subject_idx,roi_idx}); %load preprocessed fmri data (valid voxels already determined)
            brain_data = brain_data.data_matrix;
            %---select trials
            trial_selector = ~isnan(CVbeh_data); %this is replacing select_trials()
            brain_data = brain_data(trial_selector,:); %brain
            run_index = run_index(trial_selector); %run index
            CVbeh_data = CVbeh_data(trial_selector); %behavior/trial labels
            %---treat the brain data as needed...
            brain_data = remove_badvoxels(brain_data);
            %data_matrix = HDRlag(options,data_matrix,run_index); %lag data, average over window (if specified)
            %07/20/2016: lag data is disabled for this script, use HDR modeled data
            %would need to clean end run trials from fmri data here
            %data_matrix = clean_endrun_trials(data_matrix,trials2cut,subject_idx);%remove trials without proper fmri data
            %searchlight_brain_data = searchlight_brain_data(~trials2cut(:,subject_idx),:,:); %adapted from clean_endrun_trials() for this script
            %run_index = clean_endrun_trials(run_index,trials2cut,subject_idx); %match run index to cleaned behavioral data
            %normalization/termporal compression
            switch options.normalization
                case 'runwise'
                    brain_data = cocktail_blank_normalize(brain_data,run_index);
                    update_logfile('Data matrix set to zero mean & unit variance: run wise',output_log)
                case 'off'
                    update_logfile('WARNING: skipping cocktail blank removal',output_log)
            end
            switch options.trial_temporal_compression
                case 'on'
                    [brain_data,CVbeh_data{subject_idx}] = temporal_compression(brain_data,CVbeh_data{subject_idx},options);
                case 'runwise'
                    run_index = clean_endrun_trials(run_index,trials2cut,subject_idx);%match run index to valid fmri trials
                    [brain_data,CVbeh_data{subject_idx}] = temporal_compression_runwise(brain_data,CVbeh_data{subject_idx},run_index);
                case 'off'
                    %nada
            end
            
            
            cv_guesses = cell(CV.kfolds,1);
            for fold_idx = 1:CV.kfolds %CV folds
                %run logicals
                testing_logical = ismember(run_index,CV.testing_runs(:,fold_idx));
                training_logical = ismember(run_index,CV.training_runs(:,fold_idx));
                %class labels
                training_labels = CVbeh_data(training_logical);
                testing_labels = CVbeh_data(testing_logical);
                %data splits
                training_data = brain_data(training_logical,:);
                testing_data = brain_data(testing_logical,:);
                %classify
                cv_params = struct();
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
                cv_guesses{fold_idx} = options.classifier_type(cv_params,options);
                
                switch options.parforlog %parfor progress tracking
                    case 'on'
                        txtappend(special_progress_tracker,'1\n')
                        SPT_fid = fopen(special_progress_tracker,'r');
                        progress = fscanf(SPT_fid,'%i');
                        fclose(SPT_fid);
                        if mod(sum(progress),floor(numel(subs2LO(1,:)) * .01)) == 0 %1 percent
                            progress = (sum(progress) /  numel(subs2LO(1,:))) * 100;
                            message = sprintf('Searchlight GNB %.1f percent complete',progress);
                            update_logfile(message,output_log)
                        end
                end
            end%CV loop
            cv_guesses = cat(2,cv_guesses{:});
            predictions{subject_idx,roi_idx,beh_idx} = cv_guesses;
        end
    end
end



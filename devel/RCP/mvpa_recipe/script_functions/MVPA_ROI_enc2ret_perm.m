function MVPA_ROI_enc2ret_perm(subject_file_pointers,options)

%10/15/2017:
%This was adapted from LOSO_roi_mvpa(), since mvpa() was suuuper depreciated.
%05/31/2018:
%I made this it's own thing from MVPA_ROI() because of how that script
%handles the ROI loop. I figured this is a more specific instance, not
%worth making the other overly complicated..


%GOALS:::
%   0. Initialize variables and load behavioral data
%   1. Feature select
%   2. Fit models
%   3. Predict/decode

%0. Initialize variables
encROI_fn = cellfun(@(x) ~isempty(strfind(x,'encoding')),options.roi_list);
retROI_fn = cellfun(@(x) ~isempty(strfind(x,'retrieval')),options.roi_list);
if sum(encROI_fn) < 1 || sum(retROI_fn) < 1 || sum(encROI_fn) ~= sum(retROI_fn)
    error('specify encoding/retrieval ROI pair with filenames')
elseif all((encROI_fn + retROI_fn) ~= ones(size(options.roi_list))) || find(retROI_fn) < find(encROI_fn)
    error('specify encoding/retrieval ROIs in sequential pairs')
elseif sum(encROI_fn) ~= 1 || sum(retROI_fn) ~= 1
    error('dude just do one pair at a time... make it easy on yourself')
end
%ordered_ROIfns = num2cell([find(encROI),find(retROI)],2);
%ROIpairs = cellfun(@(x) options.roi_list(x),ordered_ROIfns,'Uniformoutput',false);
output_dir = fullfile(options.save_dir,'files'); %make new sub-directory for output files
if ~isdir(output_dir),mkdir(output_dir);end
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
for idx = 1:numel(options.subjects)
    if ~ismember(options.subjects(idx),options.exclusions)
        for beh_idx = 1:numel(options.behavioral_file_list),
            BehFname = [options.behavioral_file_list{beh_idx} '_' num2str(options.subjects(idx)) '.txt'];
            my_files = prepare_fp(options,options.TRfile_dir,BehFname);
            beh_matrix = load_behav_data(my_files,options);
            trialtype_matrix = NaN(size(beh_matrix(:,4))); %this shoudld've always been up here... repetitive down there
            switch options.behavioral_transformation %hardcoding this sorta
                case 'Rmemory_retrieval'
                    retrieval_trials = ismember(beh_matrix(:,3),options.ret_runs) & ~isnan(beh_matrix(:,4));
                    correctRtrials = beh_matrix(:,5) == 1 & beh_matrix(:,6) == 1; %only correct "remember" responses
                    trialtype_matrix(retrieval_trials & correctRtrials) = ...
                        beh_matrix(retrieval_trials & correctRtrials,4); %take valence for retrieval R trials
                case 'encoding_valence'
                    encoding_trials = ismember(beh_matrix(:,3),options.enc_runs) & ~isnan(beh_matrix(:,4));
                    trialtype_matrix(encoding_trials) = beh_matrix(encoding_trials,4); %only take valence ratings during encoding
                case 'retrieval_valence'
                    retrieval_trials = ismember(beh_matrix(:,3),options.ret_runs) & ~isnan(beh_matrix(:,4));
                    retrieval_lures = ismember(beh_matrix(:,3),options.ret_runs) & beh_matrix(:,4) == 0;
                    trialtype_matrix(retrieval_trials) = beh_matrix(retrieval_trials,4); %only take valence ratings during encoding
                    %stim_order(retrieval_trials) = beh_matrix(retrieval_trials,8);
                    %think about whether you want to include lures in valence RDM at all (or coded back in as neutral trials)
                    trialtype_matrix(retrieval_lures) = NaN; %they don't have a memory component, pretty different I'm excluding
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
            %store treated behavioral data
            subject_behavioral_data{idx,beh_idx} = trialtype_matrix; %subject_behavioral data NOT to be altered after this point
            subject_run_index{idx,beh_idx} = beh_matrix(:,3); %store subject run index for all trials
        end
    end
end

%Begin loops
update_logfile(':::ROI MVPA permutation testing:::\n',output_log)



%load all brain data
for subject_idx = 1:numel(options.subjects)
    if ~ismember(options.subjects(subject_idx),options.exclusions)
        update_logfile(['\nstarting subject # ' num2str(options.subjects(subject_idx))],output_log)
        update_logfile('----------------------',output_log)
        brain_data = cell(size(options.roi_list));
        for roi_idx = 1:numel(options.roi_list)
            %subject_brain_data = cell(numel(options.subjects),1);
            message = sprintf('loading brain data for roi #%i %s',roi_idx,options.rois4fig{roi_idx});
            update_logfile(message,output_log)
            %---load/pass subject data
            %note: CVbeh_data & run_index are processed twice here, but reloaded each time
            %with the same subject index. This might look dodgy but it's fine
            %each time they're reloaded the same thing happens- output is the same
            CVbeh_data = subject_behavioral_data{subject_idx};  %pass behavioral data
            run_index = subject_run_index{subject_idx}; %get run index
            ROIdata = load(subject_file_pointers{subject_idx,roi_idx}); %load preprocessed fmri data (valid voxels already determined)
            ROIdata = ROIdata.data_matrix;
            %---select trials
            trial_selector = ~isnan(CVbeh_data); %this is replacing select_trials()
            ROIdata = ROIdata(trial_selector,:); %brain
            run_index = run_index(trial_selector); %run index
            CVbeh_data = CVbeh_data(trial_selector); %behavior/trial labels
            %---treat the brain data as needed...
            ROIdata = remove_badvoxels(ROIdata);
            %data_matrix = HDRlag(options,data_matrix,run_index); %lag data, average over window (if specified)
            %07/20/2016: lag data is disabled for this script, use HDR modeled data
            %would need to clean end run trials from fmri data here
            %data_matrix = clean_endrun_trials(data_matrix,trials2cut,subject_idx);%remove trials without proper fmri data
            %searchlight_brain_data = searchlight_brain_data(~trials2cut(:,subject_idx),:,:); %adapted from clean_endrun_trials() for this script
            %run_index = clean_endrun_trials(run_index,trials2cut,subject_idx); %match run index to cleaned behavioral data
            %normalization/termporal compression
            switch options.normalization
                case 'runwise'
                    ROIdata = cocktail_blank_normalize(ROIdata,run_index);
                    update_logfile('Data matrix set to zero mean & unit variance: run wise',output_log)
                case 'off'
                    update_logfile('WARNING: skipping cocktail blank removal',output_log)
            end
            switch options.trial_temporal_compression
                case 'on'
                    [ROIdata,CVbeh_data{subject_idx}] = temporal_compression(ROIdata,CVbeh_data{subject_idx},options);
                case 'runwise'
                    run_index = clean_endrun_trials(run_index,trials2cut,subject_idx);%match run index to valid fmri trials
                    [ROIdata,CVbeh_data{subject_idx}] = temporal_compression_runwise(ROIdata,CVbeh_data{subject_idx},run_index);
                case 'off'
                    %nada
            end
            
            brain_data{roi_idx} = ROIdata;
        end
        
        %must permute the data within encoding & retrieval sets
        %so, prepare the permuted labeleing ahead of time (not just the ordering)
        permCVbeh_data = enc2ret_permuting(CVbeh_data,run_index,options);
        %initialize results matrix
        permuted_results = NaN(options.num_perms,1);
        
        encROI_data = brain_data{encROI_fn};
        retROI_data = brain_data{retROI_fn};
        
        cv_accuracy = cell(CV.kfolds,1);
        for fold_idx = 1:CV.kfolds %CV folds
            %run logicals
            testing_logical = ismember(run_index,CV.testing_runs(:,fold_idx));
            training_logical = ismember(run_index,CV.training_runs(:,fold_idx));
            %class labels, take from permuted label matrix
            training_labels = permCVbeh_data(training_logical,:);
            testing_labels = permCVbeh_data(testing_logical,:);
            %data splits
            training_data = encROI_data(training_logical,:); %train on encoding ROI data
            testing_data = retROI_data(testing_logical,:); %test on retrieval ROI data
            %classify with permuted labelings
            parfor permidx = 1:options.num_perms
                cv_params = struct();
                %cv_params.testing_data = testing_data;
                %cv_params.training_data = training_data; %no need to double-up the data here
                switch options.feature_selection
                    case 'martinez PCA'
                        [cv_params.fe_training_data,Einfo] =... %training
                            martinez_pca(training_data,options.PCAcomponents2keep);
                        [cv_params.fe_testing_data,Rinfo] = ... %testing
                            martinez_pca(testing_data,options.PCAcomponents2keep);
                        
                        message = sprintf(['martinez PCA:/n----encoding var retained = %.2f percent'...
                            '/n----retrieval var retained = %.2f percent'],...
                            Einfo.variancePercent,Rinfo.variancePercent);
                        update_logfile(message,output_log)
                    otherwise
                        cv_params.fe_training_data = training_data;
                        cv_params.fe_testing_data = testing_data;
                end
                %[cv_params.fe_training_data, cv_params.fe_testing_data] = pca_only(cv_params,options);
                %1b. Feature select based on training data
                %                 [wd,M,P] = zca_whiten(training_data,options.lambda);
                %                 trained_centroids = runkmeans(wd,curr_num_centroids,options.k_iterations);
                %                 fe_training_data = extract_brain_features(training_data,trained_centroids,M,P);
                %                 fe_testing_data = extract_brain_features(testing_data,trained_centroids,M,P);
                %2a. make cv_params struct for classifier function
                %                 cv_params.fe_training_data = fe_training_data;
                %                 cv_params.fe_testing_data = fe_testing_data;
                cv_params.training_labels = training_labels(:,permidx);
                cv_params.testing_labels = testing_labels(:,permidx);
                %2b. Insert classifier
                predictions = options.classifier_type(cv_params,options);
                %   11. store CV accuracy
                permuted_results(permidx) = ...
                    sum(predictions(:,1) == predictions(:,2)) / numel(predictions(:,1));
            end
            
            cv_accuracy{fold_idx} = permuted_results;
            
        end%CV loop
        cv_accuracy = cat(2,cv_accuracy{:});
        
        update_logfile('Saving permutation results',output_log)
        %save the ROI null distributions into seperate files
        output_fn = sprintf('subject_%i_ROInull.mat',options.subjects(subject_idx));
        save(fullfile(output_dir,output_fn),'cv_accuracy');
    end
end




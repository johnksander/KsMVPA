function searchlight_cells = MVPA_ROI2searchlight(options)

%Special script for encoding-to-retrieval analysis. Loads ROI mask from
%significant searchlight cluster ROIs at encoding, uses that as training
%data. Testing data is whole-brain searchlight.

%GOALS:::
%   0. Initialize variables
%   1. load data: behavior
%   2. load data: ROI masks from encoding data
%   3. map searchlight indicies
%   4. loop through subjects
%   5. load searchlight brain data & pass subject trial info
%   6a. loop through encding ROIs & treat fmri data
%   6b. create sliceable searchlight data matrix & treat fmri data
%   7. set up cross validation
%   8a. PCA feature selection & LDA training: encoding ROIs
%   8b. PCA feature selection: searchlight matrix
%   9. slice searchlights & classify
%   10. store CV accuracy


%0. Initialize variables
searchlight_cells = cell(numel(options.subjects),numel(options.roi_list));
vol_size = options.scan_vol_size; %just make var name easier
trials2cut = find_endrun_trials(options); %find behavioral trials without proper fmri data
subject_fmri_filepointers = load(fullfile(options.preproc_data_dir,'preproc_data_file_pointers'));
subject_fmri_filepointers = subject_fmri_filepointers.preproc_data_file_pointers;

output_log = fullfile(options.save_dir,'output_log.txt');
special_progress_tracker = fullfile(options.save_dir,'SPT.txt');
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
end

%warnings because this script doesn't jive with the toolbox
if options.remove_endrun_trials ~= 0
    update_logfile('WARNING: NOT CONFIGURED FOR REMOVING ENDRUN DATA',output_log)
end
if options.TR_delay > 0 | options.TR_avg_window > 0
    update_logfile('WARNING: NOT CONFIGURED FOR DATA LAGGING OR TR AVERAGING',output_log)
end


%   1. load data: behavior
subject_behavioral_data = cell(numel(options.subjects),numel(options.behavioral_file_list));
subject_run_index = cell(numel(options.subjects),numel(options.behavioral_file_list));
for idx = 1:numel(options.subjects)
    if ismember(options.subjects(idx),options.exclusions) == 1
        %Don't do anything
    else
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
            trialtype_matrix = clean_endrun_trials(trialtype_matrix,trials2cut,idx); %remove behavioral trials without proper fmri data
            subject_behavioral_data{idx,beh_idx} = trialtype_matrix; %subject_behavioral data NOT to be altered after this point
            subject_run_index{idx,beh_idx} = beh_matrix(:,3); %store subject run index for all trials
        end
    end
end


%   2. load data: ROI masks from encoding data
update_logfile('loading ROI masks from encoding',output_log)
encdir = fullfile(options.home_dir,'Results','%s_stats','enc2ret_data');
encdir = sprintf(encdir,options.enc_job);
mask_data = spm_read_vols(spm_vol(fullfile(encdir,'results_mask.nii')));
mask_data = logical(mask_data);
num_encROIs = size(mask_data,4);
if [size(mask_data,1),size(mask_data,2),size(mask_data,3)] ~= vol_size
    error('INCORRECT VOLUME SIZE')
end
update_logfile(sprintf('----Encoding ROIs found: %i',num_encROIs),output_log)

%Begin loops
update_logfile(':::Starting ROI-to-searchlight MVPA:::',output_log)
for roi_idx = 1:numel(options.roi_list)
    message = sprintf('ROI: %s\n',options.rois4fig{roi_idx});
    update_logfile(message,output_log)
    %3. map searchlight indicies
    update_logfile('Finding searchlight indicies',output_log)
    %--- Precalculate searchlight indices
    commonvox_maskdata = fullfile(options.preproc_data_dir,['commonvox_' options.roi_list{roi_idx}]);
    commonvox_maskdata =  spm_read_vols(spm_vol(commonvox_maskdata));
    [searchlight_inds,seed_inds] = preallocate_searchlights(commonvox_maskdata,options.searchlight_radius); %grow searchlight sphere @ every included voxel
    %        searchlight_inds = load('SLinds_1p5thr10.mat'); %just for debugging
    %        seed_inds = searchlight_inds.seed_inds;
    %        searchlight_inds = searchlight_inds.searchlight_inds;
    update_logfile('Searchlight indexing complete',output_log)
    update_logfile(['----Total valid searchlights: ' num2str(numel(seed_inds))],output_log)
    %4. loop through subjects
    for subject_idx = 1:numel(options.subjects)
        if ismember(options.subjects(subject_idx),options.exclusions) == 0
            if exist(special_progress_tracker) > 0
                delete(special_progress_tracker) %fresh start for new subject
            end
            update_logfile(['starting subject # ' num2str(options.subjects(subject_idx))],output_log)
            %   5. load searchlight brain data & pass subject trial info
            update_logfile('loading whole-brain data',output_log)
            %---load/pass subject data
            CVbeh_data = subject_behavioral_data{subject_idx};  %pass behavioral data
            run_index = subject_run_index{subject_idx}; %get run index
            searchlight_brain_data = load(subject_fmri_filepointers{subject_idx}); %load preprocessed fmri data (valid voxels already determined)
            searchlight_brain_data = searchlight_brain_data.preprocessed_scans;
            %---select trials
            trial_selector = ~isnan(CVbeh_data); %this is replacing select_trials()
            searchlight_brain_data = searchlight_brain_data(:,:,:,trial_selector); %brain
            CVbeh_data = CVbeh_data(trial_selector); %behavior/trial labels
            run_index = run_index(trial_selector); %run index
            %6a. loop through encding ROIs & treat data
            encROIs = cell(num_encROIs,1);
            for enc_idx = 1:num_encROIs
                message = sprintf('----treating data for encoding ROI #%i/%i',enc_idx,num_encROIs);
                update_logfile(message,output_log)
                curr_mask = mask_data(:,:,:,enc_idx); %get mask data
                ROIdata = apply_mask2data(curr_mask,searchlight_brain_data); %mask fmri data
                switch options.normalization
                    case 'runwise'
                        ROIdata = cocktail_blank_normalize(ROIdata,run_index);
                        update_logfile('----data set to zero mean & unit variance: run wise',output_log)
                    case 'off'
                        update_logfile('WARNING: skipping cocktail blank removal',output_log)
                end
                switch options.trial_temporal_compression
                    case 'on'
                        error('not configured for temporal compression')
                        %this is gonna load & modify CVbeh_data every time... BIG time bug...
                        %[ROIdata,CVbeh_data] = temporal_compression(ROIdata,CVbeh_data,options);
                    case 'runwise'
                        error('not configured for runwise temporal compression')
                        %blow is gonna load & cut run index every time..
                        %run_index = clean_endrun_trials(run_index,trials2cut,subject_idx);%match run index to valid fmri trials
                        %[ROIdata,CVbeh_data] = temporal_compression_runwise(ROIdata,CVbeh_data,run_index);
                end
                message = sprintf('----ROI size check: %ix%i',size(ROIdata));
                update_logfile(message,output_log)
                
                encROIs{enc_idx} = ROIdata; %store it away
            end
            update_logfile('Creating searchlight matrix',output_log)
            %   6b. create sliceable searchlight data matrix & treat fmri data
            searchlight_brain_data = bigmem_searchlight_wrapper(searchlight_brain_data,vol_size,searchlight_inds); %sliceable searchlight matrix
            update_logfile('Searchlight matrix complete',output_log)
            %data_matrix = HDRlag(options,data_matrix,run_index); %lag data, average over window (if specified)
            %07/20/2016: lag data is disabled for this script, use HDR modeled data
            %would need to clean end run trials from fmri data here
            %data_matrix = clean_endrun_trials(data_matrix,trials2cut,subject_idx);%remove trials without proper fmri data
            %searchlight_brain_data = searchlight_brain_data(~trials2cut(:,subject_idx),:,:); %adapted from clean_endrun_trials() for this script
            %run_index = clean_endrun_trials(run_index,trials2cut,subject_idx); %match run index to cleaned behavioral data
            %normalization/termporal compression
            switch options.normalization
                case 'runwise'
                    searchlight_brain_data = normalize_SLmatrix(searchlight_brain_data,run_index);
                    update_logfile('Searchlight matrix set to zero mean & unit variance: run wise',output_log)
                case 'off'
                    update_logfile('WARNING: skipping cocktail blank removal',output_log)
            end
            switch options.trial_temporal_compression
                case 'on'
                    [xxx,CVbeh_data{subject_idx}] = GNBtemporal_compression(xxx,CVbeh_data{subject_idx},options);
                case 'runwise'
                    [xxx,CVbeh_data{subject_idx}] = GNB_Tcomp_runwise(xxx,CVbeh_data{subject_idx},run_index);
            end
            %   7. set up cross validation
            cv_correct = cell(1,CV.kfolds);
            cv_guesses = cell(1,CV.kfolds);
            
            for fold_idx = 1:CV.kfolds %CV folds
                %store CV accuracy
                searchlight_correct = NaN(numel(seed_inds),num_encROIs); %N correct label guesses for searchlight CV
                searchlight_guesses = NaN(numel(seed_inds),1); %N total label guesses for searchlight CV (same for every ROI)
                %run logicals
                training_logical = ismember(run_index,CV.training_runs(:,fold_idx));
                testing_logical = ismember(run_index,CV.testing_runs(:,fold_idx));
                %class labels
                training_labels = CVbeh_data(training_logical);
                testing_labels = CVbeh_data(testing_logical);
                %   8. Encoding ROI: PCA feature selection & LDA training
                update_logfile('PCA feature selection & LDA training: encoding ROIs',output_log)
                update_logfile(sprintf('----N PCs = %i',options.PCAcomponents2keep),output_log)
                ROI_models = cell(num_encROIs,1);
                for enc_idx = 1:num_encROIs
                    %select training data
                    training_data = encROIs{enc_idx};
                    training_data = training_data(training_logical,:);
                    %run PCA feature selection
                    [training_data, Minfo] = martinez_pca(training_data,options.PCAcomponents2keep);
                    message = sprintf('----ROI #%i/%i var retained = %.2f percent',...
                        enc_idx,num_encROIs,Minfo.variancePercent);
                    update_logfile(message,output_log)
                    %train LDA model on features
                    switch options.performance_stat
                        case 'accuracy' %nothing fancy or dumb
                            ROI_models{enc_idx} = fitcdiscr(training_data,training_labels,'Prior','uniform');
                        case 'oldMC' %the "old multiclass" scheme
                            ROI_models{enc_idx} = train_oldMC_LDA(training_data,training_labels);
                    end
                    
                end
                
                %   8b. PCA feature selection: searchlight matrix
                update_logfile('PCA feature selection & LDA training: searchlight matrix',output_log)
                update_logfile(sprintf('----N PCs = %i',options.PCAcomponents2keep),output_log)
                testing_searchlights = NaN(sum(testing_logical),options.PCAcomponents2keep,numel(seed_inds));
                for SL_idx = 1:numel(seed_inds) %use a different idx than parfor...
                    testing_searchlights(:,:,SL_idx) = ...
                        martinez_pca(searchlight_brain_data(testing_logical,:,SL_idx),...
                        options.PCAcomponents2keep);
                end
                update_logfile('----finished',output_log)
                update_logfile('Classifying searchlights',output_log)
                %   8. slice searchlights & classify
                Nguess = NaN; %should be the same for every searchlight, avoid many size calculations
                switch options.performance_stat
                    case 'accuracy'
                        testing_labels = repmat(testing_labels,1,num_encROIs);
                    case 'oldMC'
                        testing_labels = oldMC_label_matrix(testing_labels);
                        testing_labels = repmat(testing_labels,1,1,num_encROIs);
                        Nguess = sum(~isnan(testing_labels(:,:,1)));
                        Nguess = sum(Nguess); %number of guesses per ROI (same for every ROI..)
                end
                %pay attention! above I just expanded testing labels for
                %testing equality with prediction matrix. Keep in mind.
                parfor searchlight_idx = 1:numel(seed_inds)
                    
                    %get the current searchlight as testing data
                    testing_data = testing_searchlights(:,:,searchlight_idx);
                    %classify with each ROI
                    switch options.performance_stat
                        case 'accuracy'
                            predictions = NaN(sum(testing_logical),num_encROIs);
                            for enc_idx = 1:num_encROIs
                                predictions(:,enc_idx) = predict(ROI_models{enc_idx},testing_data);
                            end
                            %   9. store CV accuracy
                            searchlight_correct(searchlight_idx,:) = sum(predictions == testing_labels); %count number correct
                            searchlight_guesses(searchlight_idx) = numel(predictions(:,1)); %count number of guesses
                        case 'oldMC'
                            predictions = NaN(size(testing_labels)); %expanded to (labels x class x roi)
                            for enc_idx = 1:num_encROIs
                                predictions(:,:,enc_idx) = ...
                                    test_oldMC_LDA(ROI_models{enc_idx},testing_data,testing_labels(:,:,enc_idx));
                            end
                            %   9. store CV accuracy
                            searchlight_correct(searchlight_idx,:) = sum(sum(predictions == testing_labels),2);
                            searchlight_guesses(searchlight_idx) = Nguess;
                        case 'Fscore'
                            error('Fscore not implemented')
                    end
                    
                    switch options.parforlog %parfor progress tracking
                        case 'on'
                            progress = worker_progress_tracker(special_progress_tracker);
                            if mod(progress,floor(numel(seed_inds) * .2)) == 0 %at 20 percent
                                progress = (progress / numel(seed_inds)) * 100;
                                message = sprintf('----%.1f percent complete',progress);
                                update_logfile(message,output_log)
                            end
                    end
                end%searchlight loop
                %store CV accuracy
                cv_correct{fold_idx} = searchlight_correct;
                cv_guesses{fold_idx} = searchlight_guesses;
            end%CV loop
            
            cv_correct = cat(3,cv_correct{:}); %put CV in third dim
            cv_guesses = cat(2,cv_guesses{:}); %guesses constant across roi
            
            switch options.performance_stat
                case {'accuracy','oldMC'}
                    %mean accuracy across CV folds (total CV correct / total CV guesses)
                    cv_correct = sum(cv_correct,3); %sum across folds
                    cv_guesses = sum(cv_guesses,2);
                    searchlight_results = bsxfun(@rdivide,cv_correct,cv_guesses);
                case 'Fscore'
                    %searchlight_results = mean(cell2mat(cv_guesses),2); %take average F score across CV folds
            end
            if sum(isnan(searchlight_results(:))) > 0
                update_logfile('WARNING: PROBLEM WITH CV ACCURACY STORAGE',output_log)
            end
            searchlight_results = [seed_inds,searchlight_results]; %include results' searchlight seed location (lin index)
            searchlight_cells{subject_idx,roi_idx} = searchlight_results;
        end
    end
end
update_logfile('---analysis complete---',output_log)



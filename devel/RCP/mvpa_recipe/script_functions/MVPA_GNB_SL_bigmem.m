function [brain_cells,searchlight_cells] = MVPA_GNB_SL_bigmem(options)


%GOALS:::
%   0. Initialize variables
%   1. load behavioral data
%   2. load brain data & determine valid LOSO voxels
%   3. map searchlight indicies
%   4. loop through subjects
%   5. create sliceable searchlight data matrix & treat fmri data (subjectwise)
%   6. set up cross validation
%   7. precalculate whole brain GNB parameters
%   8. slice searchlights & classify
%   9. store CV accuracy



%0. Initialize variables
brain_cells = cell(numel(options.subjects),numel(options.roi_list));
searchlight_cells = cell(numel(options.subjects),numel(options.roi_list));
valid_subs = ~ismember(options.subjects,options.exclusions)';
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
    case 'TwoOut'
        subs2LO = options.subjects(valid_subs); %cross validation indicies
        subs2LO = {subs2LO(subs2LO < 200), subs2LO(subs2LO > 200)};
        subs2LO = combvec(subs2LO{1},subs2LO{2});
    case 'OneOut'
        subs2LO = options.subjects(valid_subs); %cross validation indicies
end

%warnings because this script doesn't jive with the toolbox
if options.remove_endrun_trials ~= 0
    update_logfile('WARNING: NOT CONFIGURED FOR REMOVING ENDRUN DATA',output_log)
end
% if strcmp(options.trial_temporal_compression,'on') == 0
%     update_logfile('WARNING: NOT TESTED FOR UNCOMPRESSED SUBJECTWISE DATA',output_log)
% end
if options.TR_delay > 0 | options.TR_avg_window > 0
    update_logfile('WARNING: NOT CONFIGURED FOR DATA LAGGING OR TR AVERAGING',output_log)
end
if strcmp(options.feature_selection,'off') == 0
    update_logfile('WARNING: FEATURE SELECTION NOT CONFIGURED',output_log)
end


%1. load behavioral data
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
            switch options.behavioral_transformation %hardcoding this sorta
                case 'R'
                    encoding_trials = ismember(beh_matrix(:,3),options.enc_runs) & ~isnan(beh_matrix(:,4));
                    correctRtrials = beh_matrix(:,5) == 1 & beh_matrix(:,6) == 1; %only correct "remember" responses
                    trialtype_matrix = NaN(size(beh_matrix(:,4)));
                    trialtype_matrix(encoding_trials) = beh_matrix(encoding_trials,4);
                    trialtype_matrix(correctRtrials) = beh_matrix(correctRtrials,4);
            end
            trialtype_matrix = clean_endrun_trials(trialtype_matrix,trials2cut,idx); %remove behavioral trials without proper fmri data
            subject_behavioral_data{idx,beh_idx} = trialtype_matrix; %subject_behavioral data NOT to be altered after this point
            subject_run_index{idx,beh_idx} = beh_matrix(:,3); %store subject run index for all trials
        end
    end
end

% %2. load brain data & determine valid LOSO voxels
% %Load in Masks
% mask_data = cell(numel(options.roi_list),1);
% for maskidx = 1:numel(options.roi_list)
%     my_files = {fullfile(options.mask_dir,options.roi_list{maskidx})};
%     mask_data{maskidx} = logical(load_fmridata(my_files,options));
% end
% commonvox_maskdata = cat(4,mask_data{:});
% subject_brain_data = NaN([vol_size sum(options.trials_per_run) numel(options.subjects)]);
% for idx = 1:numel(options.subjects),
%     if ismember(options.subjects(idx),options.exclusions) == 0
%         disp(sprintf('\nLoading subject %g fMRI data',options.subjects(idx)))
%         %get data directory and preallocate file data array
%         subj_dir = fullfile(options.SPMdata_dir,[options.SPMsubj_dir num2str(options.subjects(idx))]);
%         file_data = cell(numel(options.runfolders),1); %preall cell array for load_fmridata
%         %Load in scans
%         for runidx = 1:numel(options.runfolders)
%             my_files = prepare_fp(options,subj_dir,options.runfolders{runidx},options.scan_ft); %get filenames
%             file_data{runidx} = load_fmridata(my_files,options); %load data
%         end
%         file_data = cat(4,file_data{:}); % cat data into matrix
%         for roi_idx = 1:numel(options.roi_list)
%             %punch out bad subject voxels from commonvoxel mask
%             commonvox_maskdata(:,:,:,roi_idx) = update_commonvox_mask_LOSO_SL(commonvox_maskdata,roi_idx,file_data,options);
%         end
%         subject_brain_data(:,:,:,:,idx) = file_data; %5D: x,y,z,trials,subjects
%     end
% end
%
% %Remove exclusions from both brain & behavior data (not preallocating extra empty searchlight matricies for exclusions)
% subject_inds = options.subjects(valid_subs)'; %kick out exclusions so dims match CV indexing below
% subject_behavioral_data = subject_behavioral_data(valid_subs,:);
% subject_brain_data = subject_brain_data(:,:,:,:,valid_subs);
% trials2cut = trials2cut(:,valid_subs); %don't frank this up

%Begin loops
update_logfile(':::Starting naive bayes searchlight MVPA:::',output_log)
for roi_idx = 1:numel(options.roi_list)
    if exist(special_progress_tracker) > 0
        delete(special_progress_tracker) %fresh start for new ROI
    end
    message = sprintf('ROI: %s\n',options.rois4fig{roi_idx});
    update_logfile(message,output_log)
    %3. map searchlight indicies
    update_logfile('Finding searchlight indicies',output_log)
    %--- Precalculate searchlight indices
    commonvox_maskdata = fullfile(options.preproc_data_dir,['commonvox_' options.roi_list{roi_idx}]);
    commonvox_maskdata =  spm_read_vols(spm_vol(commonvox_maskdata));
    [searchlight_inds,seed_inds] = preallocate_searchlights(commonvox_maskdata,options.searchlight_radius); %grow searchlight sphere @ every included voxel
    update_logfile('Searchlight indexing complete',output_log)
    update_logfile(['--Total valid searchlights: ' num2str(numel(seed_inds))],output_log)
    %4. loop through subjects
    for subject_idx = 1:numel(options.subjects)
        if ismember(options.subjects(subject_idx),options.exclusions) == 0
            update_logfile(['starting subject # ' num2str(options.subjects(subject_idx))],output_log)
            %   5. create sliceable searchlight data matrix & treat fmri data (subjectwise)
            update_logfile('Creating searchlight matrix',output_log)
            %---load/pass subject data
            CVbeh_data = subject_behavioral_data{subject_idx};  %pass behavioral data
            run_index = subject_run_index{subject_idx}; %get run index
            searchlight_brain_data = load(subject_fmri_filepointers{subject_idx}); %load preprocessed fmri data (valid voxels already determined)
            searchlight_brain_data = searchlight_brain_data.preprocessed_scans;
            %---select trials
            trial_selector = ~isnan(CVbeh_data); %this is replacing select_trials()
            searchlight_brain_data = searchlight_brain_data(:,:,:,trial_selector); %brain
            run_index = run_index(trial_selector); %run index
            CVbeh_data = CVbeh_data(trial_selector); %behavior/trial labels
            %---sliceable searchlight matrix
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
                    [data_matrix,CVbeh_data{subject_idx}] = GNBtemporal_compression(data_matrix,CVbeh_data{subject_idx},options);
                case 'runwise'
                    [data_matrix,CVbeh_data{subject_idx}] = GNB_Tcomp_runwise(data_matrix,CVbeh_data{subject_idx},run_index);
                case 'off'
                    %nada
            end
            %   6. set up cross validation
            output_brain = nan(vol_size(1),vol_size(2),vol_size(3),numel(options.behavioral_file_list));%initalize output brain
            [seed_x,seed_y,seed_z] = ind2sub(vol_size(1:3),seed_inds);
            cv_correct = cell(1,CV.kfolds);
            cv_guesses = cell(1,CV.kfolds);
            
            for fold_idx = 1:CV.kfolds %CV folds
                %store CV accuracy
                searchlight_correct = NaN(numel(seed_inds),1); %store number of correct label guesses for searchlight CV
                searchlight_guesses = NaN(numel(seed_inds),1); %store number of total label guesses for searchlight CV
                
                %run logicals
                testing_logical = ismember(run_index,CV.testing_runs(:,fold_idx));
                training_logical = ismember(run_index,CV.training_runs(:,fold_idx));
                %class labels
                training_labels = CVbeh_data(training_logical);
                testing_labels = CVbeh_data(testing_logical);
                %   7. precalculate whole brain GNB parameters
                [model_mu,model_SD,model_Cpriors] = ...
                    GNBtrain_wholebrain(searchlight_brain_data(training_logical,:,:),training_labels);
                model_class_labels = unique(training_labels);
                %   8. slice searchlights & classify
                parfor searchlight_idx = 1:numel(seed_inds)
                    current_searchlight = searchlight_brain_data(:,:,searchlight_idx);
                    GNBmodel = struct();%initialize stucture for parfor loop
                    GNBmodel.mu = model_mu(:,:,searchlight_idx);
                    GNBmodel.SD = model_SD(:,:,searchlight_idx);
                    GNBmodel.class_labels = model_class_labels;
                    GNBmodel.class_priors = model_Cpriors; %got a record so they put me with the baddest bunch
                    %get testing data
                    testing_data = current_searchlight(testing_logical,:);
                    %classify
                    predictions = GNBclassify_searchlight(testing_data,testing_labels,GNBmodel);
                    %   9. store CV accuracy
                    switch options.performance_stat
                        case 'accuracy'
                            searchlight_correct(searchlight_idx) = sum(predictions(:,1) == predictions(:,2)); %count number correct
                            searchlight_guesses(searchlight_idx) = numel(predictions(:,1)); %count number of guesses
                        case 'Fscore'
                            searchlight_guesses(searchlight_idx) = modelFscore(predictions(:,1),predictions(:,2));
                            %just use "guesses" for this, not a great name but w/e. Beats making another var for this switch
                    end
                end%searchlight loop
                %store CV accuracy
                cv_correct{fold_idx} = searchlight_correct;
                cv_guesses{fold_idx} = searchlight_guesses;
                
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
            
            switch options.performance_stat
                case 'accuracy'
                    searchlight_results = sum(cell2mat(cv_correct),2) ./ sum(cell2mat(cv_guesses),2); %mean accuracy across CV folds
                case 'Fscore'
                    searchlight_results = mean(cell2mat(cv_guesses),2); %take average F score across CV folds
            end
            if sum(isnan(searchlight_results(:))) > 0
                update_logfile('WARNING: PROBLEM WITH CV ACCURACY STORAGE',output_log)
            end
            searchlight_results = [seed_inds,searchlight_results]; %include results' searchlight seed location (lin index)
            searchlight_cells{subject_idx,roi_idx} = searchlight_results;
            output_brain = results2output_brain(searchlight_results(:,2),[1:numel(seed_inds)],output_brain,seed_x,seed_y,seed_z,options);
            brain_cells{subject_idx,roi_idx} = output_brain;
            %you might be able to do away with the output brain stuff, just keep searchlight output
        end
    end
end
update_logfile('---analysis complete---',output_log)



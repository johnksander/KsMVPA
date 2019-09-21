function [voxel_null,roi_seed_inds] = MVPA_GNB_SL_perm(options)
%for machines with less memory
%
%GOALS:::
%   0. Initialize variables
%   1. load behavioral data
%   2. map searchlight indicies
%   3. loop through subjects
%   4. create sliceable searchlight data matrix & treat fmri data (subjectwise)
%   5. set permutation order for searchlight course
%   6. set up cross validation
%   7. precalculate whole brain GNB parameters
%   8. slice searchlights & classify
%   9. store CV accuracy



%0. Initialize variables
rng('shuffle') %just for fun
voxel_null = cell(numel(options.subjects),numel(options.roi_list));
roi_seed_inds = cell(numel(options.roi_list),1);
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


%Begin loops
update_logfile(':::Starting naive bayes searchlight MVPA:::',output_log)
for roi_idx = 1:numel(options.roi_list)
    message = sprintf('ROI: %s\n',options.rois4fig{roi_idx});
    update_logfile(message,output_log)
    %2. map searchlight indicies
    update_logfile('Finding searchlight indicies',output_log)
    %--- Precalculate searchlight indices
    commonvox_maskdata = fullfile(options.preproc_data_dir,['commonvox_' options.roi_list{roi_idx}]);
    commonvox_maskdata =  spm_read_vols(spm_vol(commonvox_maskdata));
    update_logfile('WARNING: hardcoded searchlight index loading',output_log)
    %[searchlight_inds,seed_inds] = preallocate_searchlights(commonvox_maskdata,options.searchlight_radius); %grow searchlight sphere @ every included voxel
    SLfile = load('SLinds_1p5thr10.mat');
    searchlight_inds = SLfile.searchlight_inds;
    seed_inds = SLfile.seed_inds;
    update_logfile('Searchlight indexing complete',output_log)
    update_logfile(['--Total valid searchlights: ' num2str(numel(seed_inds))],output_log)
    %3. loop through subjects
    for subject_idx = 1:numel(options.subjects)
        if ismember(options.subjects(subject_idx),options.exclusions) == 0
            if exist(special_progress_tracker) > 0
                delete(special_progress_tracker) %fresh start for new subject
            end
            update_logfile(['starting subject # ' num2str(options.subjects(subject_idx))],output_log)
            %4. create sliceable searchlight data matrix & treat fmri data (subjectwise)
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
            switch options.trial_temporal_compression
                case 'on'
                    [data_matrix,CVbeh_data{subject_idx}] = GNBtemporal_compression(data_matrix,CVbeh_data{subject_idx},options);
                case 'runwise'
                    [data_matrix,CVbeh_data{subject_idx}] = GNB_Tcomp_runwise(data_matrix,CVbeh_data{subject_idx},run_index);
                case 'off'
                    %data_matrix = zscore(data_matrix); %do this runwise, if you end up doing it
                    update_logfile('WARNING: skipping cocktail blank removal',output_log)
            end
            
            %   5. set permutation order for searchlight course
            perm_matrix = NaN(numel(CVbeh_data),options.num_perms);
            for pmat_idx = 1:options.num_perms
                perm_matrix(:,pmat_idx) = randperm(numel(CVbeh_data))'; %set permutation order
            end
            
            searchlight_results = NaN(numel(seed_inds),options.num_perms);%easier results-to-roi file mapping
            
            for permidx = 1:options.num_perms
                
                permCVbeh_data = CVbeh_data(perm_matrix(:,permidx)); %permute labels for CV loop
                %6. set up cross validation
                cv_correct = cell(1,CV.kfolds);
                cv_guesses = cell(1,CV.kfolds);
                %cv_Fscore = cell(1,CV.kfolds);
                
                for fold_idx = 1:CV.kfolds %CV folds
                    searchlight_correct = NaN(numel(seed_inds),1); %store number of correct label guesses for searchlight CV
                    searchlight_guesses = NaN(numel(seed_inds),1); %store number of total label guesses for searchlight CV
                    %searchlight_Fscore = NaN(numel(seed_inds),1); %store searchlight F score
                    
                    %run logicals
                    testing_logical = ismember(run_index,CV.testing_runs(:,fold_idx));
                    training_logical = ismember(run_index,CV.training_runs(:,fold_idx));
                    %class labels
                    training_labels = permCVbeh_data(training_logical);
                    testing_labels = permCVbeh_data(testing_logical);
                    %7. precalculate whole brain GNB parameters
                    [model_mu,model_SD,model_Cpriors] = ...
                        GNBtrain_wholebrain(searchlight_brain_data(training_logical,:,:),training_labels);
                    model_class_labels = unique(training_labels);
                    %8. slice searchlights & classify
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
                        searchlight_correct(searchlight_idx) = sum(predictions(:,1) == predictions(:,2)); %count number correct
                        searchlight_guesses(searchlight_idx) = numel(predictions(:,1)); %count number of guesses
                        %searchlight_Fscore(searchlight_idx) = modelFscore(predictions(:,1),predictions(:,2));
                    end%searchlight loop
                    %store CV accuracy
                    cv_correct{fold_idx} = searchlight_correct;
                    cv_guesses{fold_idx} = searchlight_guesses;
                    %cv_Fscore{fold_idx} = searchlight_Fscore;
                end%CV loop
                %9. store CV accuracy
                searchlight_results(:,permidx) = sum(cell2mat(cv_correct),2) ./ sum(cell2mat(cv_guesses),2); %mean accuracy across CV folds
                %take average F score across CV folds, will have to store in another output brain (or, 4th D of output brain volume
                
                switch options.parforlog %parfor progress tracking
                    case 'on'
                        txtappend(special_progress_tracker,'1\n')
                        SPT_fid = fopen(special_progress_tracker,'r');
                        progress = fscanf(SPT_fid,'%i');
                        fclose(SPT_fid);
                        if mod(sum(progress),floor(options.num_perms * .1)) == 0 %1 percent (for test with 10 perms)
                            progress = (sum(progress) /  options.num_perms) * 100;
                            message = sprintf('Permutation test %.1f percent complete',progress);
                            update_logfile(message,output_log)
                        end
                end
                
            end %permutation parfor loop
            voxel_null{subject_idx,roi_idx} = searchlight_results;
        end
    end %subject loop
    roi_seed_inds{roi_idx} = seed_inds;
end
update_logfile('---analysis complete---',output_log)



function [voxel_null,roi_seed_inds] = MVPA_GNB_SL_perm_bigmem(options)


%GOALS:::
%   0. Initialize variables
%   1. load behavioral data
%   2. load brain data & determine valid LOSO voxels
%   3. map searchlight indicies
%   5. create sliceable searchlight data matrix & treat fmri data (subjectwise)
%   6. set up cross validation
%   7. set permutation order for searchlight course
%   8. precalculate whole brain GNB parameters
%   9. slice searchlights & classify
%   10. store CV accuracy


%0. Initialize variables
voxel_null = cell(numel(options.roi_list),1);
roi_seed_inds = cell(numel(options.roi_list),1);
valid_subs = ~ismember(options.subjects,options.exclusions)';
vol_size = options.scan_vol_size; %just make var name easier
trials2cut = find_endrun_trials(options); %find behavioral trials without proper fmri data
output_log = fullfile(options.save_dir,'output_log.txt');
special_progress_tracker = fullfile(options.save_dir,'SPT.txt');
rng('shuffle') %just for fun
switch options.CVscheme
    case 'TwoOut'
        subs2LO = options.subjects(valid_subs); %cross validation indicies
        subs2LO = {subs2LO(subs2LO < 200), subs2LO(subs2LO > 200)};
        subs2LO = combvec(subs2LO{1},subs2LO{2});
    case 'OneOut'
        subs2LO = options.subjects(valid_subs); %cross validation indicies
end

%warnings because this script doesn't jive with the toolbox
if strcmp(options.trial_temporal_compression,'on') == 0
    update_logfile('WARNING: NOT TESTED FOR UNCOMPRESSED SUBJECTWISE DATA',output_log)
end
if options.TR_delay > 0 | options.TR_avg_window > 0
    update_logfile('WARNING: NOT CONFIGURED FOR DATA LAGGING OR TR AVERAGING',output_log)
end
if strcmp(options.behavioral_measure,'allstim') == 0
    update_logfile('WARNING: DATA SELECTION NOT CONFIGURED, ONLY USE ALL STIMS',output_log)
end
if strcmp(options.feature_selection,'off') == 0
    update_logfile('WARNING: FEATURE SELECTION NOT CONFIGURED',output_log)
end


%1. load behavioral data
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
            switch options.rawdata_type
                case 'SPMbm'
                    beh_matrix = make_runindex(options);
            end
            switch options.behavioral_transformation %add EA/US split here
                case 'balanced_median_split'
                    beh_matrix = balanced_median_split(beh_matrix);
                case 'best_versus_rest'
                    %not implemented?
                case 'origin_split'
                    if options.subjects(idx) < 200
                        beh_matrix(~isnan(beh_matrix)) = 1; %US
                    elseif options.subjects(idx) > 200
                        beh_matrix(~isnan(beh_matrix)) = 2; %EA
                    end
            end
            beh_matrix = clean_endrun_trials(beh_matrix,trials2cut,idx); %remove behavioral trials without proper fmri data
            subject_behavioral_data{idx,beh_idx} = beh_matrix; %subject_behavioral data NOT to be altered after this point
        end
    end
end

%2. load brain data & determine valid LOSO voxels
%Load in Masks
mask_data = cell(numel(options.roi_list),1);
for maskidx = 1:numel(options.roi_list)
    my_files = {fullfile(options.mask_dir,options.roi_list{maskidx})};
    mask_data{maskidx} = logical(load_fmridata(my_files,options));
end
commonvox_maskdata = cat(4,mask_data{:});
subject_brain_data = NaN([vol_size sum(options.trials_per_run) numel(options.subjects)]);
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
        for roi_idx = 1:numel(options.roi_list)
            %punch out bad subject voxels from commonvoxel mask
            commonvox_maskdata(:,:,:,roi_idx) = update_commonvox_mask_LOSO_SL(commonvox_maskdata,roi_idx,file_data,options);
        end
        subject_brain_data(:,:,:,:,idx) = file_data; %5D: x,y,z,trials,subjects
    end
end

%Remove exclusions from both brain & behavior data (not preallocating extra empty searchlight matricies for exclusions)
subject_inds = options.subjects(valid_subs)'; %kick out exclusions so dims match CV indexing below
subject_behavioral_data = subject_behavioral_data(valid_subs,:);
subject_brain_data = subject_brain_data(:,:,:,:,valid_subs);
trials2cut = trials2cut(:,valid_subs); %don't frank this up

%Begin loops
update_logfile(':::Starting naive bayes searchlight permutation test:::',output_log)
for roi_idx = 1:numel(options.roi_list)
    if exist(special_progress_tracker) > 0
        delete(special_progress_tracker) %fresh start for new ROI
    end
    message = sprintf('ROI: %s\n',options.rois4fig{roi_idx});
    update_logfile(message,output_log)
    %3. map searchlight indicies
    update_logfile('Finding searchlight indicies',output_log)
    %--- Precalculate searchlight indices
    [searchlight_inds,seed_inds] = preallocate_searchlights(commonvox_maskdata(:,:,:,roi_idx),options.searchlight_radius); %grow searchlight sphere @ every included voxel
    update_logfile('Searchlight indexing complete',output_log)
    update_logfile(['--Total valid searchlights: ' num2str(numel(seed_inds))],output_log)
    if options.searchlight_radius < 2
        update_logfile('Creating spec matrix',output_log)
        fugazi = bigmem_searchlight_wrapper(subject_brain_data,vol_size,searchlight_inds);
    end
    %   5. create sliceable searchlight data matrix & treat fmri data (subjectwise)
    update_logfile('Creating searchlight matrix',output_log)
    searchlight_brain_data = cell(sum(valid_subs),1);
    CVbeh_data = cell(size(subject_behavioral_data));
    for subject_idx = 1:sum(valid_subs) %all exclusions already taken care of
        update_logfile(['starting subject # ' num2str(subject_inds(subject_idx))],output_log)
        CVbeh_data(subject_idx,:) = subject_behavioral_data(subject_idx,:); %pass behavioral data
        data_matrix = bigmem_searchlight_wrapper(subject_brain_data(:,:,:,:,subject_idx),vol_size,searchlight_inds); %sliceable searchlight matrix
        run_index = make_runindex(options); %make run index
        run_index = clean_endrun_trials(run_index,trials2cut,subject_idx); %match run index to cleaned behavioral data
        %data_matrix = HDRlag(options,data_matrix,run_index); %lag data, average over window (if specified)
        %07/20/2016: lag data is disabled for this script, use HDR modeled data
        %data_matrix = clean_endrun_trials(data_matrix,trials2cut,subject_idx);%remove trials without proper fmri data
        data_matrix = data_matrix(~trials2cut(:,subject_idx),:,:); %adapted from clean_endrun_trials() for this script
        %[data_matrix,CVbeh_data{subject_idx}] = select_trials(data_matrix,CVbeh_data{subject_idx});%select trials
        %07/20/2016: select trials is disabled for this script, rework if not using all stimuli
        %normalization/termporal compression
        switch options.trial_temporal_compression
            case 'on'
                [data_matrix,CVbeh_data{subject_idx}] = GNBtemporal_compression(data_matrix,CVbeh_data{subject_idx},options);
            case 'runwise'
                [data_matrix,CVbeh_data{subject_idx}] = GNB_Tcomp_runwise(data_matrix,CVbeh_data{subject_idx},run_index);
            case 'off'
                %data_matrix = zscore(data_matrix); %normalize subject-wise
        end
        searchlight_brain_data{subject_idx} = data_matrix;
    end
    update_logfile('Searchlight matrix complete',output_log)
    
    %   6. set up cross validation
    %set up inds for leave out CV scheme
    subject_inds = GNBmatch_subinds2data(subject_inds,searchlight_brain_data); %make subject inds match the data (num scans etc)
    CVbeh_data = cell2mat(CVbeh_data); %now everything can be a matrix
    searchlight_brain_data = cell2mat(searchlight_brain_data); %now everything can be a matrix
    %searchlight_brain_data = zscore(searchlight_brain_data,[],1); %!!!!normalize across "conditions"!!!!
    update_logfile('WARNING: skipping cocktail blank removal',output_log)
    %7. set permutation order for searchlight course
    perm_matrix = NaN(numel(subject_inds),options.num_perms);
    for pmat_idx = 1:options.num_perms
        perm_matrix(:,pmat_idx) = randperm(numel(subject_inds))'; %set permutation order
    end
    
    searchlight_results = NaN(numel(seed_inds),options.num_perms);%easier results-to-roi file mapping
    parfor permidx = 1:options.num_perms
        
        permCVbeh_data = CVbeh_data(perm_matrix(:,permidx)); %permute labels for CV loop
        cv_correct = cell(1,numel(subs2LO(1,:)));
        cv_guesses = cell(1,numel(subs2LO(1,:)));
        for test_sub_combo = 1:numel(subs2LO(1,:))
            %store CV accuracy
            searchlight_correct = NaN(numel(seed_inds),1); %store number of correct label guesses for searchlight CV
            searchlight_guesses = NaN(numel(seed_inds),1); %store number of total label guesses for searchlight CV
            %subject logicals
            testing_subject = subs2LO(:,test_sub_combo);
            training_subjects = ~ismember(subject_inds,testing_subject);
            testing_subject = ~training_subjects; %just to make it explicit
            %class labels
            training_labels = permCVbeh_data(training_subjects);
            testing_labels = permCVbeh_data(testing_subject);
            %   8. precalculate whole brain GNB parameters
            [model_mu,model_SD,model_Cpriors] = ...
                GNBtrain_wholebrain(searchlight_brain_data(training_subjects,:,:),training_labels);
            model_class_labels = unique(training_labels);
            %   9. slice searchlights & classify
            for searchlight_idx = 1:numel(seed_inds)
                current_searchlight = searchlight_brain_data(:,:,searchlight_idx);
                GNBmodel = struct();%initialize stucture for parfor loop
                GNBmodel.mu = model_mu(:,:,searchlight_idx);
                GNBmodel.SD = model_SD(:,:,searchlight_idx);
                GNBmodel.class_labels = model_class_labels;
                GNBmodel.class_priors = model_Cpriors; %got a record so they put me with the baddest bunch
                %get testing data
                testing_data = current_searchlight(testing_subject,:);
                %classify
                predictions = GNBclassify_searchlight(testing_data,testing_labels,GNBmodel);
                %   10. store CV accuracy
                searchlight_correct(searchlight_idx) = sum(predictions(:,1) == predictions(:,2)); %count number correct
                searchlight_guesses(searchlight_idx) = numel(predictions(:,1)); %count number of guesses
                %this could be faster without the sum & numel calcs here...
            end%searchlight loop
            %store CV accuracy
            cv_correct{test_sub_combo} = searchlight_correct;
            cv_guesses{test_sub_combo} = searchlight_guesses;
            
        end%CV loop
        
        searchlight_results(:,permidx) = sum(cell2mat(cv_correct),2) ./ sum(cell2mat(cv_guesses),2); %mean accuracy across CV folds
        switch options.parforlog %parfor progress tracking
            case 'on'
                txtappend(special_progress_tracker,'1\n')
                SPT_fid = fopen(special_progress_tracker,'r');
                progress = fscanf(SPT_fid,'%i');
                fclose(SPT_fid);
                if mod(sum(progress),floor(options.num_perms * .005)) == 0 %.5 percent
                    progress = (sum(progress) /  options.num_perms) * 100;
                    message = sprintf('Permutation test %.1f percent complete',progress);
                    update_logfile(message,output_log)
                end
        end
    end %permutation parfor loop
    
    voxel_null{roi_idx} = searchlight_results;
    roi_seed_inds{roi_idx} = seed_inds;
end
update_logfile('---analysis complete---',output_log)



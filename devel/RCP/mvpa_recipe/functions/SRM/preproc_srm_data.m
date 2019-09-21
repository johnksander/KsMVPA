function preproc_srm_data(subject_file_pointers,options)

%06/07/2018:
%I made this it's own thing from MVPA_ROI_enc2ret() because this will
%eventually be used for that purpose...

%GOALS:::
%   0. Initialize variables and load behavioral data
%   1. load and treat data
%   2. save in SRM-toolbox friendly form

%0. Initialize variables
%required the var name is "data" here...
all_brain_data = cell(numel(options.subjects),numel(options.roi_list));
all_behavior_data = cell(numel(options.subjects),numel(options.roi_list));
all_run_inds = cell(numel(options.subjects),numel(options.roi_list));

roiFNlabels = regexp(options.roi_list, '.nii', 'split'); %make labels for saved preproc data based on real mask FN
roiFNlabels = vertcat(roiFNlabels{:});
roiFNlabels = roiFNlabels(:,1);

SRM_preproc_dir = fullfile(options.preproc_data_dir,'SRM');

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
update_logfile(':::ROI MVPA:::\n',output_log)



%load all brain data
for subject_idx = 1:numel(options.subjects)
    if ~ismember(options.subjects(subject_idx),options.exclusions)
        update_logfile(['starting subject # ' num2str(options.subjects(subject_idx))],output_log)
        update_logfile('----------------------',output_log)
        %brain_data = cell(size(options.roi_list));
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
            data_matrix = load(subject_file_pointers{subject_idx,roi_idx}); %load preprocessed fmri data (valid voxels already determined)
            data_matrix = data_matrix.data_matrix;
            %---select trials
            trial_selector = ~isnan(CVbeh_data); %this is replacing select_trials()
            data_matrix = data_matrix(trial_selector,:); %brain
            run_index = run_index(trial_selector); %run index
            CVbeh_data = CVbeh_data(trial_selector); %behavior/trial labels
            %---treat the brain data as needed...
            data_matrix = remove_badvoxels(data_matrix);
            %data_matrix = HDRlag(options,data_matrix,run_index); %lag data, average over window (if specified)
            %07/20/2016: lag data is disabled for this script, use HDR modeled data
            %would need to clean end run trials from fmri data here
            %data_matrix = clean_endrun_trials(data_matrix,trials2cut,subject_idx);%remove trials without proper fmri data
            %searchlight_brain_data = searchlight_brain_data(~trials2cut(:,subject_idx),:,:); %adapted from clean_endrun_trials() for this script
            %run_index = clean_endrun_trials(run_index,trials2cut,subject_idx); %match run index to cleaned behavioral data
            %normalization/termporal compression
            switch options.normalization
                case 'runwise'
                    data_matrix = cocktail_blank_normalize(data_matrix,run_index);
                    update_logfile('Data matrix set to zero mean & unit variance: run wise',output_log)
                case 'off'
                    update_logfile('WARNING: skipping cocktail blank removal',output_log)
            end
            switch options.trial_temporal_compression
                case 'on'
                    [data_matrix,CVbeh_data{subject_idx}] = temporal_compression(data_matrix,CVbeh_data{subject_idx},options);
                case 'runwise'
                    run_index = clean_endrun_trials(run_index,trials2cut,subject_idx);%match run index to valid fmri trials
                    [data_matrix,CVbeh_data{subject_idx}] = temporal_compression_runwise(data_matrix,CVbeh_data{subject_idx},run_index);
                case 'off'
                    %nada
            end
            all_brain_data{subject_idx,roi_idx} = data_matrix;
            all_behavior_data{subject_idx,roi_idx} = CVbeh_data; %just for saving the var name
            all_run_inds{subject_idx,roi_idx} = run_index;
            
            
            
        end
        
    end
end

for roi_idx = 1:numel(options.roi_list)
    
    FN = fullfile(SRM_preproc_dir,sprintf('%s',roiFNlabels{roi_idx}));
    if ~isdir(FN),mkdir(FN);end
    FN = fullfile(FN,'ROI_subject_data.mat');
    brain_data = all_brain_data(:,roi_idx);
    behavior = all_brain_data(:,roi_idx);
    run_inds = all_run_inds(:,roi_idx);
    save(FN,'brain_data','behavior','run_inds');
    sprintf('ROI #%i/%i saved',roi_idx,numel(options.roi_list))
    
end



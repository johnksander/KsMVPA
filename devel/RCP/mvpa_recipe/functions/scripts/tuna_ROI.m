function searchlight_cells = tuna_ROI(options)

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
encdir = fullfile(options.home_dir,'Results',options.enc_job,'stats','%s_conn_%i','enc2ret_data');
encdir = sprintf(encdir,options.cluster_effect_stat,options.cluster_conn); %consistent params
mask_data = spm_read_vols(spm_vol(fullfile(encdir,'results_mask.nii')));
mask_data = logical(mask_data);
num_encROIs = size(mask_data,4);
if [size(mask_data,1),size(mask_data,2),size(mask_data,3)] ~= vol_size
    error('INCORRECT VOLUME SIZE')
end
update_logfile(sprintf('----Encoding ROIs found: %i',num_encROIs),output_log)
keyboard

update_logfile(':::Starting ROI tuna:::',output_log)
for subject_idx = 1:numel(options.subjects)
    if ismember(options.subjects(subject_idx),options.exclusions),continue;end
    update_logfile(['starting subject # ' num2str(options.subjects(subject_idx))],output_log)
    
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
        message = sprintf('----learning h for encoding ROI #%i/%i',enc_idx,num_encROIs);
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
            case 'runwise'
                error('not configured for runwise temporal compression')
        end
        message = sprintf('----ROI size check: %ix%i',size(ROIdata));
        update_logfile(message,output_log)
        rep = trainAutoencoder(ROIdata'); %watch out, input is feat x obs here 
        
        
        
        encROIs{enc_idx} = ROIdata; %store it away
    end
end

update_logfile('---job complete---',output_log)

%save(fullfile(options.save_dir,[options.name '_braincells']),'searchlight_cells','options')


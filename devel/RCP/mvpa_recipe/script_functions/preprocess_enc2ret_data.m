function encRDMs = preprocess_enc2ret_data(options)


%GOALS:::
%make RDMs from encoding data using ROIs of the significant clusters found
%at encoding. Use that encoding analysis' data procedures via loading the
%options structure from its results.

%   0. Initialize variables
%   1. load behavioral data
%   2. load in ROI masks from encoding data
%   3. loop through subjects
%   4. load subject data used in encoding analysis
%   5. loop through encding ROIs
%   6. build RSM from encoding ROI data (always disimilarity matrix!!!))


%0. Initialize variables
%valid_subs = ~ismember(options.subjects,options.exclusions)';
vol_size = options.scan_vol_size; %just make var name easier
trials2cut = find_endrun_trials(options); %find behavioral trials without proper fmri data
subject_fmri_filepointers = load(fullfile(options.preproc_data_dir,'preproc_data_file_pointers'));
subject_fmri_filepointers = subject_fmri_filepointers.preproc_data_file_pointers;

output_log = fullfile(options.save_dir,'preproc_output_log.txt');

%warnings because this script doesn't jive with the toolbox
if options.remove_endrun_trials ~= 0
    update_logfile('WARNING: NOT CONFIGURED FOR REMOVING ENDRUN DATA',output_log)
end
if options.TR_delay > 0 | options.TR_avg_window > 0
    update_logfile('WARNING: NOT CONFIGURED FOR DATA LAGGING OR TR AVERAGING',output_log)
end
if strcmp(options.feature_selection,'off') == 0
    update_logfile('WARNING: FEATURE SELECTION NOT CONFIGURED',output_log)
end
if ~isfield(options,'treat_special_stimuli')
    %this was added for handling the face/scene stimuli differently for
    %temporal compression. Wouldn't be in options if job was run prior to that
    options.treat_special_stimuli = 'off';
end
if numel(options.roi_list) > 1
    error('More than 1 ROI detected in options input, results won''t save properly')
end


%1. load behavioral data
subject_behavioral_data = cell(numel(options.subjects),numel(options.behavioral_file_list));
subject_run_index = cell(numel(options.subjects),numel(options.behavioral_file_list));
for idx = 1:numel(options.subjects)
    if ~ismember(options.subjects(idx),options.exclusions)
        for beh_idx = 1:numel(options.behavioral_file_list),
            BehFname = [options.behavioral_file_list{beh_idx} '_' num2str(options.subjects(idx)) '.txt'];
            my_files = prepare_fp(options,options.TRfile_dir,BehFname);
            beh_matrix = load_behav_data(my_files,options);
            switch options.behavioral_transformation %hardcoding this sorta
                case 'Rmemory_retrieval'
                    retrieval_trials = ismember(beh_matrix(:,3),options.ret_runs) & ~isnan(beh_matrix(:,4));
                    correctRtrials = beh_matrix(:,5) == 1 & beh_matrix(:,6) == 1; %only correct "remember" responses
                    trialtype_matrix = NaN(size(beh_matrix(:,4)));
                    trialtype_matrix(retrieval_trials & correctRtrials) = ...
                        beh_matrix(retrieval_trials & correctRtrials,4); %take valence for retrieval R trials
                case 'encoding_valence'
                    encoding_trials = ismember(beh_matrix(:,3),options.enc_runs) & ~isnan(beh_matrix(:,4));
                    trialtype_matrix = NaN(size(beh_matrix(:,4)));
                    trialtype_matrix(encoding_trials) = beh_matrix(encoding_trials,4); %only take valence ratings during encoding
                case 'retrieval_valence'
                    retrieval_trials = ismember(beh_matrix(:,3),options.ret_runs) & ~isnan(beh_matrix(:,4));
                    retrieval_lures = ismember(beh_matrix(:,3),options.ret_runs) & beh_matrix(:,4) == 0;
                    trialtype_matrix = NaN(size(beh_matrix(:,4)));
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
            
            
            trialtype_matrix = clean_endrun_trials(trialtype_matrix,trials2cut,idx); %remove behavioral trials without proper fmri data
            subject_behavioral_data{idx,beh_idx} = trialtype_matrix; %subject_behavioral data NOT to be altered after this point
            subject_run_index{idx,beh_idx} = beh_matrix(:,3); %store subject run index for all trials
        end
    end
end



%2. load in ROI masks from encoding data
%Load in Masks
mask_data = spm_read_vols(spm_vol(fullfile(options.save_dir,'results_mask.nii')));
mask_data = logical(mask_data);
num_enc_ROIs = size(mask_data,4);
if [size(mask_data,1),size(mask_data,2),size(mask_data,3)] ~= vol_size
    error('INCORRECT VOLUME SIZE')
end
update_logfile(sprintf('\n:::Starting encoding RDM preprocessing:::\n'),output_log)
message = sprintf('ROIs found in encoding results: %i',num_enc_ROIs);
update_logfile(message,output_log)
%initialize output var 
encRDMs = cell(numel(options.subjects),num_enc_ROIs);

for roi_idx = 1:numel(options.roi_list)
    message = sprintf('Loading subject data with ROI: %s\n',options.rois4fig{roi_idx});
    update_logfile(message,output_log)
    %3. loop through subjects
    for subject_idx = 1:numel(options.subjects)
        if ismember(options.subjects(subject_idx),options.exclusions) == 0
            %   4. load subject data used in encoding analysis
            message = sprintf('\nstarting subject #%i\n',options.subjects(subject_idx));
            update_logfile(message,output_log)
            %---load/pass subject data
            CVbeh_data = subject_behavioral_data{subject_idx};  %pass behavioral data
            run_index = subject_run_index{subject_idx}; %get run index
            brain_data = load(subject_fmri_filepointers{subject_idx}); %load preprocessed fmri data (valid voxels already determined)
            brain_data = brain_data.preprocessed_scans;
            %---select trials
            trial_selector = ~isnan(CVbeh_data); %this is replacing select_trials()
            brain_data = brain_data(:,:,:,trial_selector); %brain
            run_index = run_index(trial_selector); %run index
            CVbeh_data = CVbeh_data(trial_selector); %behavior/trial labels
            %5. loop through encding ROIs
            for enc_idx = 1:num_enc_ROIs
                message = sprintf('working on encoding ROI %i/%i',enc_idx,num_enc_ROIs);
                update_logfile(message,output_log)
                curr_mask = mask_data(:,:,:,enc_idx); %get mask data
                ROIdata = apply_mask2data(curr_mask,brain_data); %mask fmri data
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
                    case 'off'
                        %nada
                end
                
                message = sprintf('----ROI size check: %ix%i',size(ROIdata));
                update_logfile(message,output_log)
                
                %6. build RSM from encoding ROI data (always disimilarity matrix!!!)
                RDM = RSA_constructRDM(ROIdata,options);
                encRDMs{subject_idx,enc_idx} = RDM; %store it away 
                
            end%searchlight loop
            
        end
    end
end

save(fullfile(options.save_dir,'encodingRDMs'),'encRDMs');
update_logfile('---preprocessing complete---',output_log)



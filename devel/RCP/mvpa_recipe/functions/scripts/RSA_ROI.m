function [brain_cells,searchlight_cells] = RSA_ROI(options)


%GOALS:::
%   0. Initialize variables
%   1. load behavioral data
%   2. load brain data & determine valid LOSO voxels
%   3. map searchlight indicies
%   4. loop through subjects
%   5. create sliceable searchlight data matrix & treat fmri data (subjectwise)
%   6. make hypothesis matrix
%   7. slice searchlights & assemble RDM
%   8. test RDM
%   9. store RDM fits to behavioral RDM


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
    if ~ismember(options.subjects(idx),options.exclusions)
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
                case 'encoding_valence'
                    encoding_trials = ismember(beh_matrix(:,3),options.enc_runs) & ~isnan(beh_matrix(:,4));
                    trialtype_matrix = NaN(size(beh_matrix(:,4)));
                    trialtype_matrix(encoding_trials) = beh_matrix(encoding_trials,4); %only take valence ratings during encoding
            end
            trialtype_matrix = clean_endrun_trials(trialtype_matrix,trials2cut,idx); %remove behavioral trials without proper fmri data
            subject_behavioral_data{idx,beh_idx} = trialtype_matrix; %subject_behavioral data NOT to be altered after this point
            subject_run_index{idx,beh_idx} = beh_matrix(:,3); %store subject run index for all trials
        end
    end
end


%Begin loops
update_logfile(':::Starting ROI RSA:::',output_log)
for roi_idx = 1:numel(options.roi_list)
    if exist(special_progress_tracker) > 0
        delete(special_progress_tracker) %fresh start for new ROI
    end
    message = sprintf('ROI: %s\n',options.rois4fig{roi_idx});
    update_logfile(message,output_log)
    
    %4. loop through subjects
    for subject_idx = 1:numel(options.subjects)
        if ismember(options.subjects(subject_idx),options.exclusions) == 0
            %   5. make hypothesis matrix
            update_logfile(['starting subject # ' num2str(options.subjects(subject_idx))],output_log)
            %   5. create sliceable searchlight data matrix & treat fmri data (subjectwise)
            update_logfile('Loaded preprocessed data matrix',output_log)
            %---load/pass subject data
            CVbeh_data = subject_behavioral_data{subject_idx};  %pass behavioral data
            run_index = subject_run_index{subject_idx}; %get run index
            brain_data = load(subject_fmri_filepointers{subject_idx}); %load preprocessed fmri data (valid voxels already determined)
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
                    update_logfile('Searchlight matrix set to zero mean & unit variance: run wise',output_log)
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
            
            %   6. make hypothesis matrix
            
            %build RSA model from behavioral data (always disimilarity matrix!!!)
            behavior_model = abs(repmat(CVbeh_data,1,numel(CVbeh_data)) - repmat(CVbeh_data',numel(CVbeh_data),1));
            %reduce to upper triangular vector
            mat2vec_mask = logical(triu(ones(size(behavior_model)),1));
            behavior_model = behavior_model(mat2vec_mask);
            
            %   7. slice searchlights & assemble RDM
            searchlight_results = NaN(numel(seed_inds),1);
            parfor searchlight_idx = 1:numel(seed_inds)
                switch options.parforlog %parfor progress tracking
                    case 'on'
                        txtappend(special_progress_tracker,'1\n')
                        progress = load(special_progress_tracker);
                        if mod(sum(progress),numel(seed_inds) * .005) == 0 %.5 percent
                            progress = (sum(progress) /  numel(seed_inds)) * 100;
                            message = sprintf('Searchlight RSA %.1f percent complete',progress);
                            update_logfile(message,output_log)
                        end
                end
                
                RDM = RSA_constructRDM(brain_data,options);
                RDM = RDM(mat2vec_mask); %take upper triangular vector
                %   8. test RDM
                model_fit = []; %initalize so it doesn't complain
                switch options.RDM_dist_metric
                    case 'spearman'
                        model_fit = corr(RDM,behavior_model,'type','Spearman');
                        model_fit = atanh(model_fit); %fisher Z transform
                end
                
                %   9. store RDM fits to behavioral RDM
                searchlight_results(searchlight_idx) = model_fit;
                
            end%searchlight loop
            
            
            searchlight_results = [seed_inds,searchlight_results]; %include results' searchlight seed location (lin index)
            searchlight_cells{subject_idx,roi_idx} = searchlight_results;
            output_brain = results2output_brain(searchlight_results(:,2),[1:numel(seed_inds)],output_brain,seed_x,seed_y,seed_z,options);
            brain_cells{subject_idx,roi_idx} = output_brain;
            %you might be able to do away with the output brain stuff, just keep searchlight output
        end
    end
end
update_logfile('---analysis complete---',output_log)



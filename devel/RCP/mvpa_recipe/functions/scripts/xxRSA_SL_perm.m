function [voxel_null,roi_seed_inds] = xxRSA_SL_perm(options)


%07/14/17: this script is retired just because it took a super long time.
%Saving for posterity. It's a nice script.  


%GOALS:::
%   0. Initialize variables
%   1. load behavioral data
%   2. load brain data & determine valid LOSO voxels
%   3. map searchlight indicies
%   4. loop through subjects
%   5. create sliceable searchlight data matrix & treat fmri data (subjectwise)
%   6. make hypothesis matrix
%   7. set permutation order for searchlight course
%   8. slice searchlights & assemble RDM
%   9. test RDM
%   10. store permuted RDM fits to behavioral RDM


%0. Initialize variables
rng('shuffle') %just for fun
voxel_null = cell(numel(options.subjects),numel(options.roi_list));
roi_seed_inds = cell(numel(options.roi_list),1);
%valid_subs = ~ismember(options.subjects,options.exclusions)';
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
update_logfile(':::Starting searchlight RSA permutation testing:::',output_log)
for roi_idx = 1:numel(options.roi_list)
    message = sprintf('ROI: %s\n',options.rois4fig{roi_idx});
    update_logfile(message,output_log)
    %3. map searchlight indicies
    update_logfile('Finding searchlight indicies',output_log)
    %--- Precalculate searchlight indices
    commonvox_maskdata = fullfile(options.preproc_data_dir,['commonvox_' options.roi_list{roi_idx}]);
    commonvox_maskdata =  spm_read_vols(spm_vol(commonvox_maskdata));
    [searchlight_inds,seed_inds] = preallocate_searchlights(commonvox_maskdata,options.searchlight_radius); %grow searchlight sphere @ every included voxel
%     searchlight_inds = load('SLinds_1p5thr10.mat'); %just for debugging
%     seed_inds = searchlight_inds.seed_inds;
%     searchlight_inds = searchlight_inds.searchlight_inds;
    update_logfile('Searchlight indexing complete',output_log)
    update_logfile(['--Total valid searchlights: ' num2str(numel(seed_inds))],output_log)
    %4. loop through subjects
    for subject_idx = 1:numel(options.subjects)
        if ismember(options.subjects(subject_idx),options.exclusions) == 0
            if exist(special_progress_tracker) > 0
                delete(special_progress_tracker) %fresh start for new subject
            end
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
            
            %   6. make hypothesis matrix
            
            %build RSA model from behavioral data (always disimilarity matrix!!!)
            behavior_model = abs(repmat(CVbeh_data,1,numel(CVbeh_data)) - repmat(CVbeh_data',numel(CVbeh_data),1));
            %reduce to upper triangular vector
            mat2vec_mask = logical(triu(ones(size(behavior_model)),1));
            behavior_model = behavior_model(mat2vec_mask);
            
            %   7. set permutation order for searchlight course
            
            perm_matrix = NaN(numel(CVbeh_data),options.num_perms);
            for pmat_idx = 1:options.num_perms
                perm_matrix(:,pmat_idx) = randperm(numel(CVbeh_data))'; %set permutation order
            end
            
            searchlight_results = NaN(numel(seed_inds),options.num_perms);%easier results-to-roi file mapping
            
            %   8. slice searchlights & assemble RDM
            parfor searchlight_idx = 1:numel(seed_inds)
                
                current_searchlight = searchlight_brain_data(:,:,searchlight_idx);
                RDM = RSA_constructRDM(current_searchlight,options);
                
                perm_results = NaN(1,options.num_perms);
                for permidx = 1:options.num_perms
                    permRDM = RSA_permuteRDM(RDM,perm_matrix(:,permidx));
                    permRDM = permRDM(mat2vec_mask); %take upper triangular vector
                    %   9. test RDM
                    switch options.RDM_dist_metric
                        case 'spearman'
                            perm_results(permidx) = atanh(corr(permRDM,behavior_model,'type','Spearman'));
                            %fisher Z transformed
                    end
                end
                %  10. store permuted RDM fits to behavioral RDM
                searchlight_results(searchlight_idx,:) = perm_results;
                
                switch options.parforlog %parfor progress tracking
                    case 'on'
                        txtappend(special_progress_tracker,'1\n')
                        progress = load(special_progress_tracker);
                        if mod(sum(progress),numel(seed_inds) * .005) == 0 %.5 percent
                            progress = (sum(progress) /  numel(seed_inds)) * 100;
                            message = sprintf('Searchlight RSA permutations %.1f percent complete',progress);
                            update_logfile(message,output_log)
                        end
                end
            end%searchlight loop
            voxel_null{subject_idx,roi_idx} = searchlight_results;
        end
    end
    roi_seed_inds{roi_idx} = seed_inds;
end
update_logfile('---analysis complete---',output_log)



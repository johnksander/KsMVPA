function [voxel_null,roi_seed_inds] = RSA_SL_perm_Ktau_special(options)

%this script has a special Kendall's tau configuration, with the aim of
%making that statistic more tractable...

%GOALS:::
%   0. Initialize variables
%   1. load behavioral data
%   2. load brain data & determine valid LOSO voxels
%   3. map searchlight indicies
%   4. loop through subjects
%   5. create sliceable searchlight data matrix & treat fmri data (subjectwise)
%   6. make hypothesis matrix
%   7. set permutation order for searchlight course & create permuted model matrix
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
checkpoint_dir = fullfile(options.save_dir,'checkpoints'); %goddamnit...
if ~isdir(checkpoint_dir),mkdir(checkpoint_dir);end


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
if strcmp(options.RDM_dist_metric,'kendall') == 0
    update_logfile('WARNING: KENDALL TAU DISTANCE NOT SPECIFIED',output_log)
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
                    [searchlight_brain_data,CVbeh_data] = GNBtemporal_compression(searchlight_brain_data,CVbeh_data,options);
                case 'runwise'
                    [searchlight_brain_data,CVbeh_data] = GNB_Tcomp_runwise(searchlight_brain_data,CVbeh_data,run_index);
                case 'off'
                    %nada
            end
            
            
            %   6. make hypothesis matrix
            switch options.treat_special_stimuli %special treatment...
                case 'faces_and_scenes' %face and scene distinction goes away now, just valence
                    CVbeh_data = abs(CVbeh_data);
            end
            %build RSA model from behavioral data (always disimilarity matrix!!!)
            behavior_model = abs(repmat(CVbeh_data,1,numel(CVbeh_data)) - repmat(CVbeh_data',numel(CVbeh_data),1));
            %logical for upper triangular vector
            mat2vec_mask = logical(triu(ones(size(behavior_model)),1));
            
            %   7. set permutation order for searchlight course & create permuted model matrix
            permuted_models = cell(options.num_perms,1);
            for permidx = 1:options.num_perms
                curr_order = randperm(numel(CVbeh_data))'; %set permutation order
                permuted_models{permidx} = RSA_permuteRDM(behavior_model,curr_order);
            end
            %take upper triangular of permuted RDMs
            permuted_models = cellfun(@(x) x(mat2vec_mask),permuted_models,'UniformOutput',false);
            permuted_models = cat(2,permuted_models{:});
            
            switch options.RDM_dist_metric
                case 'kendall'
                    permuted_models = single(permuted_models); %for performance 
                    %precalculate the pairwise inds for K-tau sign calculations
                    [Kt_i1, Kt_i2] = find(tril(ones(numel(permuted_models(:,1)), 'uint8'), -1));
                    Kt_i1 = single(Kt_i1); %speeds up indexing
                    Kt_i2 = single(Kt_i2);
                    %find the sign of all pairwise differences, do this only once
                    Kt_Ysign = sign(permuted_models(Kt_i2, :) - permuted_models(Kt_i1, :));
                    Kt_Yt = diag(Kt_Ysign'*Kt_Ysign)'; %precalculate (n0 - nY) denominator term
            end
            
                                  
            %   8. slice searchlights & assemble RDM
            searchlight_results = NaN(numel(seed_inds),options.num_perms);%easier results-to-roi file mapping
            parfor searchlight_idx = 1:numel(seed_inds)
                
                current_searchlight = searchlight_brain_data(:,:,searchlight_idx);
                RDM = RSA_constructRDM(current_searchlight,options);
                RDM = RDM(mat2vec_mask); %take upper triangular vector
                perm_results = NaN(1,options.num_perms); %make sure the dimensions are gonna match nicely
                
                %   9. test RDM
                switch options.RDM_dist_metric
                    case 'spearman'
                        perm_results(:) = atanh(corr(RDM,permuted_models,'type','Spearman'));
                        %fisher Z transformed
                    case 'kendall'
                        RDM = single(RDM); %speeds up calcs 
                        Kt_Xsign = sign(RDM(Kt_i2, :) - RDM(Kt_i1, :));
                        model_fit = Kt_Xsign'*Kt_Ysign;
                        model_fit = model_fit ./ sqrt(diag(Kt_Xsign'*Kt_Xsign) * Kt_Yt);
                        perm_results(:) = atanh(model_fit);%fisher Z transform
                end
                
                %  10. store permuted RDM fits to behavioral RDM
                searchlight_results(searchlight_idx,:) = perm_results;
                
                switch options.parforlog %parfor progress tracking
                    case 'on'
                        progress = worker_progress_tracker(special_progress_tracker);
                        if mod(progress,floor(numel(seed_inds) * .005)) == 0 %.5 percent
                            progress = (progress / numel(seed_inds)) * 100;
                            message = sprintf('Searchlight RSA permutations %.1f percent complete',progress);
                            update_logfile(message,output_log)
                        end
                end
            end%searchlight loop
            voxel_null{subject_idx,roi_idx} = searchlight_results;
        end
        
        %save checkpoint files because this is a nightmare
        checkpoint_fn = sprintf('subject_%i.mat',options.subjects(subject_idx));
        save(fullfile(checkpoint_dir,checkpoint_fn),'voxel_null','seed_inds','options')
       
    end
    roi_seed_inds{roi_idx} = seed_inds;
end
update_logfile('---analysis complete---',output_log)



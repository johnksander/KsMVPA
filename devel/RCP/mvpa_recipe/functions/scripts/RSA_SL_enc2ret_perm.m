function RSA_SL_enc2ret_perm(options)

%Special script for encoding-to-retrieval analysis. Loads preprocessed RDMs
%constructed from the significant searchlight cluster ROIs at encoding. The
%searchlight RDMs here (retrieval) are reordered to match the stimuli
%presentation order at encoding (so the RDM ordering matches). 

%GOALS:::
%   0.   Initialize variables
%   1a.  load behavioral data (including stimuli presentation order) 
%   1b.  load encoding fMRI RDMs
%   2.   load brain data & determine valid LOSO voxels
%   3.   map searchlight indicies
%   4.   loop through subjects
%   5a.  create sliceable searchlight data matrix & treat fmri data (subjectwise)
%   5b.  reorder behavioral & fMRI data to match encoding order
%   6.   select subject encoding RDMs 
%   7.   set permutation order for searchlight course & create permuted model matrix
%   8.   slice searchlights & assemble RDM
%   9.   test RDM against permuted encoding RDMs
%   10.  store RDM fits 


%0. Initialize variables
rng('shuffle') %just for fun
output_dir = fullfile(options.save_dir,'perm_files'); %make new sub-directory for output files
if ~isdir(output_dir),mkdir(output_dir);end
%voxel_null = cell(numel(options.subjects),numel(options.roi_list));
%roi_seed_inds = cell(numel(options.roi_list),1);
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

%1a. load behavioral data
subject_behavioral_data = cell(numel(options.subjects),numel(options.behavioral_file_list));
subject_run_index = cell(numel(options.subjects),numel(options.behavioral_file_list));
subject_stim_order = cell(numel(options.subjects),1);
for idx = 1:numel(options.subjects)
    if ~ismember(options.subjects(idx),options.exclusions)
        for beh_idx = 1:numel(options.behavioral_file_list),
            BehFname = [options.behavioral_file_list{beh_idx} '_' num2str(options.subjects(idx)) '.txt'];
            my_files = prepare_fp(options,options.TRfile_dir,BehFname);
            beh_matrix = load_behav_data(my_files,options);   
            trialtype_matrix = NaN(size(beh_matrix(:,4))); %this shoudld've always been up here... repetitive down there 
            stim_order = NaN(size(beh_matrix(:,8))); %always going to be the 8th column in these TR files 
            switch options.behavioral_transformation %hardcoding this sorta
                case 'Rmemory_retrieval'
                    retrieval_trials = ismember(beh_matrix(:,3),options.ret_runs) & ~isnan(beh_matrix(:,4));
                    correctRtrials = beh_matrix(:,5) == 1 & beh_matrix(:,6) == 1; %only correct "remember" responses
                    trialtype_matrix(retrieval_trials & correctRtrials) = ...
                        beh_matrix(retrieval_trials & correctRtrials,4); %take valence for retrieval R trials
                    stim_order(retrieval_trials & correctRtrials) = ...
                        beh_matrix(retrieval_trials & correctRtrials,8);
                case 'encoding_valence'
                    encoding_trials = ismember(beh_matrix(:,3),options.enc_runs) & ~isnan(beh_matrix(:,4));
                    trialtype_matrix(encoding_trials) = beh_matrix(encoding_trials,4); %only take valence ratings during encoding
                    stim_order(encoding_trials) = beh_matrix(encoding_trials,8); %not sure I'd ever need this...
                case 'retrieval_valence'
                    retrieval_trials = ismember(beh_matrix(:,3),options.ret_runs) & ~isnan(beh_matrix(:,4));
                    retrieval_lures = ismember(beh_matrix(:,3),options.ret_runs) & beh_matrix(:,4) == 0;
                    trialtype_matrix(retrieval_trials) = beh_matrix(retrieval_trials,4); %only take valence ratings during encoding
                    stim_order(retrieval_trials) = beh_matrix(retrieval_trials,8);
                    %think about whether you want to include lures in valence RDM at all (or coded back in as neutral trials)
                    trialtype_matrix(retrieval_lures) = NaN; %they don't have a memory component, pretty different I'm excluding
                    stim_order(retrieval_lures) = NaN; %they're already nans in the TR file, but just for consistency..
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
            stim_order = clean_endrun_trials(stim_order,trials2cut,idx);
            %store treated behavioral data 
            subject_behavioral_data{idx,beh_idx} = trialtype_matrix; %subject_behavioral data NOT to be altered after this point
            subject_stim_order{idx} = stim_order;
            subject_run_index{idx,beh_idx} = beh_matrix(:,3); %store subject run index for all trials
        end
    end
end
clear stim_order %just to b safe.. 

%   1b. load encoding fMRI RDMs
update_logfile('loading RDMs from encoding',output_log)
encdir = fullfile(options.home_dir,'Results','%s_stats','enc2ret_data');
encdir = sprintf(encdir,options.enc_job);
subject_encodingRDMs = load(fullfile(encdir,'encodingRDMs.mat'));
subject_encodingRDMs = subject_encodingRDMs.encRDMs;
num_encROIs = numel(subject_encodingRDMs(1,:));
update_logfile(sprintf('----Encoding ROIs found: %i',num_encROIs),output_log)
 

%Begin loops
update_logfile(':::Starting searchlight RSA:::',output_log)
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
    update_logfile(['----Total valid searchlights: ' num2str(numel(seed_inds))],output_log)
    %4. loop through subjects
    for subject_idx = 1:numel(options.subjects)
        if ismember(options.subjects(subject_idx),options.exclusions) == 0
            if exist(special_progress_tracker) > 0
                delete(special_progress_tracker) %fresh start for new subject
            end
            update_logfile(['starting subject # ' num2str(options.subjects(subject_idx))],output_log)
            %   5a. create sliceable searchlight data matrix & treat fmri data (subjectwise)
            update_logfile('Creating searchlight matrix',output_log)
            %---load/pass subject data
            CVbeh_data = subject_behavioral_data{subject_idx};  %pass behavioral data
            run_index = subject_run_index{subject_idx}; %get run index
            stimIDs = subject_stim_order{subject_idx}; %get the stim presentation order (unique ID) 
            searchlight_brain_data = load(subject_fmri_filepointers{subject_idx}); %load preprocessed fmri data (valid voxels already determined)
            searchlight_brain_data = searchlight_brain_data.preprocessed_scans;
            %---select trials
            trial_selector = ~isnan(CVbeh_data); %this is replacing select_trials()
            searchlight_brain_data = searchlight_brain_data(:,:,:,trial_selector); %brain
            CVbeh_data = CVbeh_data(trial_selector); %behavior/trial labels
            run_index = run_index(trial_selector); %run index
            stimIDs = stimIDs(trial_selector); %stimuli order/ID 
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
                    error('not configured for temporal compression')
                    [searchlight_brain_data,CVbeh_data] = GNBtemporal_compression(searchlight_brain_data,CVbeh_data,options);
                case 'runwise'
                    error('not configured for temporal compression')
                    [searchlight_brain_data,CVbeh_data] = GNB_Tcomp_runwise(searchlight_brain_data,CVbeh_data,run_index);
                case 'off'
                    %nada
            end
            %---initalize output brain
            %yea we're not doing the output brain stuff here 
            %output_brain = nan(vol_size(1),vol_size(2),vol_size(3),numel(options.behavioral_file_list));%initalize output brain
            %[seed_x,seed_y,seed_z] = ind2sub(vol_size(1:3),seed_inds);
            
            %   5b.  reorder behavioral & fMRI data to match encoding order
            update_logfile('Reording searchlight & behavior matricies to match encoding',output_log)
            searchlight_brain_data = searchlight_brain_data(stimIDs,:,:);
            CVbeh_data = CVbeh_data(stimIDs);
            
            %   6.  select subject encoding RDMs 
            encodingRDMs = subject_encodingRDMs(subject_idx,:);
            szRDM = unique(cell2mat(cellfun(@size,encodingRDMs,'Uniformoutput',false)));
            if numel(szRDM) > 1,error('irregularly sized encoding RDMs!!!');end
            %get logical for upper triangular 
            mat2vec_mask = logical(triu(ones([szRDM,szRDM]),1));
            
            %             switch options.treat_special_stimuli %special treatment...
            %                 case 'faces_and_scenes' %face and scene distinction goes away now, just valence
            %                     CVbeh_data = abs(CVbeh_data);
            %             end

            %   7. set permutation order for searchlight course & create permuted model matrix
            %quit trying to get fancy and just loop over these.. 
            permuted_models = NaN(sum(mat2vec_mask(:)),options.num_perms,num_encROIs);
            for permidx = 1:options.num_perms
                curr_order = randperm(numel(CVbeh_data))'; %set permutation order
                %permute all encoding RDMs according to the same ordering 
                for enc_idx = 1:num_encROIs
                    curr_model = RSA_permuteRDM(encodingRDMs{enc_idx},curr_order);
                    %reduce to upper triangular vector
                    permuted_models(:,permidx,enc_idx) = curr_model(mat2vec_mask);
                end
            end

            %   8. slice searchlights & assemble RDM
            %searchlight_results = NaN(numel(seed_inds),num_encROIs);
            
            searchlight_results = NaN(numel(seed_inds),options.num_perms,num_encROIs);
            parfor searchlight_idx = 1:numel(seed_inds)
                switch options.parforlog %parfor progress tracking
                    case 'on'
                        progress = worker_progress_tracker(special_progress_tracker);
                        if mod(progress,floor(numel(seed_inds) * .05)) == 0 %5 percent
                            progress = (progress / numel(seed_inds)) * 100;
                            message = sprintf('Searchlight RSA %.1f percent complete',progress);
                            update_logfile(message,output_log)
                        end
                end
                
                current_searchlight = searchlight_brain_data(:,:,searchlight_idx);
                RDM = RSA_constructRDM(current_searchlight,options);
                RDM = RDM(mat2vec_mask); %take upper triangular vector
                
                %    9.  test RDM against encoding RDMs
                ROIfits = NaN(options.num_perms,num_encROIs);
                for enc_idx = 1:num_encROIs
                    model_fit = [];
                    switch options.RDM_dist_metric
                        case 'spearman'
                            model_fit = corr(RDM,permuted_models(:,:,enc_idx),'type','Spearman');
                            model_fit = atanh(model_fit); %fisher Z transform
                        case 'kendall'
                            model_fit = kendall_tau([RDM,permuted_models(:,:,enc_idx)]);
                            model_fit = diag(model_fit,1); %get the off diagonal value
                            model_fit = atanh(model_fit); %fisher Z transform
                    end
                    ROIfits(:,enc_idx) = model_fit;
                end
                
                %   10. store RDM fits to encoding RDMs
                searchlight_results(searchlight_idx,:,:) = ROIfits;
                
            end%searchlight loop
            
            update_logfile('Saving permutation results',output_log)
            %save the ROI null distributions into seperate files (subj specific as well, obv)
            for enc_idx = 1:num_encROIs
                output_fn = sprintf('subject_%i_encROI%i.mat',options.subjects(subject_idx),enc_idx);
                voxel_null = searchlight_results(:,:,enc_idx);
                save(fullfile(output_dir,output_fn),'voxel_null','seed_inds');
            end
                       
            %output_brain = results2output_brain(searchlight_results(:,2),[1:numel(seed_inds)],output_brain,seed_x,seed_y,seed_z,options);
            %brain_cells{subject_idx,roi_idx} = output_brain;
            %yea we're not doing the output brain stuff here 
        end
    end
end
update_logfile('---analysis complete---',output_log)



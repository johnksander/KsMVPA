function estimate_HDR_LSS(options)


fn_sv_label = [options.LSSid '_LSS_eHDR_'];

%must do per subject
%run_index = make_runindex(options); %make run index

%must do per run
%make bandpass filter
%bandpass_filter = LSS_bandpass_filter(2,32,options.scans_per_run(1)); %input TR, sigma, scans per run

fprintf(':::Estimating Hemodynamic Responses (LS-S):::\r')
switch options.LSSintercept %get the correct row from model estiamtes for TOI
    case 'on'
        TOIestimate_row = 2;
    case 'off'
        TOIestimate_row = 1;
end


%load all behavioral data for all subjs
subject_behavioral_data = cell(numel(options.subjects),numel(options.behavioral_file_list));
for idx = 1:numel(options.subjects)
    if ~ismember(options.subjects(idx),options.exclusions)
        for beh_idx = 1:numel(options.behavioral_file_list)
            if numel(options.behavioral_file_list) > 1;disp('WARNING: multiple main behaviors specified');end
            %load all stimuli trials
            BehFname = [options.behavioral_file_list{beh_idx} '_' num2str(options.subjects(idx)) '.txt'];
            my_files = prepare_fp(options,options.TRfile_dir,BehFname);
            beh_matrix = load_behav_data(my_files,options);
            switch options.behavioral_transformation
                case 'R' %used in "RGM" preproc
                    encoding_trials = ismember(beh_matrix(:,3),options.enc_runs) & ~isnan(beh_matrix(:,4));
                    correctRtrials = beh_matrix(:,5) == 1 & beh_matrix(:,6) == 1; %only correct "remember" responses
                    trialtype_beh_matrix = NaN(size(beh_matrix(:,4)));
                    trialtype_beh_matrix(encoding_trials) = beh_matrix(encoding_trials,4);
                    trialtype_beh_matrix(correctRtrials) = beh_matrix(correctRtrials,4);
                    beh_matrix = beh_matrix(:,4); %select behavioral rating
                case 'valence' %for "VMGM" preproc. Model valences seperately
                    trialtype_beh_matrix = beh_matrix(:,4); %valence types including extra retrieval lure type
                    beh_matrix = beh_matrix(:,4); %get valences
                case 'none'
                    if ~isempty(options.trialtypes)
                        disp('ERROR: behavioral transformation = none & options.trialtypes has data!!!')
                        return
                    end
                    beh_matrix = beh_matrix(:,options.which_behavior); %select behavioral rating
                    trialtype_beh_matrix = NaN(size(beh_matrix)); %trial type does not matter 
            end
            
            
            
            %I havn't made the behavioral files needed for LSS_load_trialtypes()...
            %ALSO! LSS_load_trialtypes() requires "options.scans_per_run" which
            %might be weird in this dataset. Check set_options() for notes on this. 
            %NOTE2: related, you can solve this issue by resetting options.scans_per_run here 
            %based on the beh_matrix(:,3) run inds info. This would be accurate for every subject  
            
            %beh_matrix = beh_matrix(:,options.which_behavior); %select behavioral rating
            %load other trialtypes
            %trialtype_beh_matrix = LSS_load_trialtypes(options,idx);
            %collapse into single vector
            
            beh_matrix(~isnan(beh_matrix)) = 0; %mark all trials
            %watch out with the above line, may conflict with how retrieval lures are coded (also as 0)  
            beh_matrix(~isnan(trialtype_beh_matrix)) = trialtype_beh_matrix(~isnan(trialtype_beh_matrix)); %mark all other trials of interest
            subject_behavioral_data{idx,beh_idx} = beh_matrix;
        end
    end
end

for idx = 1:numel(options.subjects),
    if ismember(options.subjects(idx),options.exclusions) == 0,
        fprintf('starting subject %i\r',options.subjects(idx))
        
        subj_dir = fullfile(options.SPMdata_dir,[options.SPMsubj_dir sprintf('%02i',options.subjects(idx))]);
        file_data = cell(numel(options.runfolders),1); %preall cell array for load_fmridata
        
        %Load in scans
        for runidx = 1:numel(options.runfolders),
            my_files = prepare_fp(options,subj_dir,options.runfolders{runidx},options.scan_ft); %get filenames
            file_data{runidx} = load_fmridata(my_files,options); %load data
        end
        file_data = cat(4,file_data{:}); % cat data into matrix
        
        %Load in Masks
        mask_data = cell(numel(options.roi_list),1);
        for maskidx = 1:numel(options.roi_list),
            my_files = {fullfile(options.mask_dir,options.roi_list{maskidx})};
            mask_data{maskidx} = logical(load_fmridata(my_files,options));
        end
        mask_data = cat(4,mask_data{:});
        
        run_index = make_runindex(options,idx); %make run index
        up_run_indx = NaN(numel(run_index)*options.TR_upsample,1);
        up_run_indx(1:2:end) = run_index;
        up_run_indx(2:2:end) = run_index; %make the upsampled run index..
        trial_onsets_across_runs = subject_behavioral_data{idx};
        
        switch options.LSSmotion_params %include subject motion params
            case 'on'
                motion_parameters = load([options.motion_param_FNs num2str(options.subjects(idx)) '.txt']);
        end
        
        disp(sprintf('WARNING: hardcoded trial indexing for upsampled TR file'))
        disp(sprintf('WARNING: hardcoded hrf params LSS_trial_design_matrix() for upsampled data'))
        
        for roi_idx = 1:numel(options.roi_list)
            
            curr_mask = mask_data(:,:,:,roi_idx); %mask data
            data_matrix = apply_mask2data(curr_mask,file_data); %mask data
            %data_matrix = normalize_data(data_matrix,run_index); %detrend & zscore data runwise
            
            for runidx = 1:numel(unique(run_index))
                disp(sprintf('\t--%s-- starting run #%i',datestr(now,16),runidx))
                
                curr_run = run_index == runidx;
                trial_onsets = trial_onsets_across_runs(up_run_indx == runidx);
                trial_inds = find(~isnan(trial_onsets));
                voxel_data = data_matrix(curr_run,:); %get run voxel vector
                voxel_data = upsample_voxdata(options,voxel_data); %upsample..
                voxel_data = zscore(voxel_data); %normalize voxel data runwise
                bandpass_filter = LSS_bandpass_filter(2,32,numel(voxel_data(:,1))); %input TR, sigma, scans per run
                %NOTE: even if data is upsampled and TR = 2--- just give TR=2, sigma = 32 input to LSS_bandpass_filter()
                %Look at the formula in LSS_bandpass_filter(). It just uses those params to calculate Hz cutoff (set to 128)
                voxel_data = bandpass_filter * voxel_data; %bandpass filter data (detrends as well)
                num_trials = numel(trial_inds) / options.trial_length; %b/c of upsampling..
                if mod(numel(trial_inds),options.trial_length) ~= 0
                    disp(sprintf('ERROR: subject #%i run #%i trial checkcount',options.subjects(idx),runidx))
                end
                
                TOIbetas = NaN(num_trials,numel(voxel_data(1,:)));
                trial_starts = 1:options.trial_length:numel(trial_inds);%skip by 3s for upsampled data
                for trialidx = 1:num_trials
                    %make trial design matrix
                    Xt = LSS_trial_design_matrix(options,trial_onsets,trial_inds,trial_starts(trialidx));
                    %LSS_trial_design_matrix() is hardcoded for upsampled TR data!!!! 
                    switch options.LSSmotion_params %include subject motion params
                        case 'on'
                            Xt = [Xt motion_parameters(curr_run,:)];
                    end
                    Xt = bandpass_filter * Xt; %bandpass filter design matrix
                    switch options.LSSintercept %add an intercept if specified
                        case 'on'
                            Xt = [ones(size(trial_onsets)) Xt];
                    end
                    %estimate betas
                    Betas = ((Xt' * Xt)^-1) * (Xt' * voxel_data);
                    switch options.LSStvals
                        case 'on'
                            %get t values
                            tvals = betaTvals(options,voxel_data,Xt,Betas);
                            TOIbetas(trialidx,:) = tvals(TOIestimate_row,:);
                        case 'off'
                            %take betas for trial of interest only
                            TOIbetas(trialidx,:) = Betas(TOIestimate_row,:);
                    end
                end
                
                estimated_brains = betas2brains(TOIbetas,curr_mask);
                sv_path = fullfile(options.SPMdata_dir,num2str(options.subjects(idx)),options.runfolders{runidx});
                savefile = [fn_sv_label num2str(options.subjects(idx)) '_' num2str(runidx)];
                save(fullfile(sv_path,savefile),'estimated_brains')
            end
        end
    end
end






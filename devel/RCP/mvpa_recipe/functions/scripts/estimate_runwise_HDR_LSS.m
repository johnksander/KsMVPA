function estimate_runwise_HDR_LSS(options)


fn_sv_label = [options.LSSid '_LSS_eHDR_'];
run_index = make_runindex(options); %make run index
%make bandpass filter
bandpass_filter = LSS_bandpass_filter(2,32,options.scans_per_run(1)); %input TR, sigma, scans per run

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
    if ismember(options.subjects(idx),options.exclusions) == 1
        %Don't do anything
    else
        for beh_idx = 1:numel(options.behavioral_file_list)
            if numel(options.behavioral_file_list) > 1;disp('WARNING: multiple main behaviors specified');end
            %load all stimuli trials
            BehFname = [options.behavioral_file_list{beh_idx} '_' num2str(options.subjects(idx)) '.txt'];
            my_files = prepare_fp(options,options.TRfile_dir,BehFname);
            beh_matrix = load_behav_data(my_files,options);
            beh_matrix = beh_matrix(:,options.which_behavior); %select behavioral rating
            %load other trialtypes
            trialtype_beh_matrix = LSS_load_trialtypes(options,options.subjects(idx));
            %collapse into single vector
            beh_matrix(~isnan(beh_matrix)) = 0; %mark all trials
            beh_matrix(~isnan(trialtype_beh_matrix)) = trialtype_beh_matrix(~isnan(trialtype_beh_matrix)); %mark all other trials of interest
            subject_behavioral_data{idx,beh_idx} = beh_matrix;
        end
    end
end


for idx = 1:numel(options.subjects),
    fprintf('starting subject %i\r',options.subjects(idx))
    if ismember(options.subjects(idx),options.exclusions) == 0,
        
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
        
        
        trial_onsets_across_runs = subject_behavioral_data{idx};
        
        for roi_idx = 1:numel(options.roi_list)
            
            curr_mask = mask_data(:,:,:,roi_idx); %mask data
            data_matrix = apply_mask2data(curr_mask,file_data); %mask data
            %data_matrix = normalize_data(data_matrix,run_index); %detrend & zscore data runwise
            
            for runidx = 1:numel(unique(run_index))
                
                curr_run = run_index == runidx;
                trial_onsets = trial_onsets_across_runs(curr_run);
                trial_inds = find(~isnan(trial_onsets));
                voxel_data = data_matrix(curr_run,:); %get run voxel vector
                voxel_data = zscore(voxel_data); %normalize voxel data runwise 
                voxel_data = bandpass_filter * voxel_data; %bandpass filter data (detrends as well)
                
                trialtypes = unique(trial_onsets(~isnan(trial_onsets)));
                TOIbetas = NaN(numel(trialtypes),numel(voxel_data(1,:)));
                for trialidx = 1:numel(trialtypes)
                    
                    
                    %make trial design matrix for each trial type, one per run 
                    Xt = LSS_run_design_matrix(trial_onsets,trialtypes(trialidx),options);
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






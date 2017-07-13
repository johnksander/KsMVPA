function [brain_cells,searchlight_results] = RSA_SL_parfor_mvpa(preprocessed_SLroi_files,preproc_data_file_pointers,options)

brain_cells = cell(numel(options.roi_list));

%GOALS:::
%   0. Initialize variables and load behavioral data
%   1. make hypothesis matrix
%   3. load brain data & assemble RDM
%   4. Test RDM

%0. Initialize variables
%run_index = make_runindex(options.scans_per_run); %make run index
%runs = unique(run_index);
subject_dirs = preprocessed_SLroi_files.subject_dirs;
output_log = fullfile(options.save_dir,'output_log.txt');

%load all behavioral data for all subjs
subject_behavioral_data = cell(numel(options.subjects),numel(options.behavioral_file_list));
%find behavioral trials without proper fmri data
trials2cut = find_endrun_trials(options);
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

%1. hypothesis matrix
% Hmat = cell2mat(subject_behavioral_data);
% Hmat = Hmat(~isnan(Hmat));
% Hmat = Hmat * Hmat';
% Hmat(Hmat ~= 2) = 1; %low disimilarity
% Hmat(Hmat == 2) = 0; %high disimilarity


Hmat = options.subjects(~ismember(options.subjects,options.exclusions)); %kick out exclusions at the beginning
Hmat(Hmat < 200) = 1;
Hmat(Hmat > 200) = 2;
Hmat = Hmat' * Hmat;
Hmat(Hmat ~= 2) = 1; %low disimilarity
Hmat(Hmat == 2) = 0; %high disimilarity
%reduce to upper triangular vector
mat2vec_mask = logical(triu(ones(size(Hmat)),1));
Hmat = Hmat(mat2vec_mask);


%Begin loops
fprintf(':::Starting searchlight LOSO MVPA:::\r')

for roi_idx = 1:numel(options.roi_list)
    message = sprintf('\nROI: %s\n',options.rois4fig{roi_idx});
    disp(message)
    txtappend(output_log,[datestr(now,31) ' ' message '\n']);
    
    %load ROI general info from searchlight preprocessing, sort into original vars
    SLdata_info = load(preprocessed_SLroi_files.SLdata_info{roi_idx});
    %searchlight_inds = SLdata_info.searchlight_inds; %not used?
    seed_inds = SLdata_info.seed_inds;
    SLdata_info = SLdata_info.SLdata_info;
    %initalize output brain
    vol_size = load(preproc_data_file_pointers{1,roi_idx}); %just use first subj as template
    vol_size = size(vol_size.preprocessed_scans);
    output_brain = nan(vol_size(1),vol_size(2),vol_size(3),numel(options.behavioral_file_list));
    [seed_x,seed_y,seed_z] = ind2sub(vol_size(1:3),seed_inds);
    %easier results-to-roi file mapping
    searchlight_results = [SLdata_info.seed_fileIDs,seed_inds,NaN(numel(seed_inds),1)];
    
    %loop through searchlight roi chunk-files
    for searchlight_roifile_idx = 1:SLdata_info.total_numfiles
        %update progress to logfile
        message = sprintf('Initializing searchlight file #%i/%i',searchlight_roifile_idx,SLdata_info.total_numfiles);
        disp(message)
        txtappend(output_log,[datestr(now,31) ' ' message '\n']);
        
        %load all every subject's chunk-file
        subject_roi_files = cell(numel(options.subjects),1);
        for subject_idx = 1:numel(options.subjects)
            if ismember(options.subjects(subject_idx),options.exclusions) == 1
                %Don't do anything
            else
                subject_fileID = ['SLrois_' num2str(options.subjects(subject_idx)) '_' num2str(searchlight_roifile_idx)];
                load(fullfile(subject_dirs{subject_idx,roi_idx},subject_fileID)); %load SLroi_file
                subject_roi_files{subject_idx} = SLroi_file.searchlights;
            end
        end
        subject_roi_files = cat(4,subject_roi_files{:}); %cat to matrix, slice in parfor loop

        file_searchlight_inds = SLroi_file.inds; %this is pulling from the last loaded subject chunk-file, assumes chunk-file inds are the same across subjects
        results4brain = NaN(numel(file_searchlight_inds),numel(options.behavioral_file_list)); %for putting results back in brain after parfor loop
        parfor searchlight_idx = 1:numel(file_searchlight_inds) %parfor
            
            subject_brain_data = subject_roi_files(:,:,searchlight_idx,:);
            subject_brain_data = squeeze(subject_brain_data); %squeeze function has it's own line here just to make sure matlab slices subject_roi_files and doesn't broadcast it
            subject_brain_data = squeeze(num2cell(subject_brain_data,[1 2]));
            CVbeh_data = cell(size(subject_behavioral_data));
            
            for subject_idx = 1:numel(options.subjects)
                if ismember(options.subjects(subject_idx),options.exclusions) == 1
                    %Don't do anything
                else
                    CVbeh_data(subject_idx,:) = subject_behavioral_data(subject_idx,:); %pass behavioral data
                    run_index = make_runindex(options,subject_idx); %make run index
                    data_matrix = subject_brain_data{subject_idx};
                    data_matrix = HDRlag(options,data_matrix,run_index); %lag data, average over window (if specified)
                    data_matrix = clean_endrun_trials(data_matrix,trials2cut,subject_idx);%remove behavioral trials without proper fmri data
                    [data_matrix,CVbeh_data{subject_idx}] = select_trials(data_matrix,CVbeh_data{subject_idx});%select trials
                    %normalization/termporal compression
                    switch options.trial_temporal_compression
                        case 'on'
                            [data_matrix,CVbeh_data{subject_idx}] = temporal_compression(data_matrix,CVbeh_data{subject_idx},options);
                        case 'runwise'
                            run_index = clean_endrun_trials(run_index,trials2cut,subject_idx);%match run index to valid fmri trials
                            [data_matrix,CVbeh_data{subject_idx}] = temporal_compression_runwise(data_matrix,CVbeh_data{subject_idx},run_index);
                        case 'off'
                            %data_matrix = zscore(data_matrix); %normalize subject-wise
                    end
                    subject_brain_data{subject_idx} = data_matrix;
                end
            end
            
            subject_brain_data = cell2mat(subject_brain_data);
            switch options.feature_selection
                case 'pca_only'
                    subject_brain_data = RSA_pca(subject_brain_data,options);
            end
            subject_brain_data = zscore(subject_brain_data); %normalize across "conditions"
            behavioral_results = NaN(1,numel(options.behavioral_file_list)); %for parfor loop indexing
            
            for beh_idx = 1:numel(options.behavioral_file_list) %Cycle through valence levels, performing classification on each
                
                RDM = RSA_constructRDM(subject_brain_data,options);
                RDM = RDM(mat2vec_mask);
                %RDM = RSA_ranktransform(RDM); %still needs to be fixed for ties
                %RDM = atanh(RDM); %this isn't going to work with 1 - spearman, gives complex numbers...
                
                behavioral_results(beh_idx) = corr(RDM,Hmat,'type','Spearman');
                
            end%beh loop
            results4brain(searchlight_idx,:) = behavioral_results; %single values for each searchlight
        end%sl_roi loop
        output_brain = results2output_brain(results4brain,file_searchlight_inds,output_brain,seed_x,seed_y,seed_z,options);
        searchlight_results(searchlight_results(:,1) == searchlight_roifile_idx,3) = results4brain;
    end%file loop
    brain_cells{roi_idx} = output_brain;
end

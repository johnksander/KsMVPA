function brain_cells = xxsinglesub_searchlight(options,subject)
%original script made by drew
%0. Initialize variables
run_index = make_runindex(options.scans_per_run); %make run index
runs = unique(run_index);
num_runs = numel(runs);
num_beh = numel(options.behavioral_file_list);
run_perms = nchoosek(runs,num_runs-1); %form all possible scan run permutations -- preallocate for crossvalidation
run_perms = run_perms - min(runs) + 1; %correct permutation index
brain_cells = cell(numel(subject),2);
fprintf(':::Launching searchlights:::\r')
for idx = subject %1:numel(options.subject),
    if ismember(options.subjects(idx),options.exclusions) == 0,
        fprintf('Preparing subject %i data\r',idx)
        %load in behavioral data
        subj_dir = fullfile(options.home_dir,[options.main_dir sprintf('%02i',options.subjects(idx))]);
        behavioral_data = cell(numel(options.behavioral_file_list),1);
        for beh_idx = 1:num_beh,
            my_files = prepare_fp(options,subj_dir,'model_parametric',options.behavioral_file_list{beh_idx});
            MCQDmatrix = load_behav_data(my_files);
            MCQDmatrix = MCQDmatrix(:,options.which_behavior); %select behavioral rating
            switch options.behavioral_transformation
                case 'balanced_median_split'
                    MCQDmatrix = balanced_median_split(MCQDmatrix);
                case 'best_versus_rest'
                    
                otherwise
            end
            behavioral_data{beh_idx} = MCQDmatrix;
        end
        
        %1. Prepare data
        file_data = cell(numel(options.runfolders),1); %preallocate cell array for load_fmridata
        for run_idx = 1:numel(options.runfolders),
            my_files = prepare_fp(options,subj_dir,options.runfolders{run_idx},options.scan_ft); %get filenames
            file_data{run_idx} = load_fmridata(my_files); %load data
        end
        %--- Normalize voxel/run-wise
        normed_data = normalize_scan_data(file_data); %detrend & zscore data runwise
        
        %--- Create averaged brain for a mask
        mask_brain = cellfun(@(x) nansum(x,4),normed_data,'UniformOutput',false);
        mask_brain = cat(4,mask_brain{:});
        mask_brain = (nansum(mask_brain,4))>-1; %Include data above a threshold
        %08/12/15, tested this and it gave me a 79x95x68 logical, every voxel had a 1 (even in bounding box)
        
        %--- Precalculate searchlight indices
        [searchlight_inds,seed_inds] = preallocate_searchlights(mask_brain,...
            options.searchlight_radius); %grow searchlight sphere @ every included voxel
        
        %2. For each searchlight
        fprintf('Running subject %i searchlights\r',idx)
        normed_data = cat(4,normed_data{:}); % cat data into matrix
        vol_size = size(normed_data);
        ns = size(searchlight_inds,1);
        output_brain = nan(vol_size(1),vol_size(2),vol_size(4),num_beh);
        num_voxels = numel(seed_inds);
        for il = 1:numel(searchlight_inds(1,:)),
            if (mod(il,10000) == 0), fprintf('Completed voxel: %d / %d\n', il, num_voxels);
            end
                [seed_x,seed_y,seed_z] = ind2sub(vol_size(1:3),seed_inds);
            if sum(isnan(searchlight_inds(:,il))) == 0, %run if entire searchlight is in the brain
                [x,y,z] = ind2sub(vol_size(1:3),searchlight_inds(:,il));
                current_search = nan(vol_size(4),ns);
                for cl = 1:ns,
                    current_search(:,cl) = normed_data(x(cl),y(cl),z(cl),:);
                end
                switch options.lag_type %lag this searchlight run-wise
                    case 'single'
                    case 'average'
                        current_search = conv_TRwindow(current_search,run_index,options.running_average_window);
                        %lagged_data = averagedata_over_TRwindow(data_matrix,run_index,options.tr_delay);
                end
                current_search = HDRlag(current_search,run_index,options.tr_delay);
                for beh_idx = 1:num_beh,
                    cv_guesses = cell(num_runs,1);
                    for cv_idx = 1:num_runs,
                        cv_params = divy_cv_info(run_index,current_search,behavioral_data,run_perms,cv_idx,beh_idx);
                        %3. Feature select based on training data
                        %[wd,M,P] = zca_whiten(cv_params.training_data,options.lambda);
                        %trained_centroids = runkmeans(wd,curr_num_centroids,options.k_iterations);
                        %cv_params.fe_training_data = extract_brain_features(cv_params.training_data,trained_centroids,M,P);
                        %cv_params.fe_testing_data = extract_brain_features(cv_params.testing_data,trained_centroids,M,P);
                    	[cv_params.fe_training_data, cv_params.fe_testing_data] = pca_kmeans(cv_params,options);
                    	%2. Insert classifier
                    	cv_guesses{cv_idx} = options.classifier_type(cv_params,options);
                        %4. Insert classifier
                        cv_guesses{cv_idx} = options.classifier_type(cv_params,options);
                    end
                    %Store classification summary here
                    output_brain(seed_x,seed_y,seed_z,beh_idx) = options.cv_summary_statistic(get_accuracy(cv_guesses));
                end
            else
                output_brain(seed_x,seed_y,seed_z,:) = NaN;
            end
        end
        
        brain_cells{1} = output_brain;
        brain_cells{2} = mask_brain;
    end
end




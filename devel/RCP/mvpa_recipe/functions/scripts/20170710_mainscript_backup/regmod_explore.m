function brain_cells = regmod_roi_searchlight(options)
%reworked script, based on singlesu_searchlight.m
%0. Initialize variables
run_index = make_runindex(options.scans_per_run); %make run index
runs = unique(run_index);
num_runs = numel(runs);
num_beh = numel(options.behavioral_file_list);
run_perms = nchoosek(runs,num_runs-1); %form all possible scan run permutations -- preallocate for crossvalidation
run_perms = run_perms - min(runs) + 1; %correct permutation index
brain_cells = cell(numel(options.subjects),numel(options.roi_list));
fprintf(':::Launching searchlights:::\r')
for idx = 1:numel(options.subjects),
    if ismember(options.subjects(idx),options.exclusions) == 0,
        fprintf('Preparing subject %i data\r',idx)
        subj_dir = fullfile(options.SPMdata_dir,[options.SPMsubj_dir sprintf('%02i',options.subjects(idx))]);
        
        %load in behavioral data
        behavioral_data = cell(numel(options.behavioral_file_list),1);
        for beh_idx = 1:numel(options.behavioral_file_list),
            BehFname = [options.behavioral_file_list{beh_idx} sprintf('%02i',options.subjects(idx)) '.txt'];
            my_files = prepare_fp(options.TRfile_dir,BehFname);
            beh_matrix = load_behav_data(my_files,options);
            beh_matrix = beh_matrix(:,options.which_behavior); %select behavioral rating
            switch options.summed_behavior4regmod
                case 'on'
                    beh_matrix = sum(beh_matrix,2);
            end
            %give this a more permanent options structure
            behavioral_data{beh_idx} = beh_matrix;
        end
        
        file_data = cell(numel(options.runfolders),1); %preallocate cell array for load_fmridata
        for run_idx = 1:numel(options.runfolders),
            my_files = prepare_fp(subj_dir,options.runfolders{run_idx},options.scan_ft); %get filenames
            file_data{run_idx} = load_fmridata(my_files); %load data
        end
        file_data = cat(4,file_data{:}); % cat data into matrix
        
        %Load in Masks
        mask_data = cell(numel(options.roi_list),1);
        for maskidx = 1:numel(options.roi_list),
            my_files = {fullfile(options.mask_dir,options.roi_list{maskidx})};
            mask_data{maskidx} = logical(load_fmridata(my_files));
        end
        mask_data = cat(4,mask_data{:});
        
        for roi_idx = 1:numel(options.roi_list)
            
            disp(sprintf('\nLoading subject %i %s ROI data \n',idx,options.roi_list{roi_idx}))
            [normed_data,curr_mask] = preprocess_ROIsearchlight_data(mask_data,roi_idx,file_data,run_index);
            
            %--- Precalculate searchlight indices
            [searchlight_inds,seed_inds] = preallocate_searchlights(curr_mask,...
                options.searchlight_radius); %grow searchlight sphere @ every included voxel
            
            %2. For each searchlight
            fprintf('Running subject %i searchlights\r',idx)
            vol_size = size(normed_data);
            ns = size(searchlight_inds,1);
            output_brain = nan(vol_size(1),vol_size(2),vol_size(3),num_beh);
            num_voxels = numel(seed_inds);
            [seed_x,seed_y,seed_z] = ind2sub(vol_size(1:3),seed_inds);
            for il = 1:numel(searchlight_inds(1,:)),
                if (mod(il,10000) == 0), fprintf('Completed voxel: %d / %d\n', il, num_voxels);
                end
                if sum(isnan(searchlight_inds(:,il))) == 0, %run if entire searchlight is in the brain/ROI
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
                        cv_guesses = NaN(num_runs,1);
                        for cv_idx = 1:num_runs,
                            cv_params = divy_cv_info(run_index,current_search,behavioral_data,run_perms,cv_idx,beh_idx);
                            
                            
                            [cv_params.training_data,mu,sd] = zscore( cv_params.training_data);
                            cv_params.testing_data = bsxfun(@rdivide,bsxfun(@minus,cv_params.testing_data,mu),sd);
                            cv_params.training_data = zscore( cv_params.training_data,0,2);
                            cv_params.testing_data = zscore( cv_params.testing_data,0,2);
                            
                            TLmu = mean(cv_params.training_labels);
                            cv_params.training_labels = cv_params.training_labels - TLmu;
                            cv_params.testing_labels = cv_params.testing_labels - TLmu;
                            
                            
                            X_data = cv_params.training_data;
                            X_int = ones(numel(cv_params.training_labels),1);
                            Xreg = cat(2,X_int,X_data); %
                            Yreg = cv_params.training_labels; %Replace with your DV
                            Betas = (Xreg'*Xreg + options.regression_lambda) \ Xreg'*Yreg;
                            predicted_labels = cat(2,ones(size(cv_params.testing_data,1),1),cv_params.testing_data) * Betas;
                            TSS = sumsqr(cv_params.testing_labels - mean(cv_params.testing_labels));
                            RSS = sumsqr(cv_params.testing_labels - predicted_labels);
                            r_sq = (TSS-RSS)/TSS;
                            cv_guesses(cv_idx) = r_sq;
                        end
                        %Store classification summary here
                        output_brain(seed_x(il),seed_y(il),seed_z(il),beh_idx) = mean(cv_guesses);
                    end
                else
                    output_brain(seed_x(il),seed_y(il),seed_z(il),:) = NaN;
                end
            end
            
            brain_cells{idx,roi_idx} = output_brain;
        end
    end
end




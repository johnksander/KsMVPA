function subject_cells = roi_connectivity(options)
%GOALS:::
%   0. Initialize variables and load behavioral data
%   1. Prepare brain data
%   2. Calculate connectivity

%0. Initialize variables
run_index = make_runindex(options.scans_per_run); %make run index
num_subjects = numel(options.subjects);
subject_cells = cell(num_subjects,2);

%Begin loops
fprintf(':::Beginning ROI connectivity:::\r')
for idx = 1:numel(options.subjects)
    if ismember(options.subjects(idx),options.exclusions) == 1
        %Don't do anything
    else
        fprintf('starting subject #%i\r',idx)
        %0. load in behavioral data
        subj_dir = fullfile(options.home_dir,[options.main_dir sprintf('%02i',options.subjects(idx))]);
        behavioral_data = cell(numel(options.behavioral_file_list),1);
        for beh_idx = 1:numel(options.behavioral_file_list),
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
        normed_data = normalize_scan_data(file_data); %detrend & zscore data runwise.
        
        %2. Select l/r amy and l/r hippo -- need to add options.roi_logical to options
        roi_id = find(options.roi_logical);
        roi_search_cells = cell(numel(roi_id),2);
        for roi_idx = 1:numel(roi_id),
            my_files = {fullfile(options.home_dir,options.mask_dir,options.roi_list{roi_id(roi_idx)})};
            mask_brain = logical(load_fmridata(my_files));
            [roi_search_cells{roi_idx,1},roi_search_cells{roi_idx,2}] = ...
                preallocate_searchlights(mask_brain,options.searchlight_radius); %grow searchlight sphere @ every included voxel
        end
        
        %3. Perform connectivity analysis between all pairwise ROI combinations
        
        vol_size = size(mask_brain);
        combo_inds = nchoosek(1:numel(roi_id),2); %all pairwise combinations
        num_combos = numel(combo_inds(:,1));
	num_behaviors = numel(behavioral_data);
        connectivity_mat = nan(num_combos,num_behaviors);
	mask_names = cell(size(combo_inds));
        for roi_idx = 1:num_combos,
            fprintf('Started mask combo %i / %i\r',roi_idx,num_combos);
            master_search = roi_search_cells{combo_inds(roi_idx,1),2}; %only using center voxel for now
            slave_search = roi_search_cells{combo_inds(roi_idx,2),2};
	    mask_names{roi_idx,1} = options.roi_list{roi_id(combo_inds(roi_idx,1))};
	    mask_names{roi_idx,2} = options.roi_list{roi_id(combo_inds(roi_idx,2))};
            conn_mat = nan(numel(master_search),num_behaviors);
            for m_idx = 1:numel(master_search),
                [mx,my,mz] = ind2sub(vol_size,master_search(m_idx));
                master_data = cellfun(@(i) squeeze(i(mx,my,mz,:)),normed_data,'UniformOutput',false);
		master_data = cat(1,master_data{:});
                %Account for HDR here
                switch options.lag_type %lag this searchlight run-wise
                    case 'single'
                    case 'average'
                        master_data = conv_TRwindow(master_data,run_index,options.running_average_window);
                end
                master_data = voxellag(master_data,run_index,options.tr_delay);
                for s_idx = 1:numel(slave_search),
                    [sx,sy,sz] = ind2sub(vol_size,slave_search(s_idx));
                    slave_data = cellfun(@(i) squeeze(i(sx,sy,sz,:)),normed_data,'UniformOutput',false);
                    slave_data = cat(1,slave_data{:});
		    %Account for HDR here
                    switch options.lag_type %lag this searchlight run-wise
                        case 'single'
                        case 'average'
                            slave_data = conv_TRwindow(slave_data,run_index,options.running_average_window);
                    end
                    slave_data = voxellag(slave_data,run_index,options.tr_delay);
                    for bi = 1:num_behaviors
                        bi_idx = behavioral_data{bi};
                        bi_idx = ~isnan(bi_idx);
                        conn_mat(m_idx,bi) = options.connection_measure(master_data(bi_idx),slave_data(bi_idx));
                    end
                end
            end
            connectivity_mat(roi_idx,:) = mean(conn_mat);
        end
    end
    subject_cells{idx,1} = connectivity_mat;
    subject_cells{idx,2} = mask_names;
end

function lagged_data = voxellag(data,run_index,num_delay)
num_delay = num_delay + 1;

runs = unique(run_index);
num_runs = numel(runs);
lagged_data = data;
for idx = 1:num_runs;
    td = data(run_index==idx);
    lagged_data(run_index==idx) = cat(1,td(num_delay:end),repmat(mean(td),num_delay-1,1));
end

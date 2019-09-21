function preprocessed_SLroi_files = SLroi_filelocs(options)

if floor(options.searchlight_radius) ~= options.searchlight_radius %integer check
    main_outputdir = num2str(options.searchlight_radius);
    main_outputdir = strsplit(main_outputdir,'.');
    main_outputdir = fullfile(options.preproc_data_dir,['SLroidata_' 'radius_' main_outputdir{1} '_' main_outputdir{2}]);
elseif floor(options.searchlight_radius) == options.searchlight_radius %integer check
    main_outputdir = fullfile(options.preproc_data_dir,['SLroidata_' 'radius_' num2str(options.searchlight_radius)]);
end

subject_dirs = cell(numel(options.subjects),numel(options.roi_list));
for roi_idx = 1:numel(options.roi_list)
    for idx = 1:numel(options.subjects)
        if ismember(options.subjects(idx),options.exclusions) == 1
            %Don't do anything
        else
            subject_dirs{idx,roi_idx} = fullfile(main_outputdir,[options.rois4fig{roi_idx} '_' num2str(options.subjects(idx))]);
        end
    end
end

preprocessed_SLroi_files.main_outputdir = main_outputdir;
preprocessed_SLroi_files.subject_dirs = subject_dirs;
preprocessed_SLroi_files.SLdata_info = cell(numel(options.roi_list),1);


for roi_idx = 1:numel(options.roi_list)
    preprocessed_SLroi_files.SLdata_info{roi_idx} = fullfile(main_outputdir,[options.rois4fig{roi_idx} '_searchlight_indicies']);
end


end


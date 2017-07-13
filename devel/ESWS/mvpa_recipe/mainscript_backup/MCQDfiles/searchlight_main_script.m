matlabpool open

options = set_options('/home/ksander/unwhitened_roi_dir_03302015/'); %ROI MVPA
ms_subjects = options.subjects(~ismember(options.subjects,options.exclusions));


searchlight_output = cell(numel(options.subjects),1);

parfor parloop_idx = ms_subjects
searchlight_output{parloop_idx} = singlesub_searchlight(options,parloop_idx);
end
save(fullfile(options.home_dir,'mvpa_recipe','searchlight_output'))
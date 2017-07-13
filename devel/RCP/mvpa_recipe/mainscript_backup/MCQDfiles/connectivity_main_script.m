%Main script for running MCQD ROI analyses

format compact

% ROI Preprocess
options = set_options('/home/ksander/unwhitened_roi_dir_03302015/'); %ROI MVPA
%roi_subject_file_pointers = preprocess_data(options);
%save(fullfile(options.output_dir,'file_pointers'),'roi_subject_file_pointers');
load(fullfile(options.output_dir,'file_pointers'))

%ROI mvpa
connectivity_output = roi_connectivity(options);
save(fullfile(options.output_dir,'roi_connectivity_output'),'connectivity_output')

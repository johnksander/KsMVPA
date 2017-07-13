%Main script for running MCQD ROI analyses

% ROI Preprocess
options = set_options('/Users/kensinel/Desktop/ksander/unwhitened_roi_dir_03302015/'); %ROI MVPA
roi_subject_file_pointers = preprocess_data(options);
save(fullfile(options.output_dir,'file_pointers'),'roi_subject_file_pointers');

% LOSO Preprocess
options = set_options('/home/ksander/unwhitened_LOSO_roi_dir_03302015/'); %LOSO MVPA
LOSO_subject_file_pointers = LOSO_preprocess_data(options);
save(fullfile(options.output_dir,'file_pointers'),'LOSO_subject_file_pointers');

%----

%ROI mvpa
roi_output = mvpa(roi_subject_file_pointers,options);
roi_statistics = summarize_mvpa(roi_output,options);
save(fullfile(options.output_dir,'roi_output_stats'),'roi_output','roi_statistics');

%LOSO mvpa
LOSO_output = LOSO_roi_mvpa(LOSO_subject_file_pointers,options);%fix 4 pleiades
LOSO_statistics = summarize_mvpa(LOSO_output,options);
save(fullfile(options.output_dir,'LOSO_output_stats'),'LOSO_output','LOSO_statistics');

%Searchlight mvpa
searchlight_output = searchlight(options);

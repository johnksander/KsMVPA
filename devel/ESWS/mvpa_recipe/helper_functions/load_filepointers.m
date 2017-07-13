function subj_filepointers = load_filepointers(options)
load(fullfile(options.preproc_data_dir,'preproc_data_file_pointers.mat'))
subj_filepointers = preproc_data_file_pointers;
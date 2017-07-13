


preproc_data_file_pointers = load(fullfile(options.preproc_data_dir,'preproc_data_file_pointers.mat'));
preproc_data_file_pointers = preproc_data_file_pointers.preproc_data_file_pointers;

preproc_data_file_pointers = strrep(preproc_data_file_pointers,'/ESWS_MVPA/','/KsMVPA/');
save(fullfile(options.preproc_data_dir,'preproc_data_file_pointers'),'preproc_data_file_pointers');
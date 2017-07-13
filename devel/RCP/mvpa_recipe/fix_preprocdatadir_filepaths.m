


preproc_data_file_pointers = load(fullfile(options.preproc_data_dir,'preproc_data_file_pointers.mat'));
preproc_data_file_pointers = preproc_data_file_pointers.preproc_data_file_pointers;

olddir = '/home/acclab/Desktop/ksander/holly_mvpa/';
newdir = '/data/netapp/jksander/RCPholly/';

for idx = 1:numel(preproc_data_file_pointers)
    preproc_data_file_pointers{idx} = strrep(preproc_data_file_pointers{idx},olddir,newdir);
end
save(fullfile(options.preproc_data_dir,'preproc_data_file_pointers'),'preproc_data_file_pointers');


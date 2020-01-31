


preproc_data_file_pointers = load(fullfile(options.preproc_data_dir,'preproc_data_file_pointers.mat'));
preproc_data_file_pointers = preproc_data_file_pointers.preproc_data_file_pointers;

%hpc to linus/woodstock
%newdir = '/home/acclab/Desktop/ksander/holly_mvpa/';
%olddir = '/data/netapp/jksander/RCPholly/';

%linus/woodstock to harvard
%newdir = '/ncf/mri/01/users/ksander/RCP/';
%olddir = '/home/acclab/Desktop/ksander/holly_mvpa/';

%harvard to bender
newdir = '/Users/ksander/Desktop/work/KsMVPA/devel/RCP/';
olddir = '/users/ksander/RCP/KsMVPA_h/';

for idx = 1:numel(preproc_data_file_pointers)
    preproc_data_file_pointers{idx} = strrep(preproc_data_file_pointers{idx},olddir,newdir);
end
save(fullfile(options.preproc_data_dir,'preproc_data_file_pointers'),'preproc_data_file_pointers');


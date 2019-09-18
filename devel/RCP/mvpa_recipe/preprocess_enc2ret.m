clear
clc
format compact

%make RDMs from encoding data using ROIs of the significant clusters found
%at encoding. Use that encoding analysis' data procedures via loading the
%options structure from its results. 

%05/09/2018: hacky conn_subdir stuff added for testing connectivity schemes. 
%Pulls manually saved options file from that subdirectory.

enc_job = 'RSA_SL_1p5_ASGM_encval_conn26';
conn_subdir = 'conn_scheme_26'; %testing different connectivity scheme, pull from subdir 
%breaking with the usual set_options() set up since we're loading an options
%struture anyways.
basedir = '/home/acclab/Desktop/ksander/holly_mvpa/KsMVPA_h/';
scriptdir = fullfile(basedir,'mvpa_recipe');
helperdir = fullfile(scriptdir,'helper_functions');
addpath(helperdir)
res_dir = fullfile(basedir,'Results');
res_dir = fullfile(res_dir,[enc_job '_stats']);
res_dir = fullfile(res_dir,conn_subdir);
optFN = [enc_job '_stats_voxel_null.mat'];
optFN = 'options_file';%quick hack for conn subdir... 
options = load(fullfile(res_dir,optFN),'options'); %load encoding options profile 
options = options.options; 
options = set_bigmem_options2linus(options); %reset the paths, if needed (works on woodstock)
%give a new save_dir. This is for encoding RDM data, also for
%backing up this job code (backup_jobcode()) without overwriting 
options.save_dir = fullfile(options.save_dir,'enc2ret_data'); 
%add paths & spm 
addpath(options.script_function_dir);
addpath(options.helper_function_dir);
addpath(options.classifier_function_dir);
addpath(options.searchlight_function_dir);
addpath(options.stat_function_dir);
%addpath('/ncf/mri/01/users/ksander/RCP/spm12');
%addpath('/data/netapp/jksander/spm12');
addpath('/home/acclab/Desktop/ksander/spm12')
%select_linus_spm('spm12');

encRDMs = preprocess_enc2ret_data(options);

%---cleanup-------------------
driverfile = mfilename;
backup_jobcode(driverfile,options)
%give it a better name
buFN = fullfile(options.save_dir,['code4' options.name '.zip']);
movefile(buFN,fullfile(options.save_dir,'code4preproc.zip'))




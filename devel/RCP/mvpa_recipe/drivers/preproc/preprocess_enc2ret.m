clear
clc
format compact

%make RDMs from encoding data using ROIs of the significant clusters found
%at encoding. Use that encoding analysis' data procedures via loading the
%options structure from its results. 

enc_job = 'RSA_SL_1p5_VMGM_encodingValence';
stats_dir = 't-stat_conn_6'; %testing different connectivity scheme, pull from subdir 
%breaking with the usual set_options() set up since we're loading an options
%struture anyways.
basedir = '/home/acclab/Desktop/ksander/holly_mvpa/KsMVPA_h/';
scriptdir = fullfile(basedir,'mvpa_recipe');
helperdir = fullfile(scriptdir,'functions','helpers');
addpath(helperdir)
res_dir = fullfile(basedir,'Results',enc_job,'stats',stats_dir);
options = load(fullfile(res_dir,'stat_outcomes.mat'),'options'); %load encoding options profile 
options = options.options;
options = reset_optpaths(options,'woodstock'); %reset the paths, if needed 
%give a new save_dir. This is for encoding RDM data, also for
%backing up this job code (backup_jobcode()) without overwriting 
options.save_dir = fullfile(options.save_dir,'enc2ret_data'); 
%add paths & spm 
addpath(options.script_function_dir);
addpath(options.helper_function_dir);
addpath(options.classifier_function_dir);
addpath(options.searchlight_function_dir);
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




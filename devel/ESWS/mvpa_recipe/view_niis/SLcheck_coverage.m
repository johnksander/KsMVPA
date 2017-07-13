clear
clc
format compact

addpath('../')
aname = 'LOSOSL_rebuild_test';

config_options.name = aname;
config_options.dataset = 'ESWS';
config_options.analysis = 'LOSO_SL';
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | dart_LSS_eHDR | 'anatom' | 'estimatedHDR_spm'
config_options.LSSid = 'ASGM'; %LSS model ID
config_options.analysis_method = 'classification';
config_options.behavioral_transformation = 'origin_split';
config_options.behavioral_measure = 'allstim';
config_options.TR_delay = 0;
config_options.TR_avg_window = 0;
config_options.remove_endrun_trials = 2;
config_options.searchlight_radius = 2.5;
config_options.classifier = @knn;
config_options.result_dir = aname;


options = set_options(config_options);
options.roi_list = {'gray_matter.nii'};
options.rois4fig = {'gray_matter'};


preproc_data_file_pointers = PreprocDataFP_handler(options,[],'load'); %reconcile filepointers

preprocessed_SLroi_files = SLroi_filelocs(options); % get SL inds, info etc 

SLinfo = load(preprocessed_SLroi_files.SLdata_info{1});
SLinds = SLinfo.searchlight_inds;

%load a volume 

examp_scan = load_nii('w3danat.nii');
fakescan = int16(zeros(size(examp_scan.img)));
fakescan(SLinds(:)) = 1; %put ones in in valid searchlights 

examp_scan.img = fakescan;

save_nii(examp_scan,'searchlight_coverage.nii')


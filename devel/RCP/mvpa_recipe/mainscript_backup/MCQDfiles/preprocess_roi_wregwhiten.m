clear 
clc
format compact

% config_options.name = 'Aro_MCQ_roi_preprocess';
% config_options.dataset = 'Aro_MCQ';%Del_MCQ/Aro_MCQ
% config_options.analysis = 'roi';%loso, preprocess w/e
% config_options.TRlag = 3;%TR lag
% config_options.TR_avg_window = 2;%TR window to average over
% config_options.classifier = @minpool;
% config_options.result_dir = 'test';
% 
% 
% options = set_options(config_options);
% 
% preproc_data_file_pointers = preprocess_data(options);

config_options.name = 'Del_MCQ_roi_preprocess_wregwhiten';
config_options.dataset = 'Del_MCQ';%Del_MCQ/Aro_MCQ
config_options.analysis = 'roi';%loso, preprocess w/e
config_options.TRlag = 2;%TR lag
config_options.TR_avg_window = 2;%TR window to average over
config_options.classifier = @minpool;
config_options.result_dir = 'test';


options = set_options(config_options);
options.preproc_data_dir = '/home/ksander/vividness_mvpa/Data/Del_MCQ/preprocessed_scan_data/roi_wregwhiten';
if ~isdir(options.preproc_data_dir)
    mkdir(options.preproc_data_dir)
end

preproc_data_file_pointers = preprocess_data_wregwhiten(options);
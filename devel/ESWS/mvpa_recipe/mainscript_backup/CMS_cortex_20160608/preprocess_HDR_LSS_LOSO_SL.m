clear 
clc
format compact

config_options.name = 'ESWS_LOSO_SL_preprocess_eHDRspm';
config_options.dataset = 'ESWS';%Del_MCQ/Aro_MCQ
config_options.analysis = 'LOSO_SL';
config_options.dataset = 'ESWS';%Del_MCQ/Aro_MCQ
config_options.rawdata_type = 'unsmoothed_raw'; % 'estimatedHDR_spm' | 'unsmoothed_raw' |'LSS_eHDR'
config_options.analysis_method = 'classification';
config_options.behavioral_measure = 'allstim';
config_options.behavioral_transformation = 'origin_split';
config_options.TRlag = 2;%TR lag
config_options.TR_avg_window = 2;%TR window to average over 
config_options.searchlight_radius = 1.5;
config_options.classifier = @minpool;
config_options.result_dir = 'LOSO_searchlight_preprocessing';


options = set_options(config_options);

estimate_HDR_LSS(options);
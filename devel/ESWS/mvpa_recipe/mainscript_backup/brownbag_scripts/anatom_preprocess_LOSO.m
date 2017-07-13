clear 
clc
format compact

config_options.name = 'ESWS_anatom_LOSO_VTC_preprocess';
config_options.dataset = 'ESWS';%Del_MCQ/Aro_MCQ
config_options.analysis = 'LOSO';
config_options.dataset = 'ESWS';%Del_MCQ/Aro_MCQ
config_options.rawdata_type =  'anatom'; % 'estimatedHDR_spm' | 'unsmoothed_raw' |'LSS_eHDR' | 'anatom'
config_options.analysis_method = 'classification';
config_options.behavioral_measure = 'allstim';
config_options.behavioral_transformation = 'origin_split';
config_options.TRlag = 0;%TR lag
config_options.TR_avg_window = 0;%TR window to average over
config_options.lag_type = 'single'; %'single' | %'average'
config_options.searchlight_radius = 1.5;
config_options.classifier = @minpool;
config_options.result_dir = 'anatom_LOSO_VTC_preprocessing';

options = set_options(config_options);
options.roi_list = {'left_vtc.nii','right_vtc.nii'};   
options.rois4fig = {'left_vtc','right_vtc'}; 

    
    
preproc_data_file_pointers = LOSO_preprocess_data_anatom(options);
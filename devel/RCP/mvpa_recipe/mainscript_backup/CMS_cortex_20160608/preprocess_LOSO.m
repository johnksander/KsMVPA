clear 
clc
format compact

config_options.name = 'ESWS_LOSO_HPFU_preprocess';
config_options.dataset = 'ESWS';%Del_MCQ/Aro_MCQ
config_options.analysis = 'LOSO';
config_options.dataset = 'ESWS';%Del_MCQ/Aro_MCQ
config_options.rawdata_type =  'dartel_raw'; % 'estimatedHDR_spm' | 'unsmoothed_raw' |'LSS_eHDR' | 'anatom'
config_options.analysis_method = 'classification';
config_options.behavioral_measure = 'allstim';
config_options.behavioral_transformation = 'origin_split';
config_options.TRlag = 0;%TR lag
config_options.TR_avg_window = 0;%TR window to average over
config_options.lag_type = 'single'; %'single' | %'average'
config_options.searchlight_radius = 1.5;
config_options.classifier = @minpool;
config_options.result_dir = config_options.name;

options = set_options(config_options);
%options.roi_list = {'left_hippocampus.nii','right_hippocampus.nii','left_fusiform.nii','right_fusiform.nii'};   
%options.rois4fig = {'left_hippocampus','right_hippocampus','left_fusiform','right_fusiform'};  
options.roi_list = {'left_fusiformHO.nii','right_fusiformHO.nii','left_hippocampus.nii','right_hippocampus.nii'};   
options.rois4fig = {'left_fusiform','right_fusiform','left_hippocampus','right_hippocampus'};  


preproc_data_file_pointers = LOSO_preprocess_data(options);


% options.roi_list = {'left_anterior_TL_medial.nii','right_anterior_TL_medial.nii','left_TL_lateral.nii','right_TL_lateral.nii',...
%         'left_superior_TL_posterior.nii', 'right_superior_TL_posterior.nii', 'left_middle_and_inferior_TG.nii',...
%         'right_middle_and_inferior_TG.nii','left_posterior_TL.nii','right_posterior_TL.nii',...
%         'left_superior_TG_anterior.nii','right_superior_TG_anterior.nii'};  
% 
% options.rois4fig = {'left_anterior_TL_medial','right_anterior_TL_medial','left_TL_lateral','right_TL_lateral',...
%         'left_superior_TL_posterior', 'right_superior_TL_posterior', 'left_middle_and_inferior_TG',...
%         'right_middle_and_inferior_TG','left_posterior_TL','right_posterior_TL',...
%         'left_superior_TG_anterior','right_superior_TG_anterior'};  
%  
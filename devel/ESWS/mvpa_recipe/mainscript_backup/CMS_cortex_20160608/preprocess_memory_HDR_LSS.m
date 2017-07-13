clear 
clc
format compact

config_options.name = 'ESWS_LOSO_preprocess_LSSeHDR';
config_options.dataset = 'ESWS';%Del_MCQ/Aro_MCQ
config_options.analysis = 'LOSO';
config_options.dataset = 'ESWS';%Del_MCQ/Aro_MCQ
config_options.rawdata_type = 'dartel_raw'; % 'estimatedHDR_spm' | 'unsmoothed_raw' |'LSS_eHDR'
config_options.analysis_method = 'classification';
config_options.behavioral_measure = 'allstim';
config_options.behavioral_transformation = 'origin_split';
config_options.TRlag = 2;%TR lag
config_options.TR_avg_window = 2;%TR window to average over 
config_options.lag_type = 'single'; %'single' | %'average'
config_options.searchlight_radius = 1.5;
config_options.classifier = @minpool;
config_options.result_dir = 'LSS_memory_preproc';


options = set_options(config_options);
options.TOIbehavior = {'ESWS_TsameRsame'};

estimate_memory_HDR_LSS(options);

% 04/23/1016: need to do LOSO preprocessing with ROI masks, this just give
% you the whole brain. The script functions will load whatever the
% prerpoc_file_pointers give them, you need to re-preprocess new brains w/
% roi masks to get the proper file_pointer files. 


% 01/29/2016: HDR LSS already estimated with whole brain mask, this should be fine for
%all other ROIs. Can check this by loading in whole brain mask & roi masks
%and using code below: 


% for idx = 1:numel(options.roi_list)
%    curr_mask = vtc_masks(:,:,:,idx); 
%    wb_mask_roi = wb_mask(curr_mask);
%    curr_mask = curr_mask(curr_mask);
% 
%    same_voxels = ismember(curr_mask,wb_mask); 
%    disp(sprintf('%s voxels not in whole brain mask = %i',options.roi_list{idx},sum(same_voxels ~= 1)))
%  
% end


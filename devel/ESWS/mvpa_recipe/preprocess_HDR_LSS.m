clear 
clc
format compact

config_options.name = 'ESWS_LOSO_preprocess_LSSeHDR';
config_options.dataset = 'ESWS';
config_options.analysis = 'LOSO';
config_options.rawdata_type = 'unsmoothed_raw'; % dartel_raw | 'unsmoothed_raw' 
config_options.analysis_method = 'classification';
config_options.behavioral_measure = 'allstim';
config_options.behavioral_transformation = 'origin_split';
config_options.TR_delay = 0;%TR lag
config_options.TR_avg_window = 0;%TR window to average over 
config_options.remove_endrun_trials = 0;
config_options.searchlight_radius = 0;
config_options.classifier = @minpool;
config_options.result_dir = 'LSS_memory_preproc';


options = set_options(config_options);
options.LSSid = 'ASGMmp10'; %LSS model ID 
options.trialtypes = {}; %just estimate all trials 
%options.trialtypes = {'ESWS_TsameRsame'};
options.LSSintercept = 'on';
options.LSStvals = 'on';
options.LSSmotion_params = 'on';
options.roi_list = {'gray_matter_10thr.nii'};   
options.rois4fig = {'gray_matter'};  


estimate_HDR_LSS(options);
%estimate_runwise_HDR_LSS(options);



% 06/08/2016: all trials must be loaded as behavioral_file_list, individual trail types loaded afterwards in options.trialtypes

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


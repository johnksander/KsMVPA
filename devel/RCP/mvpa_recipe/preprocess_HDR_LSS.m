clear 
clc
format compact

aname = 'RCP_ASGM_preproc';
num_workers = 32; %upsampling is parfor'd

%----name---------------------------------------------------
config_options.name = aname;
config_options.result_dir = aname;
%----experiment---------------------------------------------
config_options.dataset = 'RCP';
%----analysis-----------------------------------------------
config_options.analysis = 'searchlight';
config_options.CVscheme = 'none';
config_options.trial_temporal_compression = 'off'; 
config_options.feature_selection = 'off';
config_options.normalization = 'off'; 
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'unsmoothed_raw'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom' 
config_options.LSSid = 'ASGM'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 1.5;
config_options.roi_list = {'gray_matter.nii'};   
config_options.rois4fig = {'gray_matter'};  
%----TR-settings--------------------------------------------
config_options.TR_delay = 0;
config_options.TR_avg_window = 0;
config_options.remove_endrun_trials = 0;
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'none';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = @GNB; %only matters for adding GNB func paths  
config_options.performance_stat = 'none'; %accuracy | Fscore
%----------------------------------------------------------- 
options = set_options(config_options);  
%----LSS-estimation-settings--------------------------------
%options.trialtypes = {'Rneg','Rneu','Rpos','notR'}; 
%options.trialtypes = {'Rneg','Rneu','Rpos'}; %I think "not R" just gets all the trials that aren't specified here..  
options.trialtypes = {}; %just estimate all trials 
options.LSSintercept = 'on';
options.LSStvals = 'on';
options.LSSmotion_params = 'off';
options.LSSid = 'ASGM'; %reset LSS id, set_options doesn't want to take it for unsmoothed_raw parameter
options.TR_upsample = 2; %assuming 2 second TRs, upsample each to 1 second events
options.trial_length = 3; %in seconds, also for upsampled data.. 
%----------------------------------------------------------- 


addthis = which('spm_interp'); %fucker
c = parcluster('local');
c.NumWorkers = num_workers;
parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',{addthis})

estimate_HDR_LSS(options);
delete(gcp('nocreate'))


%configuration for "RGM model 
% config_options.behavioral_transformation = 'R';
% options.trialtypes = {'Rneg','Rneu','Rpos'}; %I think "not R" just gets all the trials that aren't specified here..  
% options.LSSintercept = 'on';
% options.LSStvals = 'on';
% options.LSSmotion_params = 'off';
% options.LSSid = 'RGM'; %reset LSS id, set_options doesn't want to take it for unsmoothed_raw parameter





%RCP behavior info
% val_labels = {'neg','neu','pos','dis'};
% val_inds = [1 2 3 0]; %neg, neu, pos numeric labels (zero is lure)
% response_labels = {'R','K','N'};
% response_inds = [1 2 3]; %R, K, N numeric labels


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


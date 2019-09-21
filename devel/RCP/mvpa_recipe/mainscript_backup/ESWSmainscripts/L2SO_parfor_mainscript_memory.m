clear
clc
format compact

aname = 'L2SO_mem_HPFU_comp_LDA';
num_workers = 4; %parpool workers

%----name---------------------------------------------------
config_options.name = aname;
config_options.result_dir = aname;
%----experiment---------------------------------------------
config_options.dataset = 'ESWS';
%----analysis-----------------------------------------------
config_options.analysis = 'LOSO';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom' 
config_options.LSSid = 'MGM'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 0;
%----TR-settings--------------------------------------------
config_options.TR_delay = 0;
config_options.TR_avg_window = 0;
config_options.remove_endrun_trials = 2; 
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'origin_split';
config_options.behavioral_measure = 'memory';
%----classifier---------------------------------------------
config_options.classifier = @LDA;
%-----------------------------------------------------------


options = set_options(config_options);
options.roi_list = {'left_fusiformHO.nii','right_fusiformHO.nii','left_hippocampus.nii','right_hippocampus.nii'};
options.rois4fig = {'left_fusiform','right_fusiform','left_hippocampus','right_hippocampus'};
options.exclusions = [115 202 208];
options.trial_temporal_compression = 'on';
options.feature_selection = 'off';

preproc_data_file_pointers = load(fullfile(options.preproc_data_dir,'preproc_data_file_pointers'));
preproc_data_file_pointers = preproc_data_file_pointers.preproc_data_file_pointers;

classifer_file = fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m']);
c = parcluster('local');
c.NumWorkers = num_workers;
parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',{classifer_file})

predictions = L2SO_roi_parfor_mvpa(preproc_data_file_pointers,options);
delete(gcp('nocreate'))

save(fullfile(options.save_dir,[options.name '_predictions']),'predictions','options')


for idx = 1:numel(options.roi_list)
    roi_pred = predictions(:,idx);
    roi_pred = vertcat(roi_pred{:});
    roi_pred = (sum(roi_pred(:,1) == roi_pred(:,2))) / numel(roi_pred(:,1));
    disp(sprintf('%s classification accuracy %.2f%% \n',options.rois4fig{idx},(roi_pred*100)))
end

for idx = 1:numel(options.roi_list)
    roi_pred = predictions(:,idx);
    roi_pred = vertcat(roi_pred{:});
    figure(idx)
    imagesc(roi_pred)
end


% for idx = 1:numel(options.roi_list)
%     roi_pred = predictions(:,idx);
%     for cellidx = 1:numel(roi_pred)
%         curr_cell = roi_pred{cellidx};
%         if ~isempty(curr_cell)
%             curr_cell = curr_cell(:,1);
%             if sum(curr_cell == 0) > 0
%                 disp(sprintf('roi: %i, subject #%i',idx,options.subjects(cellidx)))
%             end
%         else
%         end
%     end
%     roi_pred = vertcat(roi_pred{:});
%     figure(idx)
%     imagesc(roi_pred)
% end


%which_behavior 1 = conf, 2 = vivid, 3 = feel, 4 = order, 5 = thoughts
%subj_filepointers = load_filepointers(options);

%primary_analysis_output = regression_model(subj_filepointers,options);


%
% %primary_analysis_output = mvpa(subj_filepointers,options);
% save(fullfile(options.save_dir,options.classification_fname),'primary_analysis_output','options')
%
% statistics_output = summarize_mvpa(primary_analysis_output,options);
% save(fullfile(options.save_dir,options.statistics_fname),'statistics_output','primary_analysis_output','options');
%
% jk_get_permstats(statistics_output,primary_analysis_output,options)
% jk_mkfig_from_perm(options)
% jk_mkfig_4MCC_from_perm(options)

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
%
%

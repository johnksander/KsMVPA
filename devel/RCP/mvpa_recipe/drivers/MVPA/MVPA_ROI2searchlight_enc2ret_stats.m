clear
clc
format compact

resname = 'MVPA_ROI2searchlight_2p5_ASGM_enc2ret';
enc_job = 'RSA_SL_1p5_ASGM_encodingValence'; %encoding results to pull
permname = [resname '_stats'];


%----name---------------------------------------------------
config_options.name = permname;
config_options.result_dir = permname;
%----experiment---------------------------------------------
config_options.dataset = 'RCP';
%----analysis-----------------------------------------------
config_options.analysis = 'searchlight';
config_options.CVscheme = 'none';
config_options.normalization = 'runwise';
config_options.trial_temporal_compression = 'off'; 
config_options.feature_selection = 'off';
%----evaluation---------------------------------------------
config_options.cluster_conn = 26;
config_options.cluster_effect_stat = 'extent';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom' 
config_options.LSSid = 'ASGM'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 2.5;
config_options.roi_list = {'gray_matter.nii'};   
config_options.rois4fig = {'gray_matter'};  
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'enc2ret_valence';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = 'linear'; 
config_options.performance_stat = 'accuracy'; 
%----------------------------------------------------------- 
options = set_options(config_options);
options.parforlog = 'off';
options.PCAcomponents2keep = 60;
options.num_perms = 100;
options.enc_job = enc_job; %put the enc job in options 
main_save_dir = options.save_dir; %we're going to save results in subdirs 


%load searchlight results for all ROIs 
output_log = fullfile(options.save_dir,'stats_output_log.txt');
update_logfile('loading searchlight results',output_log)
searchlight_results = load(fullfile(options.home_dir,'Results',resname,[resname '_braincells.mat']));
searchlight_results = searchlight_results.searchlight_cells;
num_encROIs = find(~ismember(options.subjects,options.exclusions),1,'first'); %grab a valid subject index
num_encROIs = size(searchlight_results{num_encROIs},2) - 1;
update_logfile(sprintf('----Encoding ROIs found: %i',num_encROIs),output_log)


for idx = 1:num_encROIs
    
    update_logfile(sprintf('Loading data for encoding ROI #%i',idx),output_log)
    %ROI_results = cellfun(@(x) [x(:,1),x(:,idx+1)],searchlight_results,'Uniformoutput',false);
    %blah... this doesn't work b/c of empty cells & not sure if it'll take an if statement or something...
    ROI_results = cell(size(searchlight_results));
    voxel_null = cell(size(searchlight_results));
    for subject_idx = 1:numel(options.subjects)
        if ~isempty(searchlight_results{subject_idx})
            curr_cell = searchlight_results{subject_idx};
            %take the searchlight indicies (1st col) and ROI results (idx + 1)
            ROI_results{subject_idx} = [curr_cell(:,1),curr_cell(:,idx+1)];
            %load the null distribution for this subject & ROI
            subject_null = sprintf('subject_%i_encROI%i.mat',options.subjects(subject_idx),idx);
            subject_null = load(fullfile(main_save_dir,'files',subject_null));
            subject_null = subject_null.voxel_null;
            voxel_null{subject_idx} = subject_null;
        end
    end
    
    %make ROI specfic savedir 
    options.save_dir = fullfile(main_save_dir,...
        sprintf('conn_scheme_%i',options.cluster_conn),sprintf('ROI_%i_results',idx));
    if strcmp(options.cluster_effect_stat,'t-stat')
        options.save_dir = fullfile(options.save_dir,'cluster_t-stat');end
    if ~isdir(options.save_dir),mkdir(options.save_dir);end

    %here's the statistics
    searchlight_stats = map_searchlight_significance(ROI_results,voxel_null,options);
    
    
    %---cleanup-------------------
    driverfile = mfilename;
    backup_jobcode(driverfile,options)
    
end



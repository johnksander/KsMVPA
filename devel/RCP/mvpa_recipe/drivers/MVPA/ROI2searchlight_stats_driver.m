clear
clc
format compact
options = set_options('name','MVPA_R2SL_2p5_enc2ret_k80','location','bender',...
    'enc_job','RSA_SL_1p5_ASGM_encodingValence',...
    'cluster_conn',26,'cluster_effect_stat','extent',...
    'searchlight_radius',2.5,'classifier_type','linear',...
    'PCAcomponents2keep',80);


main_save_dir = fullfile(options.save_dir,'stats'); %we're going to save results in subdirs 


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
            subject_null = load(fullfile(options.save_dir,'perm_files',subject_null));
            subject_null = subject_null.voxel_null;
            voxel_null{subject_idx} = subject_null;
        end
    end
    
    %make ROI specfic savedir 
    options.save_dir = fullfile(main_save_dir,...
        sprintf('%s_conn_%i',options.cluster_effect_stat,options.cluster_conn),...
        sprintf('ROI_%i_results',idx));
    
    if ~isdir(options.save_dir),mkdir(options.save_dir);end

    %here's the statistics
    map_searchlight_significance(ROI_results,voxel_null,options);
    
    
    %---cleanup-------------------
    driverfile = mfilename;
    backup_jobcode(driverfile,options)
    
end




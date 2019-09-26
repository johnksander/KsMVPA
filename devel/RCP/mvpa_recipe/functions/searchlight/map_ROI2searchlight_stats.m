function map_ROI2searchlight_stats(options)
%this is just a wrapper for using map_searchlight_significance()
%in ROI-to-searchlight analyses (i.e. encoding-to-retreival analyses)


main_save_dir = options.save_dir; %we're going to save results in subdirs

%load searchlight results for all ROIs
output_log = fullfile(options.save_dir,'stats_output_log.txt');
update_logfile('loading searchlight results',output_log)
searchlight_results = fullfile(options.home_dir,'Results','%s','%s_braincells.mat');
searchlight_results = sprintf(searchlight_results,options.name,options.name);
searchlight_results = load(searchlight_results);
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
            subject_null = load(fullfile(main_save_dir,'perm_files',subject_null));
            subject_null = subject_null.voxel_null;
            voxel_null{subject_idx} = subject_null;
        end
    end
    
    %make ROI specfic savedir
    options.save_dir = fullfile(main_save_dir,'stats',...
        sprintf('%s_conn_%i',options.cluster_effect_stat,options.cluster_conn),...
        sprintf('ROI_%i_results',idx));
    
    if ~isdir(options.save_dir),mkdir(options.save_dir);end
    
    %here's the statistics
    map_searchlight_significance(ROI_results,voxel_null,options);
    
    
    %---cleanup-------------------
    driverfile = mfilename;
    backup_jobcode(driverfile,options)
    
end




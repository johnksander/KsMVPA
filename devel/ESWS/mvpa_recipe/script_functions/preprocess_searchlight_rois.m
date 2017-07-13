function preprocessed_SLroi_files = preprocess_searchlight_rois(preproc_data_file_pointers,options)

roiFNlabels = regexp(options.roi_list, '.nii', 'split'); %make labels for saved preproc data based on real mask FN
roiFNlabels = vertcat(roiFNlabels{:});
roiFNlabels = roiFNlabels(:,1);

searchlights_per_file = options.SL_per_file;

fprintf(':::preallocating searchlight roi_data:::\r')

%make output directories

if floor(options.searchlight_radius) ~= options.searchlight_radius %integer check
    main_outputdir = num2str(options.searchlight_radius);
    main_outputdir = strsplit(main_outputdir,'.');
    main_outputdir = fullfile(options.preproc_data_dir,['SLroidata_' 'radius_' main_outputdir{1} '_' main_outputdir{2}]);
elseif floor(options.searchlight_radius) == options.searchlight_radius %integer check
    main_outputdir = fullfile(options.preproc_data_dir,['SLroidata_' 'radius_' num2str(options.searchlight_radius)]);
end

mkdir(main_outputdir)
save(fullfile(main_outputdir,'options'),'options');
output_log = fullfile(main_outputdir,'preproc_log.txt'); %unique output log names


disp(sprintf('\nCreating directories\n'))
subject_dirs = cell(numel(options.subjects),numel(options.roi_list));
for roi_idx = 1:numel(options.roi_list)
    for idx = 1:numel(options.subjects)
        if ismember(options.subjects(idx),options.exclusions) == 1
            %Don't do anything
        else
            subject_dirs{idx,roi_idx} = fullfile(main_outputdir,[roiFNlabels{roi_idx} '_' num2str(options.subjects(idx))]);
            if ~isdir(subject_dirs{idx,roi_idx})
                mkdir(subject_dirs{idx,roi_idx})
            end
        end
    end
end

preprocessed_SLroi_files.subject_dirs = subject_dirs;
preprocessed_SLroi_files.main_outputdir = main_outputdir;
preprocessed_SLroi_files.SLdata_info = cell(numel(options.roi_list),1);


for roi_idx = 1:numel(options.roi_list)
    disp(sprintf('\nStrarting roi #%i %s ...',roi_idx,options.rois4fig{roi_idx}))
    
    %load commonvox mask
    commonvox_mask = spm_read_vols(spm_vol(fullfile(options.preproc_data_dir,['commonvox_' options.roi_list{roi_idx}])));
    fprintf('Finding searchlight indicies\r')
    %--- Precalculate searchlight indices
    [searchlight_inds,seed_inds] = preallocate_searchlights(commonvox_mask,options.searchlight_radius); %grow searchlight sphere @ every included voxel
    disp(sprintf('Complete, saving searchlight indicies\n'))
    total_numfiles = ceil(numel(seed_inds) / searchlights_per_file); %total number of files (ceil includes extra for last scans if not evenly divisible)
    SLdata_info.total_numfiles = total_numfiles;
    SLdata_info.numseeds = numel(seed_inds);
    SLdata_info.seed_fileIDs = floor([0:(numel(seed_inds) - 1)]'/ searchlights_per_file) + 1; %which file roi belongs to
    SLdata_info.searchlights_per_file = searchlights_per_file;
    save(fullfile(main_outputdir,[roiFNlabels{roi_idx} '_searchlight_indicies']),'searchlight_inds','seed_inds','SLdata_info');
    
    preprocessed_SLroi_files.SLdata_info{roi_idx} = fullfile(main_outputdir,[roiFNlabels{roi_idx} '_searchlight_indicies']);
    
    for idx = 1:numel(options.subjects)
        if ismember(options.subjects(idx),options.exclusions) == 1
            %Don't do anything
        else
            message = sprintf('\r   Starting subject %i\r-------------------------',options.subjects(idx));
            disp(message)
            txtappend(output_log,[datestr(now,31) ' ' message '\n']);
            %load preprocessed scans
            preprocessed_scans = load(preproc_data_file_pointers{idx,roi_idx});
            preprocessed_scans = preprocessed_scans.preprocessed_scans;
            %initialize searchlight roi file indicies
            vol_size = size(preprocessed_scans);
            ns = size(searchlight_inds,1);
            %output_brain = nan(vol_size(1),vol_size(2),vol_size(3),num_beh);
            %[seed_x,seed_y,seed_z] = ind2sub(vol_size(1:3),seed_inds);
            curr_file_idx = repmat([1:searchlights_per_file]',total_numfiles,1); %each seed's position in its file
            curr_file_idx = curr_file_idx(1:SLdata_info.numseeds); %remove indicies for filler scans @ end
            filechunks = NaN(total_numfiles,2); %each file's first/last scan
            filechunks(:,1) = find(curr_file_idx == 1);
            if mod(SLdata_info.numseeds,searchlights_per_file) > 0
                filestops = find(curr_file_idx == searchlights_per_file);
                filestops = [filestops;SLdata_info.numseeds];
                filechunks(:,2) = filestops; %put actual last scan in for final stop
            else
                filechunks(:,2) = find(curr_file_idx == searchlights_per_file);
            end
            
            %filemaker loop
            for chunkidx = 1:total_numfiles
                if mod(chunkidx,20) == 0
                    message = sprintf('Subject %i: Initalizing %s file #%i/%i',...
                        options.subjects(idx),options.rois4fig{roi_idx},chunkidx,total_numfiles);
                    disp(message)
                    txtappend(output_log,[datestr(now,31) ' ' message '\n']);
                end
                
                roi_chunk = NaN(vol_size(4),ns,searchlights_per_file);
                curr_SLinds = [filechunks(chunkidx,1):filechunks(chunkidx,2)]'; %first & last searchlight seeds for this file
                
                if numel(curr_SLinds) ~= searchlights_per_file & chunkidx ~= total_numfiles
                    disp(sprintf('\nWARNING: unexpected searchlight count found in roi file #%i\n',chunkidx))
                    %saftey check, throw warning if something funny happens
                end
                
                parfor il = 1:numel(curr_SLinds)
                    
                    real_il = curr_SLinds(il); %actual searchlight index
                    current_search =  SLroi_searchwrapper(preprocessed_scans,searchlight_inds,vol_size,ns,real_il);
                    %                     [x,y,z] = ind2sub(vol_size(1:3),searchlight_inds(:,real_il));
                    %                     current_search = nan(vol_size(4),ns);
                    %                     for cl = 1:ns,
                    %                         current_search(:,cl) = preprocessed_scans(x(cl),y(cl),z(cl),:);
                    %                     end %code moved to SLroi_searchwrapper function in order to elimate preprocessed scans as a broadcast var
                    roi_chunk(:,:,il) = current_search;
                end
                
                SLroi_file.searchlights = roi_chunk;
                SLroi_file.inds = curr_SLinds;
                save(fullfile(subject_dirs{idx,roi_idx},['SLrois_' num2str(options.subjects(idx)) '_' num2str(chunkidx)]),'SLroi_file')
                
            end
               
        end
    end
end




function subject_data = xxextract_scans_drewfile(main_dir,target_dir,file_name,ext,keep_cols)

scan_files = dir(fullfile(main_dir,target_dir));
if sum(cat(1,scan_files(:).isdir)) == numel(scan_files), %look in subdirectories
    subject_data = cell(size(scan_files));
    for idx = 1:numel(scan_files),
        sub_files = dir(fullfile(main_dir,scan_files(idx).name,strcat('*',ext)));
        sub_files = {sub_files(:).name};
        exclude = cellfun(@isempty,cellfun(@(x) regexp(x,file_name),sub_files,'UniformOutput',false));
        sub_files(exclude) = [];
        if exist('keep_cols','var')
            sub_files = sub_files(keep_cols);
        end
        dummy_file = (spm_vol(...
            fullfile(main_dir,scan_files(idx).name,sub_files(1))));
        dummy_file = spm_read_vols(dummy_file{1});
        subject_data{idx} = nan(size(dummy_file,1),size(dummy_file,2),size(dummy_file,3),numel(sub_files));
        subject_data{idx}(:,:,:,1) = dummy_file;
        for il = 2:numel(sub_files)
            dummy_file = (spm_vol(...
                fullfile(main_dir,scan_files(idx).name,sub_files(il))));
            subject_data{idx}(:,:,:,il) = spm_read_vols(dummy_file{1});
        end
    end
    
else
    %figure this out at some point...
end
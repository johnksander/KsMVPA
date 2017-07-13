function data_mat = load_fmridata(filepointer_cells,options)
%runwise


switch options.rawdata_type
    case {'unsmoothed_raw','dartel_raw'}
        data_mat = spm_read_vols(spm_vol(filepointer_cells{1}));
    case {'LSS_eHDR','SPMbm'}
        data_type = filepointer_cells{1}((end - 2):end);
        switch data_type %this is for loading mask files, they'll be .niis
            case 'mat'
                data_mat = load(filepointer_cells{1});
                data_mat = data_mat.estimated_brains;
            case 'nii'
                data_mat = spm_read_vols(spm_vol(filepointer_cells{1}));
        end
    case 'anatom'
        data_mat = spm_read_vols(spm_vol(filepointer_cells{1}));
%     case 'estimatedHDR_spm'
%         data_mat = cell(numel(filepointer_cells),1);
%         for scanidx = 1:numel(data_mat)
%             data_mat{scanidx} = spm_read_vols(spm_vol(filepointer_cells{scanidx}));
%         end
%         data_mat = cat(4,data_mat{:}); % cat data into matrix
end













%     dummy = spm_read_vols(spm_vol(filepointer_cells{1}));
%     vol_size = size(dummy);
%     %Declare vars
%     data_mat = NaN(vol_size(1),vol_size(2),vol_size(3),numel(filepointer_cells));
%     for idx = 1:numel(filepointer_cells);
%         data_mat(:,:,:,idx) = spm_read_vols(spm_vol(filepointer_cells{idx}));
%     end
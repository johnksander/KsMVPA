function upsamp_data = upsample_voxdata(options,voxel_data)
%upsample voxel data 

upsamp_data = NaN(size(voxel_data,1) * options.TR_upsample, size(voxel_data,2));

parfor voxidx = 1:size(voxel_data,2)
    curr_vox = voxel_data(:,voxidx);
    upsamp_data(:,voxidx) = spm_interp(curr_vox,options.TR_upsample);    
end

%up_run_ids = reshape(repmat(run_ids,TR_upsample,1),[],1);

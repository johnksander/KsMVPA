function  searchlight_brain_data = bigmem_searchlight_wrapper(subject_brain_data,vol_size,searchlight_inds)

num_subjects = size(subject_brain_data,5);
num_timepoints = size(subject_brain_data,4);
num_voxels = size(searchlight_inds,1);
num_searchlights = size(searchlight_inds,2);
searchlight_brain_data = NaN(num_timepoints,num_voxels,num_searchlights,num_subjects);



for idx = 1:num_searchlights
    
    
    [x,y,z] = ind2sub(vol_size,searchlight_inds(:,idx));
    current_searchlight = nan(num_timepoints,num_voxels,num_subjects);
    
    for voxidx = 1:num_voxels
        current_searchlight(:,voxidx,:) = subject_brain_data(x(voxidx),y(voxidx),z(voxidx),:,:);
    end
    
    searchlight_brain_data(:,:,idx,:) = current_searchlight;
end





% 
% searchlight_brain_data = cell(num_subjects,1);
% 
% 
% for idx = 1:num_subjects
%     
%     [x,y,z] = ind2sub(vol_size,searchlight_inds);
%     current_searchlight = nan(num_timepoints,num_voxels);
%     
%     for voxidx = 1:num_voxels
%         current_searchlight(:,voxidx) = subject_brain_data(x(voxidx),y(voxidx),z(voxidx),:,idx);
%     end
%     
%     searchlight_brain_data{idx} = current_searchlight;
% end
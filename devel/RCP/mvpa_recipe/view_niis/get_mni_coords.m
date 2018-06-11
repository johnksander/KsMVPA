clear
clc
format compact

basedir = '/home/acclab/Desktop/ksander/ESWS/ESWS_results';
cd(basedir)
addpath('/home/acclab/Desktop/ksander/KsMVPA/mvpa_recipe/Nifti_Toolbox');

results = load_nii(fullfile(basedir,'significant_cluster_seeds.nii')); 
origin = results.hdr.hist.originator(1:3);
scan_image = results.img;
voxel_inds = find(scan_image);
[x,y,z] = ind2sub(size(scan_image),voxel_inds);
voxel_coords = [x y z];
voxel_coords = bsxfun(@minus,voxel_coords,origin); %reset voxel inds to origin 
mni_coords = voxel_coords * 2; %MNI coords for searchlight  centers 

%now, get brodmann areas 
BAatlas = load_nii(fullfile(basedir,'brodmann.nii.gz'));
%get corresponding voxel coords in BA atlas 
BA_vox_coords = voxel_coords * 2; %atlas is 1mm vox 
BA_vox_coords = bsxfun(@plus,BA_vox_coords,BAatlas.hdr.hist.originator(1:3)); %adjust by atlas origin 
brodmann_areas = NaN(numel(voxel_inds),1);
for idx = 1:numel(voxel_inds)
    brodmann_areas(idx) = BAatlas.img(BA_vox_coords(idx,1),BA_vox_coords(idx,2),BA_vox_coords(idx,3));
end
%there it is
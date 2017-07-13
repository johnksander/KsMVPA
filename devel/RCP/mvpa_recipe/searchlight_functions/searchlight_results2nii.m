function searchlight_results2nii(significant_cluster_sizes,seed_cluster_info,options)
%make nifti files for significant searchlights
%one file with only seed centers, one file with whole searchlight space


vs = options.scan_vol_size;


%1. nifti for seed centers
cluster_size_th = min(significant_cluster_sizes);
sig_seeds = seed_cluster_info(:,2) >= cluster_size_th;
sig_seeds = seed_cluster_info(sig_seeds,1);
results2show = zeros(vs);
results2show(sig_seeds) = 1;
%do nifti tricks 
template_scan = load_nii(fullfile(options.script_dir,'view_niis','w3danat.nii')); %load template nifti file
template_scan.img = results2show;
template_scan.hdr.dime.datatype = 64; %reset to double (so decimals will work..)
template_scan.hdr.dime.bitpix = 64;
save_nii(template_scan,fullfile(options.save_dir,'significant_cluster_seeds.nii'))

%2. nifti for whole searchlight area
%get searchlight inds 
[x,y,z] = ind2sub(vs,sig_seeds);
num_searchlights = numel(sig_seeds);
mc = round(num_searchlights/2); %make a dummy searchlight to get volume 
dummy_searchlight = draw_searchlight(vs,x(mc),y(mc),z(mc),options.searchlight_radius);
sig_searchlight_inds = nan(sum(dummy_searchlight(:)),num_searchlights);
for idx = 1:num_searchlights
    sphere_voxels = draw_searchlight(vs,x(idx),y(idx),z(idx),options.searchlight_radius);
    sphere_voxels = find(sphere_voxels);
    sig_searchlight_inds(:,idx) = sphere_voxels;    
end
sig_searchlight_inds = unique(sig_searchlight_inds); 
%do nifti tricks 
results2show = zeros(vs);
results2show(sig_searchlight_inds) = 1;
template_scan = load_nii(fullfile(options.script_dir,'view_niis','w3danat.nii')); %load template nifti file
template_scan.img = results2show;
template_scan.hdr.dime.datatype = 64; %reset to double (so decimals will work..)
template_scan.hdr.dime.bitpix = 64;
save_nii(template_scan,fullfile(options.save_dir,'significant_searchlights.nii'))







function sphere_voxels = draw_searchlight(vs,x,y,z,searchlight_radius)

[emptyx, emptyy, emptyz] = meshgrid(1:vs(2),1:vs(1),1:vs(3));
sphere_voxels = logical((emptyx - y(1)).^2 + ...
            (emptyy - x(1)).^2 + (emptyz - z(1)).^2 ...
            <= searchlight_radius.^2); %adds a logical searchlight mask centered on the coordinates sphere_x/y/z_coord



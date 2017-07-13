function [searchlight_inds,id] = preallocate_searchlights(bd,searchlight_radius)
%bd is the mask
%searchlight_radius... searchlight size
vs = size(bd);
id = find(bd);
keep_spheres = logical(ones(size(id))); %08/12/2015, added if statement to only keep spheres fully within ROI space
[x,y,z] = ind2sub(vs,id);
xnum = numel(x);
mc = round(xnum/2);
dummy_searchlight = draw_searchlight(vs,x(mc),y(mc),z(mc),searchlight_radius);
searchlight_inds = nan(sum(dummy_searchlight(:)),xnum);
fprintf('Preallocating searchlights\n')
for idx = 1:xnum
    if (mod(idx,10000) == 0), fprintf('Working on voxel: %d / %d\n', idx, xnum); end
    sphere_voxels = draw_searchlight(vs,x(idx),y(idx),z(idx),searchlight_radius);
    padded_ids = find(sphere_voxels);
    padded_ids = cat(1,padded_ids,...
        nan(numel(searchlight_inds(:,1))-numel(padded_ids),1));
    searchlight_inds(:,idx) = padded_ids;
    
    if min(ismember(padded_ids,id)) == 0 %08/12/2015, added if statement to only keep spheres fully within ROI space
        keep_spheres(idx) = 0;
        searchlight_inds(:,idx) = nan(size(padded_ids));
    end
    
end


searchlight_inds = searchlight_inds(:,keep_spheres); %08/12/2015, added to only keep spheres fully within ROI space
id = id(keep_spheres); %08/12/2015, added to only keep spheres fully within ROI space




function sphere_voxels = draw_searchlight(vs,x,y,z,searchlight_radius)

[emptyx, emptyy, emptyz] = meshgrid(1:vs(2),1:vs(1),1:vs(3));
sphere_voxels = logical((emptyx - y(1)).^2 + ...
            (emptyy - x(1)).^2 + (emptyz - z(1)).^2 ...
            <= searchlight_radius.^2); %adds a logical searchlight mask centered on the coordinates sphere_x/y/z_coord

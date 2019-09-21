function [searchlight_inds,id] = searchlights_on_seeds(bd,searchlight_radius)

%this function was made specifically for drawing ROIs based on searchlight
%cluster seeds (searchlight center voxels) from a positive analysis result. 
%Often, multiple cluster's searchlight volumes will overlap so a cluster 
%search returns the incorrect number of clusters (if run on the full SL
%volumes). This function recreates the original (seperate) searchlight
%cluster volumes based on their seeds. Takes one cluster at a time. 


%bd is the mask
%searchlight_radius... searchlight size
vs = size(bd);
id = find(bd);
[x,y,z] = ind2sub(vs,id);
xnum = numel(x);
mc = round(xnum/2);
dummy_searchlight = draw_searchlight(vs,x(mc),y(mc),z(mc),searchlight_radius);
searchlight_inds = nan(sum(dummy_searchlight(:)),xnum);

fprintf('Growing searchlights on significant cluster seeds\n')
fprintf('----seeds found: %i\n',xnum)
fprintf('WARN: THIS FUNCTION DOES NOT CHECK FOR VALID ROI BOUNDARIES\n')
fprintf('WARN: USE preallocate_searchlights() FOR SEARCHLIGHT ANALYSIS\n')

for idx = 1:xnum
    sphere_voxels = draw_searchlight(vs,x(idx),y(idx),z(idx),searchlight_radius);
    padded_ids = find(sphere_voxels);
    padded_ids = cat(1,padded_ids,...
        nan(numel(searchlight_inds(:,1))-numel(padded_ids),1));
    searchlight_inds(:,idx) = padded_ids;
    

    
end

function sphere_voxels = draw_searchlight(vs,x,y,z,searchlight_radius)

[emptyx, emptyy, emptyz] = meshgrid(1:vs(2),1:vs(1),1:vs(3));
sphere_voxels = logical((emptyx - y(1)).^2 + ...
            (emptyy - x(1)).^2 + (emptyz - z(1)).^2 ...
            <= searchlight_radius.^2); %adds a logical searchlight mask centered on the coordinates sphere_x/y/z_coord

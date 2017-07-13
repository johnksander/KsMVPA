function [data_cells_BVremoved] = remove_badvoxels4cells(data_cells)

%bad_voxels = cellfun(@(x) isnan(x) | x == 0, data_cells,'UniformOutput',false);
bad_voxels = cellfun(@(x) isnan(x), data_cells,'UniformOutput',false); %only remove nan voxels, leave 0 voxels 
bad_voxels = sum(cat(1,bad_voxels{:}))>0; 
fprintf('\r--Removing %d Bad Voxels\r',sum(bad_voxels))
disp('       Only NaN voxels removed')
for bv = 1:numel(data_cells),
    this_cell = data_cells{bv};
    if isempty(this_cell)
        continue
    end
    data_cells{bv} = this_cell(:,~bad_voxels);
end
data_cells_BVremoved = data_cells;
end

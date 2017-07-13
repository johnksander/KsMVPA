function  current_search = SLroi_searchwrapper(preprocessed_scans,searchlight_inds,vol_size,ns,real_il)


[x,y,z] = ind2sub(vol_size(1:3),searchlight_inds(:,real_il));
current_search = nan(vol_size(4),ns);

for cl = 1:ns
    current_search(:,cl) = preprocessed_scans(x(cl),y(cl),z(cl),:);
end



function new_image = xxextent_threshold_drewfile(image, k)

mask = image;
if sum(isnan(mask(:))) > 0,
    mask(mask==0)=NaN;
    mask = ~isnan(mask);
    mask(isnan(mask)) = 0;
    mask(mask~=0) = 1;
    mask = logical(mask);
end
mask_clusters = bwconncomp(mask,6);
num_pixels = cellfun(@numel,mask_clusters.PixelIdxList);
pl = mask_clusters.PixelIdxList(num_pixels > k);
new_image = zeros(size(image));
new_image(cat(1,pl{:})) = 1;

function results_brain2nii(options)


load(fullfile(options.save_dir,[options.name '_braincells']));
results = brain_cells{1};
%results = results * 100; %rescale
%results(isnan(results)) = 0;

template_scan = load_nii(fullfile(options.script_dir,'view_niis','w3danat.nii')); %load template nifti file 
template_scan.img = results;
template_scan.hdr.dime.datatype = 64; %reset to double (so decimals will work..)
template_scan.hdr.dime.bitpix = 64;
save_nii(template_scan,fullfile(options.save_dir,[options.name '.nii']))

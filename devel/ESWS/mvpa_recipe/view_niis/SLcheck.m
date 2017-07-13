
addpath('../Nifti_Toolbox/')
examp_scan = load_nii('w3danat.nii');
fakescan = int16(zeros(size(examp_scan.img)));
%add2scan = searchlight_inds(~isnan(searchlight_inds));
%fakescan(add2scan(:)) = 1;

% fakescan(logical(updated_mask)) = 1; 
% examp_scan.img = fakescan;


newres = load_nii('LOSO_SL_ASGM_SPMbm.nii');
newres = newres.img;

curr_output = curr_output > 0;
examp_scan.img = commonvox_maskdata;

examp_scan.img = newres > .15;

save_nii(examp_scan,'resultmap_test.nii')
%resultsmap original file was > .55



examp_scan.img = results;
save_nii(examp_scan,'missing_vox.nii')

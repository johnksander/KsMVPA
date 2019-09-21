clear
clc
format compact
%all paths must be loaded beforehand

linus_home_dir = '/home/acclab/Desktop/ksander/KsMVPA/';
lins_script_dir = fullfile(linus_home_dir,'mvpa_recipe');
result_dir = fullfile(linus_home_dir,'Results','LOSO_SL_ASGM_comp_bigmem_r1p5_p');
result_file = dir(fullfile(result_dir,'*braincells.mat'));
load(fullfile(result_dir,result_file.name))

correction = 'bonferroni';

switch correction
    case 'FDR'
        
        %FDR threshold
        n = numel(searchlight_results(:,1)); %num searchlights
        q = 0.05; %alpha (FDR)
        %c = 1; %independance
        c = sum([1:n].^-1); %no independance
        x = (1:n)'/n*q/c; %compare this to sorted pvalues
        
    case 'bonferroni'
        n = numel(searchlight_results(:,1)); %num searchlights
        a = .05; %alpha
        x = a/n;
        
end

%get results, find significant searchlights
pvals = searchlight_results(:,3);

pvals = permutation_results(:,2);
[pvals,i] = sort(pvals);
sig_results = pvals <= x;
sig_map = zeros(size(pvals)); %map sorted pvals back to seed index locs
sig_map(i(sig_results)) = 1;
% rvals = searchlight_results(:,2);
% rvals = rvals(i);

%get output brain
seed_inds = searchlight_results(:,1);
vol_size = options.scan_vol_size;
output_brain = nan(vol_size(1),vol_size(2),vol_size(3),numel(options.behavioral_file_list));
[seed_x,seed_y,seed_z] = ind2sub(vol_size(1:3),seed_inds);
%map pvals to output brain
output_brain = results2output_brain(sig_map,[1:numel(seed_inds)],output_brain,seed_x,seed_y,seed_z,options);

%save p-map as nii file
template_scan = load_nii(fullfile(lins_script_dir,'view_niis','w3danat.nii')); %load template nifti file
template_scan.img = output_brain;
template_scan.hdr.dime.datatype = 64; %reset to double (so decimals will work..)
template_scan.hdr.dime.bitpix = 64;
save_nii(template_scan,fullfile(result_dir,[options.name '_pmap.nii']))


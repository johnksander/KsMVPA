clear
clc
format compact

%10/03/2019: now takes sats & connection config from saved options file 

basedir = '/home/acclab/Desktop/ksander/holly_mvpa/KsMVPA_h/';
job_name = 'RSA_SL_1p5_VMGM_encodingValence';
stats_dir = 't-stat_conn_6'; %testing different connectivity scheme, pull from subdir 
makeROI = 'volumes'; % seeds | volumes

res_dir = fullfile(basedir,'Results',job_name,'stats',stats_dir);
options = load(fullfile(res_dir,'stat_outcomes.mat'),'options'); %load encoding options profile 
options = options.options;
options = reset_optpaths(options,'woodstock');

cluster_conn = options.cluster_conn; %this needs to match the cluster_search() that produced results
SLradius = options.searchlight_radius; %only relevant for seeds

%maskdir = fullfile(basedir,'maskdir');
NTdir = fullfile(basedir,'mvpa_recipe','Nifti_Toolbox');
addpath(NTdir)
addpath(options.searchlight_function_dir)
%select_linus_spm('spm12')

%now fix up the res dir & pull results
save_dir = fullfile(res_dir,'enc2ret_data');
if ~isdir(save_dir),mkdir(save_dir);end

switch makeROI
    case 'volumes'
        rFN = 'significant_searchlights.nii';
    case 'seeds'
        rFN = 'significant_cluster_seeds.nii';
end

template_file = load_nii(fullfile(res_dir,rFN));
sig_clusters = load_nii(fullfile(res_dir,rFN));
sig_clusters = sig_clusters.img;
volsz = size(sig_clusters);

%cluster connectivity scheme (6, 18, or 26)
%cluster_conn = 6; %this needs to match the cluster_search() that produced results
vol_clusters = bwconncomp(sig_clusters,cluster_conn); %find clusters
vol_clusters = vol_clusters.PixelIdxList; %cluster inds

nROI = numel(vol_clusters);
outvol = zeros([volsz nROI]); %make one nii file for all the significant clusters
for idx = 1:nROI
    
    ROI = zeros(volsz); %cluster linear inds assume this size
    ROI(vol_clusters{idx}) = 1;
    
    switch makeROI 
    %grow searchlights based on original radius (make sure that's right!)
    case 'seeds'
        fprintf('\nROI#%i voxels at radius %.1f\n',idx,SLradius)
        fprintf('----seeds: %i\n',sum(ROI(:)))
        [vol_inds,~] = searchlights_on_seeds(ROI,SLradius);
        ROI(vol_inds(:)) = 1;
        fprintf('----volumes: %i\n',sum(ROI(:)))
    end
    
    outvol(:,:,:,idx) = ROI;
end


disp(sprintf('\n---- %s mode',makeROI))
disp(sprintf('n ROIs found = %i',nROI))

voxsz = [2 2 2]; %harcoded!!!
vol_origin = template_file.hdr.hist.originator;
vol_origin = vol_origin(1:3);
ROInii = make_nii(outvol,voxsz,vol_origin);

save_nii(ROInii,fullfile(save_dir,'results_mask.nii'))
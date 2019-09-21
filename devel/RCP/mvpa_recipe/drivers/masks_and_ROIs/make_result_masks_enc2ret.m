clear
clc
format compact

%05/09/2018: note- just added "conn_subdir" stuff to test different
%connectivity schemes. This just looks in a result subdirectory. I also
%moved the "cluster_conn=" specification up to the top, since that's relevant!

job_name = 'RSA_SL_1p5_ASGM_encodingValence';
conn_subdir = 'conn_scheme_26/cluster_t-stat'; %testing different connectivity scheme, pull from subdir 
cluster_conn = 26; %this needs to match the cluster_search() that produced results
SLradius = 1.5; %only relevant for seeds
makeROI = 'seeds'; % seeds | volumes

basedir = '/home/acclab/Desktop/ksander/holly_mvpa/KsMVPA_h/';
%maskdir = fullfile(basedir,'maskdir');
NTdir = fullfile(basedir,'mvpa_recipe','Nifti_Toolbox');
SLdir = fullfile(basedir,'mvpa_recipe','searchlight_functions');
result_dir = fullfile(basedir,'Results');
addpath(NTdir)
addpath(SLdir)
%select_linus_spm('spm12')

%now fix up the res dir & pull results
result_dir = fullfile(result_dir,[job_name '_stats']);
result_dir = fullfile(result_dir,conn_subdir); %testing different connectivity scheme, pull from subdir 
save_dir = fullfile(result_dir,'enc2ret_data');
if ~isdir(save_dir),mkdir(save_dir);end

switch makeROI
    case 'volumes'
        rFN = 'significant_searchlights.nii';
    case 'seeds'
        rFN = 'significant_cluster_seeds.nii';
end

template_file = load_nii(fullfile(result_dir,rFN));
sig_clusters = load_nii(fullfile(result_dir,rFN));
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
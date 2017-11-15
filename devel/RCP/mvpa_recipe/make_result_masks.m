clear
clc
format compact

job_name = 'RSA_SL_1p5_ASGM_enc2ret';
SLradius = 1.5; %only relevant for seeds
makeROI = 'volumes'; % seeds | volumes
voxsz = [2 2 2]; %harcoded!!!

basedir = '/home/acclab/Desktop/ksander/holly_mvpa/KsMVPA_h/';
maskdir = fullfile(basedir,'maskdir');
NTdir = fullfile(basedir,'mvpa_recipe','Nifti_Toolbox');
SLdir = fullfile(basedir,'mvpa_recipe','searchlight_functions');
result_dir = fullfile(basedir,'Results');
addpath(NTdir)
addpath(SLdir)
addpath(fullfile(basedir,'mvpa_recipe','helper_functions')); %....
%select_linus_spm('spm12')

%now fix up the res dir & pull results
result_dir = fullfile(result_dir,[job_name '_stats']);

switch makeROI
    case 'volumes'
        rFN = 'significant_searchlights.nii';
    case 'seeds'
        rFN = 'significant_cluster_seeds.nii';
end


%get only the ROI result subdirectories that contain sig results
ROIdirs = rdir(fullfile(result_dir,'ROI*',rFN));
ROIdirs = {ROIdirs.name};
ROIdirs = cellfun(@(x) strsplit(x,'/'),ROIdirs,'UniformOutput',false);
ROIdirs = cellfun(@(x) x{end-1},ROIdirs,'UniformOutput',false);
num_encROIs = numel(ROIdirs);
disp(sprintf('n encoding ROIs found = %i',num_encROIs))


for enc_idx = 1:num_encROIs
    
    fprintf('----loading ROI file #%i\n',enc_idx)
    curr_resFN = fullfile(result_dir,ROIdirs{enc_idx},rFN);
    template_file = load_nii(curr_resFN);
    vol_origin = template_file.hdr.hist.originator;
    vol_origin = vol_origin(1:3);
    sig_clusters = load_nii(curr_resFN);
    sig_clusters = sig_clusters.img;
    volsz = size(sig_clusters);
    
    %cluster connectivity scheme (6, 18, or 26)
    cluster_conn = 6; %this needs to match the cluster_search() that produced results
    vol_clusters = bwconncomp(sig_clusters,cluster_conn); %find clusters
    vol_clusters = vol_clusters.PixelIdxList; %cluster inds
    
    nROI = numel(vol_clusters);
    disp(sprintf('\n---- %s mode',makeROI))
    disp(sprintf('n ROIs found = %i',nROI))
    for idx = 1:nROI
        %seperate 3D nii files
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
        
        ROInii = make_nii(ROI,voxsz,vol_origin);
        %get the number of the encoding ROI
        encID = strrep(ROIdirs{enc_idx},'results','');
        encID = strrep(encID,'_','');
        %format is: job name, encoding ROI #, result ROI #
        outFN = sprintf('%s%s_%i.nii',job_name,encID,idx);
        fprintf('----saving file: %s\n',outFN)
        save_nii(ROInii,fullfile(maskdir,outFN))
        
    end
    
end
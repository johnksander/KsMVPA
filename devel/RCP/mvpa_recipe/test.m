clear
clc
format compact

resname = 'MVPA_ROI2searchlight_2p5_ASGM_enc2ret';
enc_job = 'RSA_SL_2p5_ASGM_encodingValence'; %encoding results to pull
permname = [resname '_stats'];


%----name---------------------------------------------------
config_options.name = permname;
config_options.result_dir = permname;
%----experiment---------------------------------------------
config_options.dataset = 'RCP';
%----analysis-----------------------------------------------
config_options.analysis = 'searchlight';
config_options.CVscheme = 'none';
config_options.normalization = 'runwise';
config_options.trial_temporal_compression = 'off'; 
config_options.feature_selection = 'off';
%----evaluation---------------------------------------------
config_options.cluster_conn = 26;
config_options.cluster_effect_stat = 'extent';
%----fMRI-data-specification--------------------------------
config_options.rawdata_type = 'LSS_eHDR'; % 'unsmoothed_raw' | dartel_raw | 'LSS_eHDR' | SPMbm | 'anatom' 
config_options.LSSid = 'ASGM'; %LSS model ID (or SPMbm ID)
config_options.searchlight_radius = 2.5;
config_options.roi_list = {'gray_matter.nii'};   
config_options.rois4fig = {'gray_matter'};  
%-----behavioral-data-settings------------------------------
config_options.behavioral_transformation = 'enc2ret_valence';
config_options.behavioral_measure = 'allstim';
%----classifier---------------------------------------------
config_options.classifier = 'linear'; 
config_options.performance_stat = 'accuracy'; 
%----------------------------------------------------------- 
options = set_options(config_options);
options.parforlog = 'off';
options.PCAcomponents2keep = 60;
options.num_perms = 100;
options.enc_job = enc_job; %put the enc job in options 
%main_save_dir = options.save_dir; %we're going to save results in subdirs 


%load searchlight results for all ROIs 
output_log = fullfile(options.save_dir,'stats_output_log.txt');
%update_logfile('loading searchlight results',output_log)
searchlight_results = load(fullfile(options.home_dir,'Results',resname,[resname '_braincells.mat']));
searchlight_results = searchlight_results.searchlight_cells;
num_encROIs = find(~ismember(options.subjects,options.exclusions),1,'first'); %grab a valid subject index
num_encROIs = size(searchlight_results{num_encROIs},2) - 1;
%update_logfile(sprintf('----Encoding ROIs found: %i',num_encROIs),output_log)

seed_inds = find(~ismember(options.subjects,options.exclusions),1,'first'); %grab a valid subject index
seed_inds = searchlight_results{seed_inds};
seed_inds = seed_inds(:,1); %get seed inds 
searchlight_results = cellfun(@(x) x(:,2:end),searchlight_results,'Uniformoutput',false);
searchlight_results = searchlight_results(~cellfun(@isempty,searchlight_results));

%find my significant voxels 
main_save_dir = fullfile(options.save_dir,'conn26_alpha001','ROI_2_results');
results_nii = fullfile(main_save_dir,'significant_cluster_seeds.nii');
results_nii = load_nii(results_nii);
results_map = results_nii.img;

roi_idx = 2;

%MNI coordinates for double-check
origin = results_nii.hdr.hist.originator(1:3);
sig_vox = find(results_map);
vs = size(results_map);
[x,y,z] = ind2sub(size(results_map),sig_vox); %show me x,y,z coords
voxel_coords = [x y z];
voxel_coords = bsxfun(@minus,voxel_coords,origin); %reset voxel inds to origin 
mni_coords = voxel_coords * 2; %MNI coords for searchlight  centers 
%these check out on the mask you made.. 
vox_results = cellfun(@(x) x(ismember(seed_inds,sig_vox),roi_idx)',searchlight_results,'Uniformoutput',false);
vox_results = cell2mat(vox_results);
for idx = 1:3
   figure(idx)
   histogram(vox_results(:,idx),numel(vox_results(:,idx)))
   title(num2str(idx))
end

mean(vox_results)

save('reference','vox_results','sig_vox','mni_coords')

for idx = 1:3
    %make some new mask files with individual searchlights
    dummy_nii = load_nii(fullfile(main_save_dir,'significant_cluster_seeds.nii'));
    %dummy_nii.img = zeros(size(dummy_nii.img));
    
    [emptyx, emptyy, emptyz] = meshgrid(1:vs(2),1:vs(1),1:vs(3));
    sphere_voxels = logical((emptyx - y(idx)).^2 + ...
        (emptyy - x(idx)).^2 + (emptyz - z(idx)).^2 ...
        <= options.searchlight_radius .^2);
    
    dummy_nii.img  = sphere_voxels;
    save_nii(dummy_nii, sprintf('retreival_SL%i.nii',idx))
end


    
%update_logfile(sprintf('Loading data for encoding ROI #%i',idx),output_log)
%ROI_results = cellfun(@(x) [x(:,1),x(:,idx+1)],searchlight_results,'Uniformoutput',false);
%blah... this doesn't work b/c of empty cells & not sure if it'll take an if statement or something...
voxel_null = cell(size(options.subjects))';
for subject_idx = 1:numel(options.subjects)
    if ~ismember(options.subjects(subject_idx),options.exclusions)
        %load the null distribution for this subject & ROI
        subject_null = sprintf('subject_%i_encROI%i.mat',options.subjects(subject_idx),idx);
        subject_null = load(fullfile(options.save_dir,'files',subject_null));
        subject_null = subject_null.voxel_null;
        subject_null = subject_null(ismember(seed_inds,sig_vox),:)';
        voxel_null{subject_idx} = subject_null;
    end
end

voxel_null = cat(1,voxel_null{:});

for idx = 1:3
   figure(idx)
   histogram(voxel_null(:,idx))
   title(num2str(idx))
end


mean(voxel_null)


% 
%             %begin test code--- checking normalized data
%             sig_vox = load('view_niis/reference.mat');
%             vox_resuls = sig_vox.vox_results;
%             sig_vox = sig_vox.sig_vox(1);
%             f = load('view_niis/subject406_SL1_normalized.mat')
%             fX = f.encROI_data;
%             fY = f.retROI_data;
%             
%             
%             X = encROIs{2};
%             Y = searchlight_brain_data(:,:,seed_inds == sig_vox);
%             sum(X(:) ~= fX(:)) %perfect
%             sum(Y(:) ~= fY(:))
%   
%             %end test code--- everything past here is original



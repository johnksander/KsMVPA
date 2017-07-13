% 2nd level permutation test -- max is 12 subjects (for exact perm test)
clear
close all
clc

%--- options
analysis_target = 'f'; %rS or beta
save_output = 'on';
subjects = [5,6,7,8,9,10,11,12,14,15,16,17];
%--- voxel-level
voxel_alpha_level = 0.001;
num_tails = 1;
tail_direction = 'right';
stat_type = 'ttest';
variance_smooth_kernel = 7;
%--- cluster-level
cluster_alpha_level = 0.05;
cluster_stats = 'on';
conn_comp_size = 6; %filter for maximal statistic cluster size

this_os = computer;
            main_dir = '/Users/drewlinsley/Documents/MATLAB/scene_modeler_scripts/';
            data_dir = fullfile(main_dir,'searchlight_output');
            fullbrain_stem = fullfile(main_dir,'searchlight_fb_mask');
            function_dir = fullfile(main_dir,'searchlight_functions');
            addpath(function_dir);
out_dir = fullfile(main_dir,sprintf('%s_drew_permuted',analysis_target));
if ~exist(out_dir,'dir'),
    mkdir(out_dir)
end

%create permutation index
perm_idx = arrayfun(@str2double,dec2bin(1:(2^numel(subjects))-1)); %we can do half the perms since contrasts will mirror
perm_idx(numel(perm_idx(:,1)),:) = 0;
%perm_idx(numel(perm_idx(:,1))-1,:) = perm_idx(numel(perm_idx(:,1)),:);
%perm_idx(numel(perm_idx(:,1)),:) = [];
%perm_idx = perm_idx(:,2:numel(perm_idx(1,:)));
perm_idx(perm_idx==0)=-1; %set contrasts up; True T is number of perms - 1
%start preparing scans

%--- load first fullbrain mask
load(fullfile(fullbrain_stem,sprintf('subject_%i',subjects(1))));
%--- trim eyeballs
blobs = bwconncomp(mask_brain,conn_comp_size);
vol_size = size(mask_brain);
[num, fb] = max(cellfun(@numel,blobs.PixelIdxList));
fb_mask = zeros(vol_size);
fb_mask(blobs.PixelIdxList{fb}) = 1;
fb_mask = logical(fb_mask);
%--- preallocate data_mat
data_mat = nan(numel(fb_mask),numel(subjects)); %remove nans
for idx = 1:numel(subjects),
    load(fullfile(fullbrain_stem,sprintf('subject_%i',subjects(idx))));
    %--- trim eyeballs
    blobs = bwconncomp(mask_brain,conn_comp_size);
    [num, fb] = max(cellfun(@numel,blobs.PixelIdxList));
    fb_mask = zeros(vol_size);
    fb_mask(blobs.PixelIdxList{fb}) = 1;
    fb_mask = logical(fb_mask);
    load(fullfile(data_dir,sprintf('subject_%i.mat',subjects(idx)))); %load a single volume for setting shit up
    global_brain(fb_mask==0)=NaN; %HERE
    data_mat(:,idx) = reshape(global_brain,numel(fb_mask),1);
end

switch analysis_target
    case 't'
        data_mat = data_mat./100;
end
%--- A little clean up
clearvars global_brain
%--- Starting perms
%stuff
fprintf('\r\rBeginning Permutations\r\r')
%preallocate status array
status_backspace = arrayfun(@(x) numel(num2str(x)),1:numel(perm_idx(:,1)));
status_backspace = [0 diff(status_backspace)*-1] + status_backspace;
status_backspace = arrayfun(@(x) repmat('\b',1,x),status_backspace,'UniformOutput', false);
p_thresh = round((voxel_alpha_level * 2^numel(subjects)));

%--- remove rows containing nans
%data_mat(isnan(sum(data_mat,2)),:)=NaN;
%data_mat(isnan(data_mat))=0;
%data_mat = 2.*bsxfun(@rdivide,bsxfun(@minus,data_mat,nanmin(data_mat)),bsxfun(@minus,nanmax(data_mat),nanmin(data_mat)))-1; %normalize to [-1 1]
%data_mat = bsxfun(@minus,data_mat,nanmean(data_mat));%zscores
%data_mat = bsxfun(@rdivide,bsxfun(@minus,data_mat,nanmean(data_mat)),nanstd(data_mat));%zscores

%--- correct pval foor 1 vs 2-tailed comps
switch tail_direction
    case 'both'
        p_thresh = round(p_thresh/2);
    otherwise
end
%preallocate results arrays
switch stat_type,
    case 'mean'
        t_vol = nanmean(bsxfun(@times,data_mat,perm_idx(1,:)),2);
        win_array_right = repmat(t_vol,1,p_thresh);
        win_array_left = repmat(t_vol,1,p_thresh);
        a_vox = nan(numel(perm_idx(:,1)),1);
        a_vox(1) = t_vol(138238);
        for idx = 2:numel(perm_idx(:,1)),
            permed_vol = nanmean(bsxfun(@times,data_mat,perm_idx(idx,:)),2); %squaring this to convert t-values to f-values
            [win_array_left, win_array_right] = update_win_array(permed_vol,win_array_right,win_array_left,p_thresh);
            fprintf(sprintf('%s%i',status_backspace{idx},idx))
            a_vox(idx) = permed_vol(138238);
        end
        T_vol = nanmean(data_mat,2);
    case 'ttest'
        if variance_smooth_kernel > 0,
            fprintf('\r\rUsing Ttests with %imm variance smoothing\r\r',variance_smooth_kernel)
            t_vol = bsxfun(@times,data_mat,perm_idx(1,:));
            var_vol = reshape(nanvar(t_vol,0,2),vol_size);
            spm_smooth(var_vol,var_vol,variance_smooth_kernel);
            t_vol = nanmean(t_vol,2)./sqrt(reshape(var_vol,numel(var_vol),1));
            win_array_right = repmat(t_vol,1,p_thresh);
            win_array_left = repmat(t_vol,1,p_thresh);
            for idx = 2:numel(perm_idx(:,1)),
                permed_vol = bsxfun(@times,data_mat,perm_idx(idx,:));
                var_vol = reshape(nanvar(permed_vol,0,2),vol_size);
                spm_smooth(var_vol,var_vol,variance_smooth_kernel);
                permed_vol = nanmean(permed_vol,2)./sqrt(reshape(var_vol,numel(var_vol),1));
                [win_array_left, win_array_right] = update_win_array(permed_vol,win_array_right,win_array_left,p_thresh);
                fprintf(sprintf('%s%i',status_backspace{idx},idx))
            end
            var_vol = reshape(nanvar(data_mat,0,2),vol_size);
            spm_smooth(var_vol,var_vol,variance_smooth_kernel);
            T_vol = nanmean(data_mat,2)./sqrt(reshape(var_vol,numel(var_vol),1));
        else
            fprintf('\r\rUsing Ttests without variance smoothing\r\r')
            t_vol = bsxfun(@times,data_mat,perm_idx(1,:));
            t_vol = nanmean(t_vol,2)./nanstd(t_vol,0,2);
            win_array_right = repmat(t_vol,1,p_thresh);
            win_array_left = repmat(t_vol,1,p_thresh);
            for idx = 2:numel(perm_idx(:,1)),
                permed_vol = bsxfun(@times,data_mat,perm_idx(idx,:));
                permed_vol = nanmean(permed_vol,2)./std(permed_vol,0,2);
                [win_array_left, win_array_right] = update_win_array(permed_vol,win_array_right,win_array_left,p_thresh);
                fprintf(sprintf('%s%i',status_backspace{idx},idx))
            end
            T_vol = nanmean(data_mat,2)./nanstd(data_mat,0,2);
        end
    case 'ftest'
        if variance_smooth_kernel > 0,
            fprintf('\r\rUsing Ftests with %imm variance smoothing\r\r',variance_smooth_kernel)
            t_vol = bsxfun(@times,data_mat,perm_idx(1,:));
            var_vol = reshape(nanvar(t_vol,0,2),vol_size);
            spm_smooth(var_vol,var_vol,variance_smooth_kernel);
            t_vol = (nanmean(t_vol,2)./sqrt(reshape(var_vol,numel(var_vol),1))).^2;
            win_array_right = repmat(t_vol,1,p_thresh);
            win_array_left = repmat(t_vol,1,p_thresh);
            for idx = 2:numel(perm_idx(:,1)),
                permed_vol = bsxfun(@times,data_mat,perm_idx(idx,:));
                var_vol = reshape(nanvar(permed_vol,0,2),vol_size);
                spm_smooth(var_vol,var_vol,variance_smooth_kernel);
                permed_vol = (nanmean(permed_vol,2)./sqrt(reshape(var_vol,numel(var_vol),1))).^2;
                [win_array_left, win_array_right] = update_win_array(permed_vol,win_array_right,win_array_left,p_thresh);
                fprintf(sprintf('%s%i',status_backspace{idx},idx))
            end
            var_vol = reshape(nanvar(data_mat,0,2),vol_size);
            spm_smooth(var_vol,var_vol,variance_smooth_kernel);
            T_vol = (nanmean(data_mat,2)./sqrt(reshape(var_vol,numel(var_vol),1))).^2;
        else
            fprintf('\r\rUsing Ftests without variance smoothing\r\r')
            t_vol = bsxfun(@times,data_mat,perm_idx(1,:));
            t_vol = (nanmean(t_vol,2)./nanstd(t_vol,0,2)).^2;
            win_array_right = repmat(t_vol,1,p_thresh);
            win_array_left = repmat(t_vol,1,p_thresh);
            for idx = 2:numel(perm_idx(:,1)),
                permed_vol = bsxfun(@times,data_mat,perm_idx(idx,:));
                permed_vol = (nanmean(permed_vol,2)./std(permed_vol,0,2)).^2;
                [win_array_left, win_array_right] = update_win_array(permed_vol,win_array_right,win_array_left,p_thresh);
                fprintf(sprintf('%s%i',status_backspace{idx},idx))
            end
            T_vol = (nanmean(data_mat,2)./nanstd(data_mat,0,2)).^2;
        end
    otherwise
        error('pick a better stat_type')
end
%--- save corrected volume
if num_tails == 1,
    switch tail_direction
        case 'right'
            T_vol(T_vol<win_array_right(:,p_thresh))=NaN; %nan out subthreshold voxels
        case 'left'
            T_vol(T_vol>win_array_left(:,p_thresh))=NaN; %nan out subthreshold voxels
        case 'both'
            fprintf('\rTesting 2-tailed hypothesis\r')
            T_vol(T_vol>win_array_left(:,p_thresh) & T_vol<win_array_right(:,p_thresh))=NaN; %nan out subthreshold voxels
        otherwise
            error('fix variable tail_direction; should be either ''right'' or ''left''')
    end
else
    T_vol(T_vol>win_array_left(:,p_thresh) & T_vol<win_array_right(:,p_thresh))=NaN; %nan out subthreshold voxels
end
T_vol = reshape(T_vol,vol_size);
vol3d('cdata',T_vol);
switch cluster_stats
    case 'on'
        fprintf('\r\rComputing cluster statistics\r\r')
        switch stat_type,
            case 'mean'
                max_cluster_vec = nan(numel(perm_idx(:,1)),1);
                for idx = 1:numel(perm_idx(:,1)),
                    permed_vol = nanmean(bsxfun(@times,data_mat,perm_idx(idx,:)),2);
                    permed_vol(permed_vol>win_array_left(:,p_thresh) & permed_vol<win_array_right(:,p_thresh)) = NaN;
                    clusters = bwconncomp(reshape(~isnan(permed_vol),vol_size),conn_comp_size);
                                if isempty(clusters.PixelIdxList),
                                    max_cluster_vec(idx) = 0;
                                else
                                max_cluster_vec(idx) = max(cellfun(@numel,clusters.PixelIdxList));
                                end
                                fprintf(sprintf('%s%i',status_backspace{idx},idx))
                end
            case 'ttest'
                if variance_smooth_kernel > 0,
                    fprintf('\r\rUsing Ttests with %imm variance smoothing\r\r',variance_smooth_kernel)
                    max_cluster_vec = nan(numel(perm_idx(:,1)),1);
                    switch tail_direction
                        case 'right'
                            for idx = 1:numel(perm_idx(:,1)),
                                permed_vol = bsxfun(@times,data_mat,perm_idx(idx,:));
                                var_vol = reshape(nanvar(permed_vol,0,2),vol_size);
                                spm_smooth(var_vol,var_vol,variance_smooth_kernel);
                                permed_vol = nanmean(permed_vol,2)./sqrt(reshape(var_vol,numel(var_vol),1));
                                permed_vol(permed_vol<win_array_right(:,p_thresh)) = NaN;
                                clusters = bwconncomp(reshape(~isnan(permed_vol),vol_size),conn_comp_size);
                                if isempty(clusters.PixelIdxList),
                                    max_cluster_vec(idx) = 0;
                                else
                                max_cluster_vec(idx) = max(cellfun(@numel,clusters.PixelIdxList));
                                end
                                fprintf(sprintf('%s%i',status_backspace{idx},idx))
                            end
                        case 'left'
                            for idx = 1:numel(perm_idx(:,1)),
                                permed_vol = bsxfun(@times,data_mat,perm_idx(idx,:));
                                var_vol = reshape(nanvar(permed_vol,0,2),vol_size);
                                spm_smooth(var_vol,var_vol,variance_smooth_kernel);
                                permed_vol = nanmean(permed_vol,2)./sqrt(reshape(var_vol,numel(var_vol),1));
                                permed_vol(permed_vol > win_array_left(:,p_thresh)) = NaN;
                                clusters = bwconncomp(reshape(~isnan(permed_vol),vol_size),conn_comp_size);
                                if isempty(clusters.PixelIdxList),
                                    max_cluster_vec(idx) = 0;
                                else
                                max_cluster_vec(idx) = max(cellfun(@numel,clusters.PixelIdxList));
                                end
                                fprintf(sprintf('%s%i',status_backspace{idx},idx))
                            end
                        case 'both'
                            for idx = 1:numel(perm_idx(:,1)),
                                permed_vol = bsxfun(@times,data_mat,perm_idx(idx,:));
                                var_vol = reshape(nanvar(permed_vol,0,2),vol_size);
                                spm_smooth(var_vol,var_vol,variance_smooth_kernel);
                                permed_vol = nanmean(permed_vol,2)./sqrt(reshape(var_vol,numel(var_vol),1));
                                permed_vol(permed_vol > win_array_left(:,p_thresh) & permed_vol<win_array_right(:,p_thresh)) = NaN;
                                clusters = bwconncomp(reshape(~isnan(permed_vol),vol_size),conn_comp_size);
                                if isempty(clusters.PixelIdxList),
                                    max_cluster_vec(idx) = 0;
                                else
                                max_cluster_vec(idx) = max(cellfun(@numel,clusters.PixelIdxList));
                                end
                                fprintf(sprintf('%s%i',status_backspace{idx},idx))
                            end
                        otherwise
                            error('fix variable tail_direction; should be either ''right'' or ''left''')
                    end
                else
                    fprintf('\r\rUsing Ttests without variance smoothing\r\r')
                    max_cluster_vec = nan(numel(perm_idx(:,1)),1);
                    for idx = 1:numel(perm_idx(:,1)),
                        permed_vol = bsxfun(@times,data_mat,perm_idx(idx,:));
                        permed_vol = nanmean(permed_vol,2)./std(permed_vol,0,2);
                        permed_vol(permed_vol > win_array_left(:,p_thresh) & permed_vol<win_array_right(:,p_thresh)) = NaN;
                        clusters = bwconncomp(reshape(~isnan(permed_vol),vol_size),conn_comp_size);
                                if isempty(clusters.PixelIdxList),
                                    max_cluster_vec(idx) = 0;
                                else
                                max_cluster_vec(idx) = max(cellfun(@numel,clusters.PixelIdxList));
                                end
                        fprintf(sprintf('%s%i',status_backspace{idx},idx))
                    end
                end
            case 'ftest'
                if variance_smooth_kernel > 0,
                    fprintf('\r\rUsing Ftests with %imm variance smoothing\r\r',variance_smooth_kernel)
                    max_cluster_vec = nan(numel(perm_idx(:,1)),1);
                    switch tail_direction
                        case 'right'
                            for idx = 1:numel(perm_idx(:,1)),
                                permed_vol = bsxfun(@times,data_mat,perm_idx(idx,:));
                                var_vol = reshape(nanvar(permed_vol,0,2),vol_size);
                                spm_smooth(var_vol,var_vol,variance_smooth_kernel);
                                permed_vol = (nanmean(permed_vol,2)./sqrt(reshape(var_vol,numel(var_vol),1))).^2;
                                permed_vol(permed_vol<win_array_right(:,p_thresh)) = NaN;
                                permed_vol(~fb_mask) = NaN;
                                clusters = bwconncomp(reshape(~isnan(permed_vol),vol_size),conn_comp_size);
                                if isempty(clusters.PixelIdxList),
                                    max_cluster_vec(idx) = 0;
                                else
                                max_cluster_vec(idx) = max(cellfun(@numel,clusters.PixelIdxList));
                                end
                                if max(cellfun(@numel,clusters.PixelIdxList)) > 1000,
                                    beep
                                end
                                
                                fprintf(sprintf('%s%i',status_backspace{idx},idx))
                            end
                        case 'left'
                            for idx = 1:numel(perm_idx(:,1)),
                                permed_vol = bsxfun(@times,data_mat,perm_idx(idx,:));
                                var_vol = reshape(nanvar(permed_vol,0,2),vol_size);
                                spm_smooth(var_vol,var_vol,variance_smooth_kernel);
                                permed_vol = (nanmean(permed_vol,2)./sqrt(reshape(var_vol,numel(var_vol),1))).^2;
                                permed_vol(permed_vol > win_array_left(:,p_thresh)) = NaN;
                                clusters = bwconncomp(reshape(~isnan(permed_vol),vol_size),conn_comp_size);
                                max_cluster_vec(idx) = max(cellfun(@numel,clusters.PixelIdxList));
                                fprintf(sprintf('%s%i',status_backspace{idx},idx))
                            end
                        case 'both'
                            for idx = 1:numel(perm_idx(:,1)),
                                permed_vol = bsxfun(@times,data_mat,perm_idx(idx,:));
                                var_vol = reshape(nanvar(permed_vol,0,2),vol_size);
                                spm_smooth(var_vol,var_vol,variance_smooth_kernel);
                                permed_vol = (nanmean(permed_vol,2)./sqrt(reshape(var_vol,numel(var_vol),1))).^2;
                                permed_vol(permed_vol > win_array_left(:,p_thresh) & permed_vol<win_array_right(:,p_thresh)) = NaN;
                                clusters = bwconncomp(reshape(~isnan(permed_vol),vol_size),conn_comp_size);
                                max_cluster_vec(idx) = max(cellfun(@numel,clusters.PixelIdxList));
                                fprintf(sprintf('%s%i',status_backspace{idx},idx))
                            end
                        otherwise
                            error('fix variable tail_direction; should be either ''right'' or ''left''')
                    end
                else
                    fprintf('\r\rUsing Ftests without variance smoothing\r\r')
                    max_cluster_vec = nan(numel(perm_idx(:,1)),1);
                    for idx = 1:numel(perm_idx(:,1)),
                        permed_vol = bsxfun(@times,data_mat,perm_idx(idx,:));
                        permed_vol = (nanmean(permed_vol,2)./std(permed_vol,0,2)).^2;
                        permed_vol(permed_vol > win_array_left(:,p_thresh) & permed_vol<win_array_right(:,p_thresh)) = NaN;
                        clusters = bwconncomp(reshape(~isnan(permed_vol),vol_size),conn_comp_size);
                        max_cluster_vec(idx) = max(cellfun(@numel,clusters.PixelIdxList));
                        fprintf(sprintf('%s%i',status_backspace{idx},idx))
                    end
                end
            otherwise
                error('pick a better stat_type')
        end
end
cluster_vol = T_vol;
cluster_vol(~isnan(cluster_vol))=1;
cluster_vol(isnan(cluster_vol))=0;
cluster_vol = logical(cluster_vol);
T_clusters = bwconncomp(cluster_vol,conn_comp_size);
T_cluster_idx = cellfun(@numel,T_clusters.PixelIdxList);
T_cluster_idx(T_cluster_idx<=prctile(max_cluster_vec,(1-cluster_alpha_level)*100))=0;%make this either < (p = 0.05) or <= (p< 0.05)
T_cluster_idx(T_cluster_idx>0)=1;
supra_threshold_clusters = T_clusters.PixelIdxList(logical(T_cluster_idx));
fprintf('\rCluster Threshold = %2.f',prctile(max_cluster_vec,(1-cluster_alpha_level)*100))
fprintf('\rMax size in T_vol = %i',max(cellfun(@numel,T_clusters.PixelIdxList)))
if isempty(supra_threshold_clusters),
    fprintf('\r\rNo clusters passed threshold\r\r')
else
    corrected_vol = zeros(vol_size);
    clust_idx = cat(1,supra_threshold_clusters{:});
    corrected_vol(clust_idx)=T_vol(clust_idx);
    corrected_vol(corrected_vol>0) = 1000; %dumb fix so that spm keeps all activations
    vol3d('cdata',corrected_vol);
    switch save_output
        case 'on'
            fprintf('\r\rOutput saved to %s\r\r',out_dir)
            head = spm_vol(fullfile(fullbrain_stem,sprintf('S%i',subjects(1)),...
                    'NullCarryOver','mask.hdr'));
            head.fname = fullfile(out_dir,sprintf('%s_alpha_%i_maximal_stat_vol_and_stats.nii',analysis_target,voxel_alpha_level));    
                S = struct('fname',head.fname,'dim',head.dim,'mat',head.mat,'dt',head.dt,...
    'n',head.n,'descrip',head.descrip);
            spm_write_vol(head,corrected_vol);
            save(fullfile(out_dir,sprintf('%s_alpha_%i_maximal_stat_vol_and_stats.mat',analysis_target,voxel_alpha_level)),'corrected_vol'); %save output stats
        otherwise
            fprintf('\rOutput not saved')
    end
end
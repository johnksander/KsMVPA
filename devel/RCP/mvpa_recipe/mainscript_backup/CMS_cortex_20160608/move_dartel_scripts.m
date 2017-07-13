clear
clc
format compact

basedir = '/home/acclab/Desktop/ksander/ESWS_MVPA';
cd(basedir)

%data_dir = fullfile('SPM_datasets','CMS_2015'); %when I had a duplicate copy 
data_dir = '/home/acclab/Desktop/ksander/DARTEL_CMS_MVPA';
output_dir = fullfile('SPM_datasets','ESWS_SPMdata','raw_scans');

EAsubs = [101:120]';
USsubs = [201:220]';
total_subjects = [EAsubs;USsubs];

for idx = 1:numel(total_subjects)
    curr_sub = total_subjects(idx);
    subj_dir = fullfile(data_dir,['DARTEL_MVPA' num2str(curr_sub)]);
    
    run1 = fullfile(subj_dir,'enc1','wraf-ep2d-01.nii');
    run2 = fullfile(subj_dir,'enc2','wraf-ep2d-02.nii');
    if ~exist(run1) | ~exist(run2)
        disp(sprintf('WARNING: run file not found for subject %i',curr_sub))
    end
    
    disp(sprintf('Copying scans: subject %i',curr_sub))
    newsub_dir = fullfile(output_dir,num2str(curr_sub));
    %mkdir(newsub_dir)
    run1dir = fullfile(newsub_dir,'001');
    %mkdir(run1dir)
    run2dir = fullfile(newsub_dir,'002');
    %mkdir(run2dir)
    
    copyfile(run1,run1dir)
    copyfile(run2,run2dir)
end

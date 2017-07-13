clear 
clc 
format compact

result_dir = '/home/acclab/Desktop/ksander/KsMVPA/Results/LOSO_SL_ASGM_comp_bigmem_r1p5';
results = dir(fullfile(result_dir,'*braincells.mat'));
results = load(fullfile(result_dir,results.name));
result_vals = results.searchlight_results(:,2);

ind_of_interest = find(result_vals == max(result_vals));
%searchlight_radius... searchlight size
vs = results.options.scan_vol_size;
id = results.searchlight_results(:,1);
searchlight_radius = results.options.searchlight_radius;
[x,y,z] = ind2sub(vs,id);
xnum = numel(x);
mc = round(xnum/2);
dummy_searchlight = find_SL_data4linus_helperfunc(vs,x(mc),y(mc),z(mc),searchlight_radius);
%get it
sphere_voxels = find_SL_data4linus_helperfunc(vs,x(ind_of_interest),y(ind_of_interest),z(ind_of_interest),searchlight_radius);
searchlight_inds = find(sphere_voxels);
[x,y,z] = ind2sub(vs,searchlight_inds); %real x,y,z
current_searchlight = cell(numel(results.options.subjects),1);

%get linus filepaths 
options = load('linus_options');
options = options.options;
addpath(options.script_function_dir);
addpath(options.helper_function_dir);
addpath(options.classifier_function_dir);
addpath(options.searchlight_function_dir);
addpath(options.stat_function_dir);
%addpath('/data/netapp/jksander/spm12');
select_linus_spm('spm12');

for idx = 1:numel(options.subjects),
    if ismember(options.subjects(idx),options.exclusions) == 0
        disp(sprintf('\nLoading subject %g fMRI data',options.subjects(idx)))
        %get data directory and preallocate file data array
        subj_dir = fullfile(options.SPMdata_dir,[options.SPMsubj_dir num2str(options.subjects(idx))]);
        file_data = cell(numel(options.runfolders),1); %preall cell array for load_fmridata
        %Load in scans
        for runidx = 1:numel(options.runfolders)
            my_files = prepare_fp(options,subj_dir,options.runfolders{runidx},options.scan_ft); %get filenames
            file_data{runidx} = load_fmridata(my_files,options); %load data
        end
        file_data = cat(4,file_data{:}); % cat data into matrix
        %I have the data
        searchlight = nan(numel(file_data(1,1,1,:)),numel(searchlight_inds));
        for voxidx = 1:numel(searchlight_inds)
            searchlight(:,voxidx,:) = file_data(x(voxidx),y(voxidx),z(voxidx),:);
        end
        current_searchlight{idx} = searchlight;        
    end
end

save('current_searchlight','current_searchlight')



clear
clc
format compact

aname = 'ESWS_LOSO_SL_RelVec_r1p5';
preallocate_SLrois = 'load'; % 'run' | 'load'
num_workers = 12; %parpool workers

config_options.name = aname;
config_options.dataset = 'ESWS';%Del_MCQ/Aro_MCQ
config_options.rawdata_type = 'unsmoothed_raw'; % 'estimatedHDR_spm' | 'unsmoothed_raw' |'LSS_eHDR'
config_options.analysis = 'LOSO_SL';
config_options.analysis_method = 'classification';
config_options.behavioral_measure = 'allstim';
config_options.behavioral_transformation = 'origin_split';
config_options.TRlag = 2;%TR lag
config_options.TR_avg_window = 2;%TR window to average over
config_options.searchlight_radius = 1.5;
config_options.classifier = @RelVec;
config_options.result_dir = aname;


options = set_options(config_options);

preproc_data_file_pointers = load(fullfile(options.preproc_data_dir,'preproc_data_file_pointers'));
preproc_data_file_pointers = preproc_data_file_pointers.preproc_data_file_pointers;

switch preallocate_SLrois
    case 'run'
        options.SL_per_file = 1000;
        parpool(num_workers)
        preprocessed_SLroi_files = preprocess_searchlight_rois(preproc_data_file_pointers,options);
        delete(gcp('nocreate'))
    case 'load'
        preprocessed_SLroi_files = SLroi_filelocs(options);
end


classifer_file = fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m']);
parpool(num_workers,'AttachedFiles',{classifer_file})

brain_cells = LOSO_SL_parfor_mvpa(preprocessed_SLroi_files,preproc_data_file_pointers,options);
delete(gcp('nocreate'))


save(fullfile(options.save_dir,[options.name '_braincells']),'brain_cells','options')



%which_behavior 1 = conf, 2 = vivid, 3 = feel, 4 = order, 5 = thoughts
%subj_filepointers = load_filepointers(options);

%primary_analysis_output = regression_model(subj_filepointers,options);


%
% %primary_analysis_output = mvpa(subj_filepointers,options);
% save(fullfile(options.save_dir,options.classification_fname),'primary_analysis_output','options')
%
% statistics_output = summarize_mvpa(primary_analysis_output,options);
% save(fullfile(options.save_dir,options.statistics_fname),'statistics_output','primary_analysis_output','options');
%
% jk_get_permstats(statistics_output,primary_analysis_output,options)
% jk_mkfig_from_perm(options)
% jk_mkfig_4MCC_from_perm(options)





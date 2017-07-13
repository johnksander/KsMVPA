function trialtype_matrix = LSS_load_trialtypes(options,subject_num)

numTT = numel(options.trialtypes);
trialtype_matrix = NaN(sum(options.scans_per_run),1);

for idx = 1:numTT %loop will not run if options.trialtypes is an empty cell 
    
    BehFname = [options.trialtypes{numTT} '_' num2str(subject_num) '.txt'];
    my_files = prepare_fp(options,options.TRfile_dir,BehFname);
    TOI_beh_matrix = load_behav_data(my_files,options);
    TOI_beh_matrix = TOI_beh_matrix(:,options.which_behavior); %select behavioral rating
    TOI_beh_matrix(~isnan(TOI_beh_matrix)) = idx;
    trialtype_matrix(~isnan(TOI_beh_matrix)) = TOI_beh_matrix(~isnan(TOI_beh_matrix));
end
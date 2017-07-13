clear
clc
format compact

%preprocess_HDR_LSS_updated

%preprocess_LOSO_SL_updated

%RSA_searchlight_updated

%--------------------------

searchlight_zeromean_ROI_followup
searchlight_zeromean_ROI_followup_perm
searchlight_zeromean_ROI_followup_stats



% warning('off', 'MATLAB:table:ModifiedVarnames')
% logfile = '/home/acclab/Desktop/ksander/KsMVPA/Results/LOSO_ROI_searchlight_followup_gnb_zeromean/stats_results.txt';
% val_log = '/home/acclab/Desktop/ksander/KsMVPA/Results/LOSO_ROI_searchlight_followup_gnb_zeromean/val_log.txt';
% 
% currval = 1;
% itr_num = 0;
% 
% while currval >= .049;
%     
%     searchlight_zeromean_ROI_followup_perm()
%     searchlight_zeromean_ROI_followup_stats()
%     
%     itr_num = itr_num + 1;
%     currval = readtable(logfile);
%     currval = currval.ROI_Significant_searchlights{5};
%     currval = strsplit(currval,' = ');
%     currval = str2num(currval{2});
%     fprintf('iteration #%i\n',itr_num)
%     fprintf('----currval = %.4f\n',currval)
%     txtappend(val_log,[num2str(currval) '\n'])
% end
clear
clc
format compact

%steps 0
%0a) run RSA searchlight on encoding data
%0b) make ROI masks for searchlight clusters with make_result_masks_enc2ret()
%0c) 


%1)
%preprocess_HDR_LSS
%2)
%preprocess_LOSO_SL
%3)
MVPA_ROI2searchlight_enc2ret_main
%4)
MVPA_ROI2searchlight_enc2ret_perm
%5)
MVPA_ROI2searchlight_enc2ret_stats

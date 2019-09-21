
clear
outputfile_name = 'minpool_roi_output';

fname = 'minpool_roi_permed_statistics.mat';
load(fname)

load([outputfile_name '.mat']);
clear minpool_roi_output

acc_ci = acc_ci(:,1:6,2:4);
acc_means = acc_means(2:4,1:6);
acc_p_values = acc_p_values(2:4,1:6);

save('fixed_mrp_statistics','acc_means','acc_p_values','acc_ci');
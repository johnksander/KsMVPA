function [local_dists,global_dists,converged_dists] = xxproduce_model_distances_drewfile(testing_local,testing_global,testing_converged)

label_idx = reshape(repmat(1:7,100,1),700,1);
%label_l_idx = reshape(repmat(1:7,100,1),2800,1);
label_l_idx = reshape(repmat(1:7,400,1),2800,1);


label_idx(label_idx==4)=3;
label_idx(label_idx==5)=3;
label_idx(label_idx==6)=4;
label_idx(label_idx==7)=5;

label_l_idx(label_l_idx==4)=3;
label_l_idx(label_l_idx==5)=3;
label_l_idx(label_l_idx==6)=4;
label_l_idx(label_l_idx==7)=5;


all_local = [mean(testing_local(label_l_idx==1,:));mean(testing_local(label_l_idx==2,:));...
    mean(testing_local(label_l_idx==3,:));mean(testing_local(label_l_idx==4,:));...
    mean(testing_local(label_l_idx==5,:))];
all_global = [mean(testing_global(label_idx==1,:));mean(testing_global(label_idx==2,:));...
    mean(testing_global(label_idx==3,:));mean(testing_global(label_idx==4,:));...
    mean(testing_global(label_idx==5,:))];
all_converged = [mean(testing_converged(label_idx==1,:));mean(testing_converged(label_idx==2,:));...
    mean(testing_converged(label_idx==3,:));mean(testing_converged(label_idx==4,:));...
    mean(testing_converged(label_idx==5,:))];

local_dists = pdist(all_local,'euclidean');
global_dists = pdist(all_global,'euclidean');
converged_dists = pdist(all_converged,'euclidean');

function [updated_array_left, updated_array_right] = xxupdate_win_array_drewfile(permed_vol,win_array_right,win_array_left,p_thresh)

%--- right tail
win_idx = permed_vol>win_array_right(:,1);
prior = win_array_right(:,1);
win_array_right(win_idx,1) = permed_vol(win_idx);
for col = 2:p_thresh,
    post = win_array_right(:,col);
    win_array_right(win_idx,col) = prior(win_idx);
    prior = post;
end
updated_array_right = win_array_right;
%--- left tail
win_idx = permed_vol<win_array_left(:,1);
prior = win_array_left(:,1);
win_array_left(win_idx,1) = permed_vol(win_idx);
for col = 2:p_thresh,
    post = win_array_left(:,col);
    win_array_left(win_idx,col) = prior(win_idx);
    prior = post;
end
updated_array_left = win_array_left;
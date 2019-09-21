function cv_guesses = cat_cv_inds(cv_guesses)

for idx = 1:numel(cv_guesses),
    cv_guesses{idx} = cat(2,cv_guesses{idx},zeros(numel(cv_guesses{idx}(:,1)),1) + idx);
end

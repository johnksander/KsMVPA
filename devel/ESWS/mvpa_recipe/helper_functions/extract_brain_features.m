function patches = extract_brain_features(X, nn, M, P)
% extract overlapping sub-patches into rows of 'patches'
if exist('M','var'),
    patches = bsxfun(@minus, X, M) * P;
end
% % compute 'triangle' activation function
% xx = sum(patches.^2, 2);
% cc = sum(nn.^2, 2)';
% xc = patches * nn';
% 
%z = sqrt(bsxfun(@plus, cc, bsxfun(@minus, xx, 2*xc))); % distances

z = pdist2(X,nn);

mu = mean(z, 2); % average distance to centroids for each patch
patches = max(bsxfun(@minus, mu, z), 0);

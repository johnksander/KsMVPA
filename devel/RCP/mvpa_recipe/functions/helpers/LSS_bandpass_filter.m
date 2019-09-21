function bandpass_filter = LSS_bandpass_filter(TR,sigma,scans_per_run)
%Make bandpass filter for LSS estimation. This emulates FSL's gaussian
%lowess filter. Output matrix to be multiplied by data and design matrix,
%detrends and de-noises data. 




% TR = 2;
% scans_per_run = 150;
% sigma = 32; %gives 128 hz for tr = 2

sigma=sigma/TR;
sigN2=(sigma/sqrt(2))^2;
K = toeplitz(1/sqrt(2*pi*sigN2)* exp(-[0:(scans_per_run - 1)].^2/(2*sigN2)));
K = spdiags(1./sum(K')',0,scans_per_run,scans_per_run)*K;
H = zeros(scans_per_run,scans_per_run); % Smoothing matrix, s.t. H*y is smooth line
X = [ones(scans_per_run,1) (1:scans_per_run)'];
for k = 1:scans_per_run
    W = diag(K(k,:));
    Hat = X*pinv(W*X)*W;
    H(k,:) = Hat(k,:);
end
%F is the filtering matrix that you premultiply the data and design by
bandpass_filter=eye(scans_per_run)-H;


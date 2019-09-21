function basis = RelVec_compute_basis(data_matrix,data_matrix2)
%code from SB1
basisWidth	= 0.5;
eta	= 1/basisWidth^2;

basis = exp(-eta*distSqrd(data_matrix,data_matrix2));

function D2 = distSqrd(X,Y)
nx	= size(X,1);
ny	= size(Y,1);
D2	= sum(X.^2,2)*ones(1,ny) + ones(nx,1)*sum(Y.^2,2)' - 2*(X*Y');



%code from SB2

% basisWidth	= 0.5;	
% % Heuristically adjust basis width to account for 
% % distance scaling with dimension.
% % 
% dimension = numel(size(data_matrix));
% basisWidth	= basisWidth^(1/dimension);
% %
% % Compute ("Gaussian") basis (design) matrix
% % 
% basis	= exp(-distSquared(data_matrix,data_matrix2)/(basisWidth^2));
% 
% function D2 = distSquared(X,Y)
% %
% nx	= size(X,1);
% ny	= size(Y,1);
% %
% D2 = (sum((X.^2), 2) * ones(1,ny)) + (ones(nx, 1) * sum((Y.^2),2)') - ...
%      2*X*Y';

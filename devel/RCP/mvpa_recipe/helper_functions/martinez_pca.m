function [outData, outParams] = martinez_pca(training_data,num_PCs)

%code from srinivasan 2016--- modified slightly for toolbox. All comments 
%below this line are from source.
%------------------------------------------------------------------------

% Input - trainData - Input Data Matrix
%       - opts - Structure of options - num_PCs is the number of PCs
%         required
% 
% output - outData - Data in PC space
%        - outParams - Structure of output parametes - includes eigen
%        values , eigen vectors and the variance percentage
% 


% %Find number of rows - Max number of PCs is (Nrows-1)
%size_total=size(training_data,1);

% Center Data at zero mean
data_zeroMean=bsxfun(@minus,training_data,mean(training_data));

% Calculate data*data' 
Covariance_Matrix=(data_zeroMean)*(data_zeroMean)';

% Eigen value decomposition 
[tmpVectors_1,diagonalMatrix]=eig(Covariance_Matrix);

% Find the vector of eigen values 
outParams.eigenVals=diag(diagonalMatrix);

% Calculate the eigen vectors of the actual covariance matrix -
% (data'*data) using SVD trick
% The number of Vectors is given by opts_numPcs

scale=outParams.eigenVals.^(.5);
tmpVectors_2=data_zeroMean'*tmpVectors_1;
outParams.eigenVectors=bsxfun(@rdivide,tmpVectors_2,scale');

% Project the data on to span of PCs
outData=data_zeroMean*outParams.eigenVectors(:,end-num_PCs+1:end);

% Calculate the total percentage of variance in the output data
outParams.variancePercent=(sum(outParams.eigenVals(end-num_PCs+1:end))*100)/sum(outParams.eigenVals(:));

end


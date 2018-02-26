function outputStruct = mainFunction(dataCell,labelCell,nSamplesPerBlock,crossvalFlag,nPcs)

% Input - dataCell - Input Data Cell Array. A (number of subject X 1) cell array. Each cell element should be a (number of acquisitions x number of voxels) data matrix 
%                    of one subject - They should be arranged in the order of acquisition. This is the final preprocessed data matrix on which PCA will be performed
% 
%       - labelCell - The binary (0 or 1) class label of each sample - A (number of subject X 1) cell array.
%      Each cell element should be a vector with the same number of rows as  dataCell. All acquisitions within a block should have
%       the same label.
%
%       - nSamplesPerBlock - The number of acquisitions per block. The
%       algorithm will average over all the samples in a block.
%                                                                  
%       - crossvalFlag - (0 or 1) flag 
%                           0 - The algorithm will not use crossvalidation to select the number of PCs. It will use the number specified in nPcs argument.
%                           1 - The algorithm will use crossvalidation to select the optimal number of PCs.
%                           
%       - nPcs - when crossvalFlag is 0 - user input number of PCs
%              - when crossvalFlag is 1 - The maximum number of PCs to consider
%
%
% output - outputStruct   - structure containing output 

addpath(genpath(pwd));
if crossvalFlag 
    [outputStruct, pcOpt] = CrossvalFunction(dataCell,labelCell,nSamplesPerBlock,nPcs);
    fprintf('Optimal number of Principal Components is %d',pcOpt);
else 
    outputStruct = noCrossvalFunction(dataCell,labelCell,nSamplesPerBlock,nPcs);
end

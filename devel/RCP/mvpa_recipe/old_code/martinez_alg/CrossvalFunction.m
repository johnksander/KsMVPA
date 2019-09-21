function [outputStruct, pcOpt] = CrossvalFunction(dataCell,labelCell,nSamplesPerBlock,nPcs)

pcCrossvalCell = cell(1,nPcs);
accuracyPcCrossval = zeros(1,nPcs);

for pcIter = 1:nPcs
    tpStruct = noCrossvalFunction(dataCell,labelCell,nSamplesPerBlock,pcIter);
    pcCrossvalCell{1,pcIter} = tpStruct;
    accuracyPcCrossval(1,pcIter) = tpStruct.accuracyMean;
end

[~, pcOpt] = max(accuracyPcCrossval);
outputStruct = pcCrossvalCell{1,pcOpt};


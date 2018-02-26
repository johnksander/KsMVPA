function outputStruct = noCrossvalFunction(dataCell,labelCell,nSamplesPerBlock,nPcs)

dataPcaCell = cell(size(dataCell,1),1);
labelAvgCell = cell(size(dataCell,1),1);
for m1 = 1 : size(dataCell , 1)  
    opts=struct('numPcs',nPcs);
    [dataPca, outParams] = pca(dataCell{m1,1}, opts);
    
    dataAvg = [];
    labelAvg = [];
    for m2 = 1 : nSamplesPerBlock : size(dataPca,1)
        dataAvg = vertcat(dataAvg, mean(dataPca(m2:m2 + nSamplesPerBlock - 1,:)));
        labelAvg = vertcat(labelAvg, labelCell{m1,1}(m2,1));
    end
    dataPcaCell{m1,1} = dataAvg;
    labelAvgCell{m1,1} = labelAvg;
end

accuracyCrossval = zeros(size(dataCell,1),1);
statsCrossval = cell(size(dataCell,1),1);


for m1=1:size(dataCell,1)

    test_element=m1;

    cellTrain = dataPcaCell;
    cellTrain{m1,1} = [];
    dataTrain = cell2mat(cellTrain);
    dataTest = dataPcaCell{m1,1};
    
    cellLabelTrain = labelAvgCell;
    cellLabelTrain{m1,1} = [];
    labelTrain = cell2mat(cellLabelTrain);
    labelTest = labelAvgCell{m1,1};
    
    model = fitcdiscr(dataTrain,labelTrain); 
    predictedLabel = predict(model,dataTest);  
    stats = confusionmatStats(labelTest,predictedLabel);
    accuracy = stats.accuracy(1);
    
    accuracyCrossval(m1,1) = accuracy;
    statsCrossval{m1,1} = stats;
    
end

accuracyMean = mean(accuracyCrossval);

outputStruct.accuracyMean = accuracyMean;
outputStruct.accuracyCrossval = accuracyCrossval;
outputStruct.stats = stats;



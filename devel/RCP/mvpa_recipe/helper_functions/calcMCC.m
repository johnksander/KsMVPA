function MCC = calcMCC(TP,FP,FN,TN)


MCC = ((TP * TN) - (FP * FN)) / (sqrt((TP + FP) * (TP + FN) * (TN + FP) * (TN + FN)));


end


function [vals, idx] = multiclass_sigmoid(X,theta)

[vals, idx] = max(sigmoid(X*theta’)’);
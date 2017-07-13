function data_matrix = minmax_normdata(data_matrix)

Xmins = min(data_matrix);
Xmaxs = max(data_matrix);
data_matrix = bsxfun(@rdivide,(bsxfun(@minus,data_matrix,Xmins)),(Xmaxs - Xmins));


end


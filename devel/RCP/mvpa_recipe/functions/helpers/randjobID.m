function ID = randjobID()
%make a random 6 letter ID sequence
rng('shuffle')
alph = num2str(97:122,'%s');
x = randi(26,6,1);
ID = alph(x);



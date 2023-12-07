%{
Simple method that compares two symbol arrays (Integers) 
and counts discongruencies.  Outputs a fraction.
%}
function [SER] = SymbolErrorRate(X, Y)
    SER = 0;
    for i = 1:size(X, 1)
        if X(i) ~= Y(i)
            SER = SER + 1;
        end
    end
    SER = SER/size(X, 1);
end
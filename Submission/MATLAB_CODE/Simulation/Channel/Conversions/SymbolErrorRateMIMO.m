%{
Simple method that compares two symbol arrays (Integers) 
and counts discongruencies.  Outputs a fraction.
%}
function [SER] = SymbolErrorRateMIMO(X, Y)
    SER = 0;
    for i = 1:size(X, 1)
        for j = 1:size(X, 2)
            if X(i, j) ~= Y(i, j)
                SER = SER + 1;
            end
        end
    end
    SER = SER/(size(X, 1)*size(X, 2));
end
%% Remove Pilots
function [data] = RemovePilots(prefix, CPLength, CPLocations)
    input = prefix;
    offset = 0;
    for i = CPLocations
        i = i - offset;
        lhs = input(1:i-1);
        rhs = input(i+CPLength:end);
        input = cat(2, lhs, rhs);
        offset = offset + 1;
    end
    data = input;
end

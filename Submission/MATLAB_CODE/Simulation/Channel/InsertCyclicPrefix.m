%% Insert CP
function [cp, cp_locations] = InsertCyclicPrefix( ...
    CPSpacing, ...
    CPLength, ...
    CPValue, ...
    data)
    data2D = [];
    CPArray = zeros(size(data));
    cp_locations = [];
    for i = 1:size(PilotArray, 2)
        if mod(i, PilotSpacing) == 0
            CPArray(i) = CPValue;
            cp_locations = cat(1, cp_locations, 1);
        else 
            CPArray(i) = "NAN";
        end
    end
    for i = 1:CPLength
        data2D = cat(1, data2D, CPArray);
    end
    data = cat(1, data, data2D);
    cp = reshape(data, 1, []);
    cp(isnan(cp)) = [];
end

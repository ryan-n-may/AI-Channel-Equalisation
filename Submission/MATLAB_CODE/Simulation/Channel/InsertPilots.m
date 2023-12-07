%% Insert Pilots
function [pilots, PilotLocations] = InsertPilots( ...
    PilotSpacing, ...
    PilotLength, ...
    PilotValue, ...
    data)
    data2D = [];
    PilotArray = zeros(size(data));
    PilotLocations = [];
    for i = 1:size(PilotArray, 2)
        if mod(i, PilotSpacing) == 0
            PilotArray(i) = PilotValue;
        else 
            PilotArray(i) = "NAN";
        end
    end
    for i = 1:PilotLength
        data2D = cat(1, data2D, PilotArray);
    end
    data = cat(1, data, data2D);
    pilots = reshape(data, 1, []);
    pilots(isnan(pilots)) = [];
    for i = 1:size(pilots, 2)
        if pilots(i) == PilotValue
            PilotLocations = [PilotLocations; i];
        end
    end
end
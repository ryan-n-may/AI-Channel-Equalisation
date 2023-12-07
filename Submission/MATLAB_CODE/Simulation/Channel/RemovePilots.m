%% Remove Pilots
function [data] = RemovePilots(Pilots, PilotLength, PilotLocations)
    input = Pilots;
    offset = 0;
    for i = PilotLocations
        i = i - offset;
        lhs = input(1:i-1);
        rhs = input(i:end);
        input = cat(2, lhs, rhs);
        offset = offset + 1;
    end
    data = input;
end
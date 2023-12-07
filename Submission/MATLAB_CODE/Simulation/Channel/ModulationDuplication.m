function [data] = ModulationDuplication(data, Duplications)
    data2D = [];
    for i = 1:Duplications
        data2D = cat(2, data2D, data);
    end
    data = reshape(data2D, 1, []);
end
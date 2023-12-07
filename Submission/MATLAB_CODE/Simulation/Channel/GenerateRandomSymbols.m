function [x] = GenerateRandomSymbols(Modulation, BitLength, Duplications)
    x = randi([0, Modulation-1], BitLength, 1).';
    x_repeating = [];
    for i = 1:Duplications
        x_repeating = cat(1, x_repeating, x);
    end
    x = reshape(x_repeating, 1, []);
end
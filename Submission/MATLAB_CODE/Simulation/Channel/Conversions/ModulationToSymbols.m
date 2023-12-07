%{
Simple method that converts modulations (constellation points) to symbols 
(integer representations).
%}
function [symbols] = ModulationToSymbols(modulation, Modulation)
    symbols = qamdemod(modulation, Modulation, "gray");
end
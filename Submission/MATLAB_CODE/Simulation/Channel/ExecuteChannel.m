function [rx_pilots, tx_pilots, pilot_locations, ... 
    pilot_modulated_x, y_modulated_pilot, x, y, ...
    IFFT_pilot_modulated_x, y_modulated_pilot_IFFT] ... 
        = ExecuteChannel(...
                Modulation, ...
                BitLength, ...
                PilotSpacing, ...
                PilotValue, ...
                SymbolDuplications, ...
                ModulationDuplications, ...
                PilotDuplications, ...
                RayleighChannel, ...
                AWGNChannel, ...
                includeAWGN, ...
                includeChannel, ...
                verbose)
    % INPUT
    %x                                               = randi([0, Modulation-1], BitLength, 1).';
    x                                               = GenerateRandomSymbols(Modulation, BitLength, SymbolDuplications);
    if verbose, disp("Size of x: " + size(x)), end
    % MODULATION
    modulated_x                                     = qammod(x, Modulation, 'UnitAveragePower', true);
    if verbose, disp("Size of modulated x: " + size(modulated_x)), end
    % STRETCH 
    stretch_modulated_x                             = ModulationDuplication(modulated_x, ModulationDuplications);
    % INSERT PILOTS
    [pilot_modulated_x, pilot_locations]            = InsertPilots(PilotSpacing, PilotDuplications, PilotValue, stretch_modulated_x);
    if verbose, disp("Size of pilot modulated x: " + size(pilot_modulated_x)), end
    % IFFT
    IFFT_pilot_modulated_x                          = ifft(pilot_modulated_x, 32);
    if verbose, disp("Size of IFFT_pilot_modulated_x: " + size(IFFT_pilot_modulated_x)), end
    % GET IFFT TX PILOTS
    tx_pilots                                       = IFFT_pilot_modulated_x;
    tx_pilots(:)                                    = 0;
    tx_pilots(pilot_locations)                      = IFFT_pilot_modulated_x(pilot_locations);   
    % CHANNEL
    try
        if(includeChannel == true)
            y_modulated_pilot_IFFT                  = RayleighChannel .* IFFT_pilot_modulated_x;  
        else
            y_modulated_pilot_IFFT                  = 1 .* IFFT_pilot_modulated_x;   
        end
    catch
        disp("Error: length of rayleigh channel incompatable with pilot and cp modulated symbols.")
        disp("Length of IFFT_pilot_modulated_x = " + length(IFFT_pilot_modulated_x));           
        disp("Length of rayleigh channel = " + length(RayleighChannel));
        error("Rayleigh channel incompatable size.")
    end
    if(includeAWGN == true)
        y_modulated_pilot_IFFT                  = AWGNChannel(y_modulated_pilot_IFFT);
    else
        y_modulated_pilot_IFFT                  = 1 .* (y_modulated_pilot_IFFT);
    end
    if verbose, disp("Size of y modulated pilot IFFT: " + size(y_modulated_pilot_IFFT)), end
    % GET IFFT RX PILOTS
    rx_pilots                                       = y_modulated_pilot_IFFT;
    rx_pilots(:)                                    = 0;
    rx_pilots(pilot_locations)                      = y_modulated_pilot_IFFT(pilot_locations);
    % FFT
    y_modulated_pilot                               = fft(y_modulated_pilot_IFFT, 32);
    if verbose, disp("Size y modulated pilot: " + size(y_modulated_pilot)), end
    % REMOVE PILOTS
    y_modulated                                     = RemovePilots(y_modulated_pilot, PilotDuplications, pilot_locations);
    if verbose, disp("Size of y modulated: " + size(y_modulated)), end
    % DEMODULATE
    y                                               = qamdemod(y_modulated, Modulation);
    if verbose, disp("Size of y: " + size(y)), end
end
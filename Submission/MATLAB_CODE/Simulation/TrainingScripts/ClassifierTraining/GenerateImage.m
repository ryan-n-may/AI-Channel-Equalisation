
function [IMAGE] = GenerateImage(SNR)
        %% Channel simulation configuration
        includeAWGN             = false;
        includeChannel          = true;
        Channels                = 1;
        TransmissionsPerChannel = 64;
        M                       = 32;
        Scaling                 = 1.0;
        MDS                     = 100;
        Modulation              = 4;
        BitLength               = 4;
        PilotSpacing            = 4;
        PilotValue              = -0.707 - 0.707*1i;
        SymbolDuplications      = 4;
        ModulationDuplications  = 1;
        PilotDuplications       = 4;
        [~,~,~,~,IFFT_Y,~,~,~,~,~,~] = GetChannelData(Channels,TransmissionsPerChannel, ...
              M,Scaling,SNR,MDS,Modulation,BitLength,PilotSpacing,PilotValue,SymbolDuplications, ...
              ModulationDuplications,PilotDuplications,includeAWGN,includeChannel, false, NaN, NaN);
        
        Y_Complex = (IFFT_Y(1:32, 1:64) + IFFT_Y(33:64, 1:64)*1i);
        FFT_Y = [real(fft(Y_Complex, 32)) ; imag(fft(Y_Complex, 32))];
        IMAGE = repelem(FFT_Y, 2, 2);
        awgn_channel = comm.AWGNChannel( ...
                "NoiseMethod", "Signal to noise ratio (SNR)", ...
                "SNR", SNR, ...
                "SignalPower", 1 ...
                );

        IMAGE = awgn_channel(IMAGE);
end
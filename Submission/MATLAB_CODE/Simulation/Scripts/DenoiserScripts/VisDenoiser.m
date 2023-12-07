clear variables;
close all;

%% Channel simulation configuration
includeAWGN             = false;
includeChannel          = true;
Channels                = 1;
TransmissionsPerChannel = 64;
M                       = 32;
Scaling                 = 1.0;
SNR                     = 10;
MDS                     = 100;
Modulation              = 4;
BitLength               = 4;
PilotSpacing            = 4;
PilotValue              = -0.707 - 0.707*1i;

SymbolDuplications      = 4;
ModulationDuplications  = 1;
PilotDuplications       = 4;


        %% Creating testing Data
        [~,~,~,IFFT_X,IFFT_Y,~,~,~,~,~,~] = GenerateLSTMData(Channels,TransmissionsPerChannel, ...
              M,Scaling,SNR,MDS,Modulation,BitLength,PilotSpacing,PilotValue,SymbolDuplications, ...
              ModulationDuplications,PilotDuplications,includeAWGN,includeChannel);
        
        disp("SIZE OF: " + size(IFFT_Y));
        disp("SIZE OF: " + size(IFFT_X));
        Y_Complex = (IFFT_Y(1:32, 1:64) + IFFT_Y(33:64, 1:64)*1i);
        X_Complex = (IFFT_X(1:32, 1:64) + IFFT_X(33:64, 1:64)*1i);
      
        FFT_X = [real(fft(X_Complex, 32)) ; imag(fft(X_Complex, 32))];
        FFT_Y = [real(fft(Y_Complex, 32)) ; imag(fft(Y_Complex, 32))];
        
        NOISY_INPUT = repelem(FFT_Y, 2, 2);

        awgn_channel = comm.AWGNChannel( ...
                "NoiseMethod", "Signal to noise ratio (SNR)", ...
                "SNR", SNR, ...
                "SignalPower", 1 ...
                );

        NOISY_INPUT = awgn_channel(NOISY_INPUT);
        CLEAN_OUTPUT = FFT_Y;

        disp("SIZE OF SCALED X : " + size(FFT_X));
        disp("SIZE OF SCALED Y : " + size(FFT_Y));
        
        matFile = matfile("denoiserNet.mat");
        denoiserNet = matFile.denoiserNet;
        
        %% Testing
        [OUTPUT_PREDICTION] = predict( ...
            denoiserNet, ...
            NOISY_INPUT);
        
        DrawMIMOData(CLEAN_OUTPUT, NOISY_INPUT, OUTPUT_PREDICTION, "");
        
        

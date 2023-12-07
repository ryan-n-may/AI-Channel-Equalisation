clear variables;
close all;

matFile = matfile("denoiserNet.mat");
denoiserNet = matFile.denoiserNet;

%{
matFile = matfile("denoiserNet_no_classification.mat");
denoiserNet_no_classification = matFile.denoiserNet;

matFile = matfile("denoiserNet_no_averaging.mat");
denoiserNet_no_averaging = matFile.denoiserNet;
%}

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
PilotValue              = -0.7071 - 0.7071*1i;

SymbolDuplications      = 4;
ModulationDuplications  = 1;
PilotDuplications       = 4;

MSE_NOISY = [];
MSE_CLEAN = [];
Q_ARRAY = [];

for SNR = 1:1:30
    %% Creating training Data
    [ LSTM_INPUT_SPLIT, ... 
      ~, ~, ...
      IFFT_X_SPLIT, IFFT_Y_SPLIT, ...
      CHANNEL_H_SPLIT, ...
      SYMBOL_X, SYMBOL_Y, ...
      PILOTS_X_SPLIT, PILOTS_Y_SPLIT ...
      ] = GenerateLSTMData(Channels,TransmissionsPerChannel, ...
                  M,Scaling,SNR,MDS,Modulation,BitLength,PilotSpacing,PilotValue,SymbolDuplications, ...
                  ModulationDuplications,PilotDuplications,includeAWGN,includeChannel);
    %% Converting IFFT_Y from split to complex. 
    IFFT_Y_COMPLEX  = (IFFT_Y_SPLIT(1:32, :) + IFFT_Y_SPLIT(33:64, :)*1i);
    IFFT_X_COMPLEX  = (IFFT_X_SPLIT(1:32, :) + IFFT_X_SPLIT(33:64, :)*1i);
    FFT_X_SPLIT     = [real(fft(IFFT_X_COMPLEX, 32)) ; imag(fft(IFFT_X_COMPLEX, 32))];
    FFT_Y_SPLIT     = [real(fft(IFFT_Y_COMPLEX, 32)) ; imag(fft(IFFT_Y_COMPLEX, 32))];
            
    [FFT_PREDICTION_SPLIT, FFT_Y_SPLIT_SCALED_NOISY, FFT_Y_SPLIT_SCALED, NOISY_Q] = RunDenoiser(FFT_Y_SPLIT, SNR, denoiserNet);
    
    FFT_Y_SPLIT_NOISY = FFT_Y_SPLIT_SCALED_NOISY(1:2:end, 1:2:end);
    MSE_NOISY = [MSE_NOISY ERROR(FFT_Y_SPLIT_NOISY, FFT_Y_SPLIT)];
    MSE_CLEAN = [MSE_CLEAN ERROR(FFT_PREDICTION_SPLIT, FFT_Y_SPLIT)];
    Q_ARRAY = [Q_ARRAY ; NOISY_Q];
end 

figure();
subplot(1,2,1);
hold on
semilogy(smooth(10*log10(MSE_NOISY)), '-*');
semilogy(smooth(10*log10(MSE_CLEAN)), '-o');
legend( ...
    "Noisy", ...
    "Denoised" ...
    )

subplot(1,2,2);
hold on
plot((smooth(MSE_NOISY)), '-*');
plot((smooth(MSE_CLEAN)), '-o');
legend( ...
    "Noisy", ...
    "Denoised" ...
    )





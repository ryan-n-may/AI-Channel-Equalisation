clear variables;
close all;

matFile = matfile("denoiserNet.mat");
denoiserNet = matFile.denoiserNet;

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
PilotValue              = -0.7071 - 0.7071*1i;

SymbolDuplications      = 4;
ModulationDuplications  = 1;
PilotDuplications       = 4;

REPEAT_DENOISING_RUNS = 320;
LSTM_INPUT_APPENDED     = [];
CHANNEL_H_APPENDED      = [];
IFFT_Y_APPENDED         = [];
IFFY_X_APPENDED         = [];

MSE_NOISY = [];
MSE_CLEAN = [];
for i = 1:1:REPEAT_DENOISING_RUNS
    %% Creating training Data
    [ LSTM_INPUT_SPLIT, ... 
      ~, ~, ...
      IFFT_X_SPLIT, IFFT_Y_SPLIT, ...
      CHANNEL_H_SPLIT, ...
      SYMBOL_X, SYMBOL_Y, ...
      PILOTS_X_SPLIT, PILOTS_Y_SPLIT ...
      ] = GetChannelData(Channels,TransmissionsPerChannel, ...
                  M,Scaling,SNR,MDS,Modulation,BitLength,PilotSpacing,PilotValue,SymbolDuplications, ...
                  ModulationDuplications,PilotDuplications,includeAWGN,includeChannel, false, NaN, NaN);
    %% Converting IFFT_Y from split to complex. 
    IFFT_Y_COMPLEX  = (IFFT_Y_SPLIT(1:32, :) + IFFT_Y_SPLIT(33:64, :)*1i);
    IFFT_X_COMPLEX  = (IFFT_X_SPLIT(1:32, :) + IFFT_X_SPLIT(33:64, :)*1i);
    FFT_X_SPLIT     = [real(fft(IFFT_X_COMPLEX, 32)) ; imag(fft(IFFT_X_COMPLEX, 32))];
    FFT_Y_SPLIT     = [real(fft(IFFT_Y_COMPLEX, 32)) ; imag(fft(IFFT_Y_COMPLEX, 32))];
            
    [FFT_PREDICTION_SPLIT, FFT_Y_SPLIT_SCALED_NOISY, FFT_Y_SPLIT_SCALED] = RunDenoiser(FFT_Y_SPLIT, SNR, denoiserNet);
    
    %DrawMIMOData(FFT_Y_SPLIT_SCALED_NOISY, FFT_PREDICTION_SPLIT, FFT_Y_SPLIT_SCALED, "Noisy, Predicted, Clean")
    FFT_Y_SPLIT_NOISY = FFT_Y_SPLIT_SCALED_NOISY(1:2:end, 1:2:end);
    MSE_NOISY = [MSE_NOISY CalculateMSE(FFT_Y_SPLIT_NOISY, FFT_Y_SPLIT)];
    MSE_CLEAN = [MSE_CLEAN CalculateMSE(FFT_PREDICTION_SPLIT, FFT_Y_SPLIT)];
    %disp("MSE Noisy: " + MSE_NOISY);
    %disp("MSE Clean: " + MSE_CLEAN);

    FFT_PREDICTION_COMPLEX = FFT_PREDICTION_SPLIT(1:32, :) + FFT_PREDICTION_SPLIT(33:64, :)*1i;
    IFFT_PREDICTION_COMPLEX = ifft(FFT_PREDICTION_COMPLEX, 32);
    
    
    %% Modifying outputs
    LSTM_VALID_INPUT    = [PILOTS_X_SPLIT(1:32, :) ; real(IFFT_PREDICTION_COMPLEX) ; PILOTS_X_SPLIT(33:64, :) ; imag(IFFT_PREDICTION_COMPLEX)];
    CHANNEL_VALID_H     = CHANNEL_H_SPLIT;
    IFFT_Y              = [real(IFFT_PREDICTION_COMPLEX) ; imag(IFFT_PREDICTION_COMPLEX)];
    IFFT_X              = IFFT_X_SPLIT;

    %% Appending outputs 
    LSTM_INPUT_APPENDED     = [LSTM_INPUT_APPENDED LSTM_VALID_INPUT];
    CHANNEL_H_APPENDED      = [CHANNEL_H_APPENDED CHANNEL_VALID_H];
    IFFT_Y_APPENDED         = [IFFT_Y_APPENDED IFFT_Y];
    IFFY_X_APPENDED         = [IFFY_X_APPENDED IFFT_X];
end


LSTM_VALID_INPUT = LSTM_INPUT_APPENDED;
CHANNEL_VALID_H = CHANNEL_H_APPENDED;
IFFT_X = IFFY_X_APPENDED;
IFFT_Y = IFFT_Y_APPENDED;

%{
figure();
hold on
plot(smooth(MSE_CLEAN));
plot(smooth(MSE_NOISY));
legend("Cleaned", "Noisy")
%}


save("LSTMVALIDATIONDATA.mat", "LSTM_VALID_INPUT", "CHANNEL_VALID_H");
save("LSTMVALIDATIONEQUALISATION.mat", "IFFT_X", "IFFT_Y");
save("LSTMVALIDATIONSYMBOLERRORS.mat", "SYMBOL_X", "SYMBOL_Y");


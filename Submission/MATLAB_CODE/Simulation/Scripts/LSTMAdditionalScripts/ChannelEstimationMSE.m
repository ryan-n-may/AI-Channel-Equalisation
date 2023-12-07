clear variables;
close all;

load("TrainedEstimator.mat", "LSTMnet", "lstm");
matFile = matfile("denoiserNet.mat");
denoiserNet = matFile.denoiserNet;

%% VALIDATION DATA ESTIMATION
includeAWGN             = false;
includeChannel          = true;
Channels                = 1;
TransmissionsPerChannel = 64;
M                       = 32;
Scaling                 = 1.0;
SNR                     = 5;
MDS                     = 100;
Modulation              = 4;
BitLength               = 4;
PilotSpacing            = 4;
PilotValue              = -0.7071 - 0.7071*1i;

SymbolDuplications      = 4;
ModulationDuplications  = 1;
PilotDuplications       = 4;
[ ~, ... 
 ~, ~, ...
 IFFT_X_SPLIT, IFFT_Y_SPLIT, ...
 CHANNEL_H_SPLIT, ...
 ~, ~, ...
 PILOTS_X_SPLIT, ~, ...
 PilotLocs ] = GenerateLSTMData( ...
                        Channels, ...
                        TransmissionsPerChannel, ...
                        M, ...
                        Scaling, ...
                        SNR, ...
                        MDS, ...
                        Modulation, ...
                        BitLength, ...
                        PilotSpacing, ...
                        PilotValue, ...
                        SymbolDuplications, ...
                        ModulationDuplications, ...
                        PilotDuplications, ...
                        includeAWGN, ...
                        includeChannel);

%% DENOISING LSTM INPUT
% Converting IFFT_Y from split to complex.
IFFT_Y_COMPLEX  = (IFFT_Y_SPLIT(1:32, :) + IFFT_Y_SPLIT(33:64, :)*1i);
IFFT_X_COMPLEX  = (IFFT_X_SPLIT(1:32, :) + IFFT_X_SPLIT(33:64, :)*1i);
FFT_Y_COMPLEX   = fft(IFFT_Y_COMPLEX, 32);
FFT_X_COMPLEX   = fft(IFFT_X_COMPLEX, 32);
FFT_X_SPLIT     = [real(FFT_X_COMPLEX) ; imag(FFT_X_COMPLEX)];
FFT_Y_SPLIT     = [real(FFT_Y_COMPLEX) ; imag(FFT_Y_COMPLEX)];
            
[FFT_PREDICTION_SPLIT, FFT_Y_SPLIT_SCALED_NOISY, FFT_Y_SPLIT_SCALED] = RunDenoiser(FFT_Y_SPLIT, SNR, denoiserNet);
    
%DrawMIMOData(FFT_Y_SPLIT_SCALED_NOISY, FFT_PREDICTION_SPLIT, FFT_Y_SPLIT_SCALED, "Noisy, Predicted, Clean")
FFT_Y_SPLIT_NOISY = FFT_Y_SPLIT_SCALED_NOISY(1:2:end, 1:2:end);
MSE_NOISY = ERROR(FFT_Y_SPLIT_NOISY, FFT_Y_SPLIT);
MSE_CLEAN = ERROR(FFT_PREDICTION_SPLIT, FFT_Y_SPLIT);
disp("MSE Noisy: " + MSE_NOISY);
disp("MSE Clean: " + MSE_CLEAN);

FFT_PREDICTION_COMPLEX = FFT_PREDICTION_SPLIT(1:32, :) + FFT_PREDICTION_SPLIT(33:64, :)*1i;
IFFT_PREDICTION_COMPLEX = ifft(FFT_PREDICTION_COMPLEX, 32);
    
% Modifying outputs
LSTM_INPUT  = [PILOTS_X_SPLIT(1:32, :) ; real(IFFT_PREDICTION_COMPLEX) ; PILOTS_X_SPLIT(33:64, :) ; imag(IFFT_PREDICTION_COMPLEX)];
CHANNEL_H   = CHANNEL_H_SPLIT(1:64, 1);
IFFT_Y_DENOISED      = [real(IFFT_PREDICTION_COMPLEX) ; imag(IFFT_PREDICTION_COMPLEX)];
IFFT_X_DENOISED      = IFFT_X_SPLIT;

%% LSTM ESTIMATION
[lstm, O_LSTM] = lstm.TestLSTM(LSTMnet, LSTM_INPUT);


%% LS ESTIMATION
FFT_Y_COMPLEX_NOISY = FFT_Y_SPLIT_NOISY(1:32) + FFT_Y_SPLIT_NOISY(33:64)*1i;
PILOTS_Y_NOISY_COMPLEX = FFT_Y_COMPLEX_NOISY(PilotLocs).';
PILOTS_X_COMPLEX = FFT_X_COMPLEX(PilotLocs);

MessageLocs = [];
for i = 1:1:32 
    MessageLocs = [MessageLocs; i];
end

[H_LS_COMPLEX, ~] = LS(PILOTS_Y_NOISY_COMPLEX, PILOTS_X_COMPLEX, PilotLocs, MessageLocs);
H_LS = [real(H_LS_COMPLEX) ; imag(H_LS_COMPLEX)];

%% MMSE ESTIMATION
h_CIR = CHANNEL_H(1:32) + CHANNEL_H(33:64)*1i;
H_MMSE_C = MMSE(H_LS_COMPLEX, h_CIR, 32, SNR);
H_MMSE = [real(H_MMSE_C); imag(H_MMSE_C)];

figure()
subplot(2,1,1)
title("(A)")
hold on
semilogy((CHANNEL_H(1:64, 1)),    '-o')
semilogy((O_LSTM(1:64, 1)),       '-x')
semilogy((H_LS(1:64, 1)),         '-*')
semilogy((H_MMSE(1:64, 1)),       '-^')
legend("Channel", "LSTM Estimation", "LS Estimation", "MMSE Estimation")
subplot(2,1,2)
title("(B)")
hold on
semilogy(10*log10(abs(CHANNEL_H(1:32) + CHANNEL_H(33:64)*1i)),  '--o')
semilogy(10*log10(abs(O_LSTM(1:32) + O_LSTM(33:64)*1i)),        '-x')
semilogy(10*log10(abs(H_LS(1:32) + H_LS(33:64)*1i)),            '-*');
semilogy(10*log10(abs(H_MMSE(1:32) + H_MMSE(33:64)*1i)),        '-^')
legend("Channel", "LSTM Estimation", "LS Estimation", "MMSE Estimation")


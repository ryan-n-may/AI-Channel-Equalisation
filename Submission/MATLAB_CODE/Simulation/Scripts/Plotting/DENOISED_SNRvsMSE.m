clear variables;
close all;
load("TrainedEstimator.mat", "lstm", "LSTMnet");
matFile = matfile("denoiserNet.mat");
denoiserNet = matFile.denoiserNet;

%% Channel simulation configuration
% Simulation specific variables
SNR_L = 1;
SNR_I = 5;
SNR_H = 50;

includeAWGN             = false;
includeChannel          = true;
Channels                = 64;
TransmissionsPerChannel = 1;
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


AVERAGEING_ROUNDS = 10;


AveragedMSE_LS          = [];
AveragedMSE_LS_DENOISED = [];
AveragedMSE_MMSE        = [];
AveragedMSE_LSTM        = [];

first = true;
%% Generating testing data in cells
for j = 1:AVERAGEING_ROUNDS
    
    MSE_LS          = [];
    MSE_LS_DENOISED = [];
    MSE_MMSE        = [];
    MSE_LSTM        = [];
    MSE_NOISY_RUN   = [];
    MSE_CLEAN_RUN   = [];

    for SNR = SNR_L:SNR_I:SNR_H 
        
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
        MSE_NOISY_RUN = [MSE_NOISY_RUN MSE_NOISY];
        MSE_CLEAN_RUN = [MSE_CLEAN_RUN MSE_CLEAN];
        %disp("MSE Noisy: " + MSE_NOISY);
        %disp("MSE Clean: " + MSE_CLEAN);
        
        FFT_PREDICTION_COMPLEX = FFT_PREDICTION_SPLIT(1:32, :) + FFT_PREDICTION_SPLIT(33:64, :)*1i;
        IFFT_PREDICTION_COMPLEX = ifft(FFT_PREDICTION_COMPLEX, 32);
            
        % Modifying outputs
        LSTM_INPUT  = [PILOTS_X_SPLIT(1:32, :) ; real(IFFT_PREDICTION_COMPLEX) ; PILOTS_X_SPLIT(33:64, :) ; imag(IFFT_PREDICTION_COMPLEX)];
        CHANNEL_H   = CHANNEL_H_SPLIT(1:64, 1);
        IFFT_Y_DENOISED      = [real(IFFT_PREDICTION_COMPLEX) ; imag(IFFT_PREDICTION_COMPLEX)];
        IFFT_X_DENOISED      = IFFT_X_SPLIT;
        
        %% LSTM ESTIMATION
        [lstm, O_LSTM] = lstm.TestLSTM(LSTMnet, LSTM_INPUT);
        O_LSTM_COMPLEX = O_LSTM(1:32) + O_LSTM(33:64)*1i;

        %% DENOISED LS ESTIMATION
        PILOTS_Y_COMPLEX = FFT_Y_COMPLEX(PilotLocs).';
        PILOTS_X_COMPLEX = FFT_X_COMPLEX(PilotLocs).';
        
        MessageLocs = [];
        for i = 1:1:32 
            MessageLocs = [MessageLocs; i];
        end
        
        [H_LS_DENOISED_COMPLEX, ~] = LS(PILOTS_Y_COMPLEX, PILOTS_X_COMPLEX, PilotLocs, MessageLocs);
        H_LS_DENOISED = [real(H_LS_DENOISED_COMPLEX) ; imag(H_LS_DENOISED_COMPLEX)];
        
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
        
        CHANNEL_H_Complex = CHANNEL_H(1:32) + CHANNEL_H(33:64)*1i;

        MSE_LS          = [MSE_LS,          ERROR(CHANNEL_H_Complex,    H_LS_COMPLEX)];
        MSE_LS_DENOISED = [MSE_LS_DENOISED, ERROR(CHANNEL_H_Complex,    H_LS_DENOISED_COMPLEX)];
        MSE_LSTM        = [MSE_LSTM,        ERROR(CHANNEL_H_Complex,    O_LSTM_COMPLEX)];   
        MSE_MMSE        = [MSE_MMSE,        ERROR(CHANNEL_H_Complex,    H_MMSE_C)];

       
    end
    if first 
        AveragedMSE_LS_DENOISED = MSE_LS_DENOISED;
        AveragedMSE_LS          = MSE_LS;
        AveragedMSE_MMSE        = MSE_MMSE;
        AveragedMSE_LSTM        = MSE_LSTM;
        first = false;      
    else
        AveragedMSE_LS_DENOISED = AveragedMSE_LS_DENOISED + MSE_LS_DENOISED;
        AveragedMSE_LS          = AveragedMSE_LS + MSE_LS;
        AveragedMSE_MMSE        = AveragedMSE_MMSE + MSE_MMSE;
        AveragedMSE_LSTM        = AveragedMSE_LSTM + MSE_LSTM;
    end
    
end

AveragedMSE_LS_DENOISED = AveragedMSE_LS_DENOISED ./ AVERAGEING_ROUNDS;
AveragedMSE_LS          = AveragedMSE_LS ./ AVERAGEING_ROUNDS;
AveragedMSE_MMSE        = AveragedMSE_MMSE ./ AVERAGEING_ROUNDS;
AveragedMSE_LSTM        = AveragedMSE_LSTM ./ AVERAGEING_ROUNDS;
 
figure()
hold on;    
semilogy(10*log10(AveragedMSE_LS_DENOISED), '-d');
semilogy(10*log10(AveragedMSE_LS),          '-*');
semilogy(10*log10(AveragedMSE_MMSE),        '-^');
semilogy(10*log10(AveragedMSE_LSTM),        '-s');
legend("Denoised LS", "LS", "MMSE", "LSTM");

%{
figure();
hold on;
semilogy(10*log10(MSE_NOISY_RUN), '-o');
semilogy(10*log10(MSE_CLEAN_RUN), '-s');
legend("MSE of noisy data", "MSE of denoised data");

%}
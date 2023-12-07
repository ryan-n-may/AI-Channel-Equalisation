clear variables;
close all;
load("TrainedEstimator.mat", "lstm", "LSTMnet");

%% Channel simulation configuration
% Simulation specific variables
SNR_L = 1;
SNR_I = 10;
SNR_H = 50;

includeAWGN             = true;
includeChannel          = true;
Channels                = 1000;
TransmissionsPerChannel = 1;
M                       = 32;
Scaling                 = 1.0;
MDS                     = 100;
Modulation              = 4;
BitLength               = 4;
PilotSpacing            = 4;
PilotValue              = -0.123 + 0.123*1i;

SymbolDuplications      = 4;
ModulationDuplications  = 1;
PilotDuplications       = 4;


AVERAGEING_ROUNDS = 10;


AveragedMSE_LS          = [];
AveragedMSE_MMSE        = [];
AveragedMSE_LSTM        = [];

first = true;
%% Generating testing data in cells
for j = 1:AVERAGEING_ROUNDS
    
    MSE_LS          = [];
    MSE_MMSE        = [];
    MSE_LSTM        = [];
    for i = SNR_L:SNR_I:SNR_H 
        IFFT_X_AV = 0;
        IFFT_Y_AV = 0;
        LSTM_INPUT_AV = 0;
        CHANNEL_H_AV = 0;
        [ LSTM_INPUT, ... 
          FFT_X, FFT_Y, ...
          IFFT_X, IFFT_Y, ...
          CHANNEL_H, ...
          SYMBOL_X, SYMBOL_Y, ...
          PILOTS_X, PILOTS_Y, ...
          PilotLocs ] = GenerateLSTMData( ...
                        Channels, ...
                        TransmissionsPerChannel, ...
                        M, ...
                        Scaling, ...
                        i, ...
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
        CHANNEL_H_Complex = CHANNEL_H(1:32) + CHANNEL_H(33:64)*1i;
        complexY = IFFT_Y(1:32) + IFFT_Y(33:64).*1i;
        complexX = IFFT_X(1:32) + IFFT_X(33:64).*1i;

        complexYFFT = fft(complexY, 32);
        complexXFFT = fft(complexX, 32);
        

        %% LS Estimation
        % Estimate
        PILOTS_Y_C = PILOTS_Y(1:32) + PILOTS_Y(33:64).*1i;
        PILOTS_X_C = PILOTS_X(1:32) + PILOTS_X(33:64).*1i;
        PILOTS_Y_C_M = [];
        PILOTS_X_C_M = [];
        for j = 1:1:32
            if PILOTS_Y_C(j) ~= 0
                PILOTS_Y_C_M = [PILOTS_Y_C_M ; PILOTS_Y_C(j)];
                PILOTS_X_C_M = [PILOTS_X_C_M ; PILOTS_X_C(j)];
            end
        end
        MessageLocs = [];
        for k = 1:1:32 
            MessageLocs = [MessageLocs; k];
        end
        [H_LS, ~] = LS(PILOTS_Y_C_M, PILOTS_X_C_M, PilotLocs, MessageLocs);
        % MSE
        MSE_LS = [MSE_LS, ERROR(CHANNEL_H_Complex, H_LS)];
               

        %% LSTM Estimation
        % Estimate
        [lstm, LSTMchannelEstimation] = lstm.TestLSTM(LSTMnet, LSTM_INPUT);
        H_LSTM = LSTMchannelEstimation(1:32) + LSTMchannelEstimation(33:64).*1i;
        % MSE
        MSE_LSTM = [MSE_LSTM, ERROR(CHANNEL_H_Complex, H_LSTM)];   

        %% MMSE Estimation
        % Estimate
        H_MMSE = MMSE(H_LS, CHANNEL_H_Complex.', 32, i);
        % MSE
        MSE_MMSE = [MSE_MMSE, ERROR(CHANNEL_H_Complex, H_MMSE)];
        
        
        

    end
    if first 
        
        AveragedMSE_LS          = MSE_LS;
        AveragedMSE_MMSE        = MSE_MMSE;
        AveragedMSE_LSTM        = MSE_LSTM;
        first = false;      
    else
        
        AveragedMSE_LS          = AveragedMSE_LS + MSE_LS;
        AveragedMSE_MMSE        = AveragedMSE_MMSE + MSE_MMSE;
        AveragedMSE_LSTM        = AveragedMSE_LSTM + MSE_LSTM;
    end
    
end

AveragedMSE_LS          = AveragedMSE_LS ./ AVERAGEING_ROUNDS;
AveragedMSE_MMSE        = AveragedMSE_MMSE ./ AVERAGEING_ROUNDS;
AveragedMSE_LSTM        = AveragedMSE_LSTM ./ AVERAGEING_ROUNDS;
 
figure()
hold on;
semilogy(10*log10(AveragedMSE_LS),        '-*');
semilogy(10*log10(AveragedMSE_MMSE),      '-^');
semilogy(10*log10(AveragedMSE_LSTM),      '-s');
legend("LS", "MMSE", "LSTM");
clear variables;
close all;
load("TrainedEstimator.mat", "lstm", "LSTMnet");

%% Channel simulation configuration
% Simulation specific variables
MDS_L = 10;
MDS_I = 50;
MDS_H = 1000;

onlyAWGN                = false;
Channels                = 1;
TransmissionsPerChannel = 1;
M                       = 8;
Scaling                 = 0.25;
SNR                     = 50;
Modulation              = 4;
BitLength               = 4;
PilotSpacing            = 4;
PilotValue              = -0.123 + 0.123*1i;

SymbolDuplications      = 4;
ModulationDuplications  = 1;
PilotDuplications       = 4;


AVERAGEING_ROUNDS = 5;

AveragedMSE_Coherent    = [];
AveragedMSE_Raw         = [];
AveragedMSE_LS          = [];
AveragedMSE_MMSE        = [];
AveragedMSE_LSTM        = [];

first = true;
%% Generating testing data in cells
for j = 1:AVERAGEING_ROUNDS
    MSE_Raw         = [];
    MSE_Coherent    = [];
    MSE_LS          = [];
    MSE_MMSE        = [];
    MSE_LSTM        = [];
    for i = MDS_L:MDS_I:MDS_H 
        disp("MDS: " + i);
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
                        SNR, ...
                        i, ...
                        Modulation, ...
                        BitLength, ...
                        PilotSpacing, ...
                        PilotValue, ...
                        SymbolDuplications, ...
                        ModulationDuplications, ...
                        PilotDuplications, ...
                        onlyAWGN);
        CHANNEL_H_Complex = CHANNEL_H(1:32) + CHANNEL_H(33:64)*1i;
        complexY = IFFT_Y(1:32) + IFFT_Y(33:64).*1i;
        complexX = IFFT_X(1:32) + IFFT_X(33:64).*1i;

        complexYFFT = fft(complexY, 32);
        complexXFFT = fft(complexX, 32);
        %% NO Estimation
        MSE_Raw = [MSE_Raw, SymbolErrorRate(ModulationToSymbols(complexXFFT, 4), ModulationToSymbols(complexYFFT, 4))];

        %% Coherent Estimation
        % Equalise
        complexE_Coherent = complexX;
        % MSE
        SymbolErrorRate(ModulationToSymbols(complexXFFT, 4), ModulationToSymbols(fft(complexE_Coherent, 32), 4)) 
        MSE_Coherent = [MSE_Coherent,  SymbolErrorRate(ModulationToSymbols(complexXFFT, 4), ModulationToSymbols(fft(complexE_Coherent, 32), 4))];


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
        % Equalise
        complexE_LS = complexY ./ H_LS;
        % MSE
        LS_SER = SymbolErrorRate(ModulationToSymbols(complexXFFT, 4), ModulationToSymbols(fft(complexE_LS, 32), 4));
        if LS_SER < 1/i
            MSE_LS = [MSE_LS, 1/i];
            disp("USING THEORETICAL LS SER");
        else 
            MSE_LS = [MSE_LS, LS_SER];
        end

        %% LSTM Estimation
        % Estimate
        [lstm, LSTMchannelEstimation] = lstm.TestLSTM(LSTMnet, LSTM_INPUT);
        % EQUALISE
        complexChannelEstimation = LSTMchannelEstimation(1:32) + LSTMchannelEstimation(33:64).*1i;
        complexE_LSTM = complexY ./ complexChannelEstimation;
        % MSE
        MSE_LSTM = [MSE_LSTM, SymbolErrorRate(ModulationToSymbols(complexXFFT, 4), ModulationToSymbols(fft(complexE_LSTM, 32), 4))];   

        %% MMSE Estimation
        % Estimate
        H_MMSE = MMSE(H_LS, CHANNEL_H_Complex, 32, i);
        % Equalise
        complexE_MMSE = complexY ./ H_MMSE;
        % MSE
        MSE_MMSE = [MSE_MMSE, SymbolErrorRate(ModulationToSymbols(complexXFFT, 4), ModulationToSymbols(fft(complexE_MMSE, 32), 4))];
        
    end
    if first 
        AveragedMSE_Coherent    = MSE_Coherent;
        AveragedMSE_Raw         = MSE_Raw;
        AveragedMSE_LS          = MSE_LS;
        AveragedMSE_MMSE        = MSE_MMSE;
        AveragedMSE_LSTM        = MSE_LSTM;
        first = false;      
    else
        AveragedMSE_Coherent    = AveragedMSE_Coherent + MSE_Coherent;
        AveragedMSE_Raw         = AveragedMSE_Raw + MSE_Raw;
        AveragedMSE_LS          = AveragedMSE_LS + MSE_LS;
        AveragedMSE_MMSE        = AveragedMSE_MMSE + MSE_MMSE;
        AveragedMSE_LSTM        = AveragedMSE_LSTM + MSE_LSTM;
    end
    
end

AveragedMSE_Coherent    = AveragedMSE_Coherent ./ AVERAGEING_ROUNDS;
AveragedMSE_Raw         = AveragedMSE_Raw ./ AVERAGEING_ROUNDS;
AveragedMSE_LS          = AveragedMSE_LS ./ AVERAGEING_ROUNDS;
AveragedMSE_MMSE        = AveragedMSE_MMSE ./ AVERAGEING_ROUNDS;
AveragedMSE_LSTM        = AveragedMSE_LSTM ./ AVERAGEING_ROUNDS;
 
figure()
hold on;
plot(AveragedMSE_Coherent,  '--')
plot(AveragedMSE_Raw,       '-o');
plot(AveragedMSE_LS,        '-*');
plot(AveragedMSE_MMSE,      '-^');
plot(AveragedMSE_LSTM,      '-s');
title("SNR vs MDS: Channel equalisation methods");
xlabel("Maximum Doppler Shift (Hz)");
ylabel("SER");
legend("Coherent", "No Equalisation", "LS", "MMSE", "LSTM");
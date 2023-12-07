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
PilotValue              = -0.7071 - 0.7071*1i;

SymbolDuplications      = 4;
ModulationDuplications  = 1;
PilotDuplications       = 4;


AVERAGEING_ROUNDS = 10;

AveragedMSE_Coherent    = [];
AveragedMSE_Raw         = [];
AveragedMSE_LS          = [];
AveragedMSE_MMSE        = [];
AveragedMSE_LSTM        = [];
AveragedMSE_LSTMCNN     = [];

first = true;
%% Generating testing data in cells
for j = 1:AVERAGEING_ROUNDS
    MSE_Raw         = [];
    MSE_Coherent    = [];
    MSE_LS          = [];
    MSE_MMSE        = [];
    MSE_LSTM        = [];
    MSE_LSTMCNN     = [];
    for i = SNR_L:SNR_I:SNR_H 
        
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
        CHANNEL_H_Complex = CHANNEL_H(1:32, :) + CHANNEL_H(33:64, :)*1i;
        complexY = IFFT_Y(1:32, :) + IFFT_Y(33:64, :).*1i;
        complexX = IFFT_X(1:32, :) + IFFT_X(33:64, :).*1i;

        complexYFFT = fft(complexY, 32);
        complexXFFT = fft(complexX, 32);

        %% ESTIMATION 
        [H_LS, H_MMSE]  = RunLSMMSE(PILOTS_X(:, 1), PILOTS_Y(:, 1), CHANNEL_H(:, 1), PilotLocs, 32, i, false);
        [H_LSTM]        = RunLSTM(PILOTS_X, LSTM_INPUT, lstm, LSTMnet, false, i);
        %H_LSTM          = mean(H_LSTM, 2);

        %% EQUALISATION
        complexE_Coherent           = complexX;
        complexE_MMSE               = complexY(:, 1) ./ H_MMSE;
        complexE_LS                 = complexY(:, 1) ./ H_LS;
        complexE_LSTM               = complexY(:, 1) ./ H_LSTM(:, 1);
         
        %{
        PlotLSTMEstimate(CHANNEL_H(:, 1), [real(H_LSTM(:, 1)) ; imag(H_LSTM(:, 1))], "LSTM SNR = " + i);
        PlotLSTMEstimate(CHANNEL_H(:, 1), [real(H_MMSE) ; imag(H_MMSE)], "MMSE SNR = " + i);
        PlotLSTMEstimate(CHANNEL_H(:, 1), [real(H_LS) ; imag(H_LS)], "LS SNR = " + i);
        PlotLSTMOutput(fft(complexE_LSTM, 32), fft(complexX, 32), fft(complexY, 32), "LSTM SNR = " + i);
        PlotLSTMOutput(fft(complexE_MMSE, 32), fft(complexX, 32), fft(complexY, 32), "MMSE SNR = " + i);
        PlotLSTMOutput(fft(complexE_LS, 32), fft(complexX, 32), fft(complexY, 32), "LS SNR = " + i);
        %}

        %% MODULATION TO SYMBOLS
        SYM_X           = ModulationToSymbols(fft(complexX, 32), 4);
        SYM_E_Coherent  = ModulationToSymbols(fft(complexE_Coherent, 32), 4);
        SYM_E_Raw       = ModulationToSymbols(fft(complexY, 32), 4);
        SYM_E_MMSE      = ModulationToSymbols(fft(complexE_MMSE, 32), 4);
        SYM_E_LS        = ModulationToSymbols(fft(complexE_LS, 32), 4);
        SYM_E_LSTM      = ModulationToSymbols(fft(complexE_LSTM, 32), 4);
        
        %% SER
        SER_Coherent    = SymbolErrorRate(SYM_E_Coherent, SYM_X);
        SER_Raw         = SymbolErrorRate(SYM_E_Raw, SYM_X);
        SER_MMSE        = SymbolErrorRate(SYM_E_MMSE, SYM_X);
        SER_LS          = SymbolErrorRate(SYM_E_LS, SYM_X);
        SER_LSTM        = SymbolErrorRate(SYM_E_LSTM, SYM_X);

        %% UPDATE ARRAYS
        MSE_Coherent    = [MSE_Coherent SER_Coherent];
        MSE_Raw         = [MSE_Raw SER_Raw];
        MSE_MMSE        = [MSE_MMSE SER_MMSE];
        MSE_LS          = [MSE_LS SER_LS];
        MSE_LSTM        = [MSE_LSTM SER_LSTM];
        
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
plot(AveragedMSE_Coherent,  '--');
plot(AveragedMSE_Raw,       '-o');
plot(AveragedMSE_LS,        '-*');
plot(AveragedMSE_MMSE,      '-^');
plot(AveragedMSE_LSTM,      '-s');
title("SNR vs SER: Channel equalisation methods");
xlabel("SNR (dB)");
ylabel("SER");
legend("Coherent", "No Equalisation", "LS", "MMSE", "LSTM");
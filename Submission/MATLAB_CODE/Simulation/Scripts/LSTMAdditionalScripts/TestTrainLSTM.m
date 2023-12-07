clear variables;
close all;
load("LSTMTRAININGDATA.mat", "LSTM_INPUT", "CHANNEL_H");
load("LSTMEQUALISATION.mat", "IFFT_X", "IFFT_Y");
load("TrainedEstimator.mat", "LSTMnet", "lstm");
CHANNEL = 1:2048;
PLOTLIMIT = 1:1;
P = LSTM_INPUT(:, CHANNEL);
H = CHANNEL_H(:, CHANNEL);
X = IFFT_X;
Y = IFFT_Y;



%% Testing training data
[lstm, O] = lstm.TestLSTM(LSTMnet, P);

PlotLSTMEstimate(H(:, 1), O(:, 1), "Estimation from training data");
%% Equalising 
O_Complex = (O(1:32, CHANNEL) + O(33:64, CHANNEL)*1i);
H_Complex = (H(1:32, CHANNEL) + H(33:64, CHANNEL)*1i);
Y_Complex = (Y(1:32, CHANNEL) + Y(33:64, CHANNEL)*1i);
X_Complex = (X(1:32, CHANNEL) + X(33:64, CHANNEL)*1i);
E_Complex = Y_Complex ./ O_Complex;

%% NOISE READING
MSE_CLEAN = ERROR(Y_Complex, X_Complex);
MSE_EQD = ERROR(E_Complex, X_Complex);
disp("MSE CLEAN: " + MSE_CLEAN);
disp("MSE EQD: " + MSE_EQD);

%% Converting to symbols and calculating SER
E_Symbols = ModulationToSymbols(E_Complex, 4);
X_Symbols = ModulationToSymbols(X_Complex, 4);
Y_Symbols = ModulationToSymbols(Y_Complex, 4);
SER_CLEAN = SymbolErrorRateMIMO(X_Symbols, Y_Symbols);
SER_EQD = SymbolErrorRateMIMO(X_Symbols, E_Symbols);
disp("SER CLEAN: " + SER_CLEAN)
disp("SER EQD: " + SER_EQD)

E_Complex_FFT = fft(E_Complex, 32);
Y_Complex_FFT = fft(Y_Complex, 32);
X_Complex_FFT = fft(X_Complex, 32);

%% Plotting
PlotLSTMOutput( ...
    E_Complex_FFT(:, PLOTLIMIT),  ...
    Y_Complex_FFT(:, PLOTLIMIT),  ...
    X_Complex_FFT(:, PLOTLIMIT),  ...
    "Equalised | Y | X");
VisualiseAWGN( ...
    real(E_Complex_FFT(:, PLOTLIMIT)), ...
    real(Y_Complex_FFT(:, PLOTLIMIT)), ...
    real(X_Complex_FFT(:, PLOTLIMIT)), ...
    "E | Y | X", "E", "Y", "X");
save("TrainedEstimator.mat", "lstm", "LSTMnet");

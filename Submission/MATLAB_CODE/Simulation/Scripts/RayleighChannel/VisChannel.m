clear variables;
load("TrainedEstimator.mat", "lstm", "LSTMnet");
matFile = matfile("denoiserNet.mat");
denoiserNet = matFile.denoiserNet;

% Channel simulation configuration
includeAWGN             = false;
includeChannel          = true;
Channels                = 1;
TransmissionsPerChannel = 64;
M                       = 32;
Scaling                 = 1.0;
SNR                     = 50;
Modulation              = 4;
BitLength               = 4;
PilotSpacing            = 4;
PilotValue              = -0.7071 - 0.7071*1i;

SymbolDuplications      = 4;
ModulationDuplications  = 1;
PilotDuplications       = 4;

MDS                     = [10 24 60 100 200];
SR                      = [1  1  1  1   1  ];
Samples                 = [];
Samples_H_LS            = [];
Samples_H_MMSE          = [];
Samples_H_LSTM          = [];

for i  = 1:5
   
    
    [ ~, ... 
         ~, ~, ...
         IFFT_X_SPLIT, IFFT_Y_SPLIT, ...
         CHANNEL_H_SPLIT, ...
         ~, ~, ...
         PILOTS_X_SPLIT, ~, ...
         PilotLocs ] = GetChannelData( ...
                    Channels, ...
                    TransmissionsPerChannel, ...
                    M, ...
                    Scaling, ...
                    SNR, ...
                    MDS(i), ...
                    Modulation, ...
                    BitLength, ...
                    PilotSpacing, ...
                    PilotValue, ...
                    SymbolDuplications, ...
                    ModulationDuplications, ...
                    PilotDuplications, ...
                    includeAWGN, ...
                    includeChannel, ...
                    true, ...
                    SR(i), ...
                    100);

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
        %DrawMIMOData(FFT_Y_SPLIT_SCALED_NOISY, FFT_Y_SPLIT_NOISY, FFT_Y_SPLIT_SCALED, "Noisy, Predicted, Clean")
        FFT_Y_COMPLEX_NOISY = FFT_Y_SPLIT_NOISY(1:32, :) + FFT_Y_SPLIT_NOISY(33:64, :)*1i;
        IFFT_Y_COMPLEX_NOISY = ifft(FFT_Y_COMPLEX_NOISY, 32);
        
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
  
        %% COHERENT ESTIMATION
        CHANNEL_H_Complex = CHANNEL_H(1:32) + CHANNEL_H(33:64)*1i;

    
    CHANNEL_H_C = CHANNEL_H(1:32) + CHANNEL_H(33:64);
    Samples         = [Samples          CHANNEL_H_C];
    Samples_H_LS    = [Samples_H_LS     H_LS_COMPLEX];
    Samples_H_MMSE  = [Samples_H_MMSE   H_MMSE_C];
    Samples_H_LSTM  = [Samples_H_LSTM   O_LSTM_COMPLEX.'];

end
load("TrainedEstimator.mat", "lstm", "LSTMnet");
matFile = matfile("denoiserNet.mat");
denoiserNet = matFile.denoiserNet;


figure();
subplot(1,5,1)
hold on;
semilogy(10*log10(abs(Samples(:, 1))));
semilogy(10*log10(abs(Samples_H_MMSE(:, 1))));
semilogy(10*log10(abs(Samples_H_LSTM(:, 1))));

subplot(1,5,2)
hold on;
semilogy(10*log10(abs(Samples(:, 2))));
semilogy(10*log10(abs(Samples_H_MMSE(:, 2))));
semilogy(10*log10(abs(Samples_H_LSTM(:, 2))));

subplot(1,5,3)
hold on;
semilogy(10*log10(abs(Samples(:, 3))));
semilogy(10*log10(abs(Samples_H_MMSE(:, 3))));
semilogy(10*log10(abs(Samples_H_LSTM(:, 3))));

subplot(1,5,4)
hold on;
semilogy(10*log10(abs(Samples(:, 4))));
semilogy(10*log10(abs(Samples_H_MMSE(:, 4))));
semilogy(10*log10(abs(Samples_H_LSTM(:, 4))));

subplot(1,5,5)
hold on;
semilogy(10*log10(abs(Samples(:, 5))));
semilogy(10*log10(abs(Samples_H_MMSE(:, 5))));
semilogy(10*log10(abs(Samples_H_LSTM(:, 5))));
legend("Channel", "MMSE", "LSTM")


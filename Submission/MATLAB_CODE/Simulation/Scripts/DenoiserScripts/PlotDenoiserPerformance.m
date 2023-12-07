clear variables;
close all;
matFile = matfile("denoiserNet.mat");
denoiserNet = matFile.denoiserNet;

%% Channel simulation configuration
includeAWGN             = false;
includeChannel          = true;
Channels                = 1;
TransmissionsPerChannel = 128;
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

MSE_NOISE_AV_R = zeros(1, 30);
MSE_NOISE_AV_D = zeros(1, 30);
for AV = 1:1:1
    MSE_NOISE_RAW = [];
    MSE_NOISE_DEN = [];
    for SNR = 1:1:30
        %% Creating data to denoise
        [~,~,~,~,IFFT_Y_SPLIT,~,~,~,~,~,~] ... 
        = GetChannelData(Channels,TransmissionsPerChannel,M,Scaling,SNR,MDS,Modulation, ...
                           BitLength,PilotSpacing,PilotValue,SymbolDuplications,ModulationDuplications, ...
                           PilotDuplications,includeAWGN,includeChannel, false, NaN, NaN);
        %% DenoisingNOISY
        FFT_Y_COMPLEX = fft(IFFT_Y_SPLIT(1:32, 1:64) + IFFT_Y_SPLIT(33:64, 1:64)*1i, 32);
        FFT_Y_SPLIT   = [real(FFT_Y_COMPLEX) ; imag(FFT_Y_COMPLEX)];
        % Run denoiser
        [FFT_DENOISED_SPLIT, FFT_NOISY_SPLIT, FFT_CLEAN_SPLIT] = RunDenoiser(FFT_Y_SPLIT, SNR, denoiserNet);
        %DrawMIMOData(FFT_DENOISED_SPLIT, FFT_NOISY_SPLIT, FFT_CLEAN_SPLIT, "Visualising Noise");
        FFT_DENOISED_COMPLEX = FFT_DENOISED_SPLIT(1:32, :) + FFT_DENOISED_SPLIT(33:64, :)*1i;
        FFT_DENOISED_SPLIT_UPSCALED = repelem(FFT_DENOISED_SPLIT, 2, 2);
        %% Calculating MSE
        MSE_NOISY   = norm(FFT_CLEAN_SPLIT - FFT_NOISY_SPLIT, 'fro')^2/numel(FFT_CLEAN_SPLIT);
        MSE_CLEANED = norm(FFT_CLEAN_SPLIT - FFT_DENOISED_SPLIT_UPSCALED, 'fro')^2/numel(FFT_CLEAN_SPLIT);
        %DrawMIMOData(FFT_O_Upscaled_for_comparison, FFT_Y_NOISY, FFT_Y_CLEAN, "O Y_noisy Y_clean");
        MSE_NOISE_RAW = [MSE_NOISE_RAW MSE_NOISY];
        MSE_NOISE_DEN = [MSE_NOISE_DEN MSE_CLEANED];
    end
    MSE_NOISE_AV_R = MSE_NOISE_AV_R + MSE_NOISE_RAW;
    MSE_NOISE_AV_D = MSE_NOISE_AV_D + MSE_NOISE_DEN;
end
MSE_NOISE_AV_R = MSE_NOISE_AV_R ./ AV;
MSE_NOISE_AV_D = MSE_NOISE_AV_D ./ AV;

MSE_LS_AV_R = zeros(1, 20);
MSE_LS_AV_D = zeros(1, 20);
for AV = 1:1:10
    MSE_LS_RAW = [];
    MSE_LS_DEN = [];
    for SNR = 1:1:20
        %% Creating testing Data
        [~,~,~,IFFT_X_SPLIT,IFFT_Y_SPLIT,CHANNEL_H_SPLIT,~,~,PILOTS_X_SPLIT,~,PILOT_LOCS] ... 
        = GetChannelData(Channels,TransmissionsPerChannel,M,Scaling,SNR,MDS,Modulation, ...
                           BitLength,PilotSpacing,PilotValue,SymbolDuplications,ModulationDuplications, ...
                           PilotDuplications,includeAWGN,includeChannel, false, NaN, NaN);
        %% COMPUTING FIRST HALF of 128 SAMPLES: 64 by 64.
        FFT_Y_COMPLEX = fft(IFFT_Y_SPLIT(1:32, 1:64) + IFFT_Y_SPLIT(33:64, 1:64)*1i, 32);
        FFT_Y_SPLIT   = [real(FFT_Y_COMPLEX) ; imag(FFT_Y_COMPLEX)];
        % Run denoiser
        [FFT_DENOISED_SPLIT_1, FFT_NOISY_SPLIT_1, FFT_CLEAN_SPLIT] = RunDenoiser(FFT_Y_SPLIT, SNR, denoiserNet);
        %DrawMIMOData(FFT_DENOISED_SPLIT_1, FFT_NOISY_SPLIT_1, FFT_CLEAN_SPLIT, "Visualising Noise");
        FFT_DENOISED_COMPLEX_1 = FFT_DENOISED_SPLIT_1(1:32, :) + FFT_DENOISED_SPLIT_1(33:64, :)*1i;
        IFFT_DENOISED_COMPLEX_1 = ifft(FFT_DENOISED_COMPLEX_1, 32);
        %% 2nd HALF
        FFT_Y_COMPLEX = fft(IFFT_Y_SPLIT(1:32, 65:128) + IFFT_Y_SPLIT(33:64, 65:128)*1i, 32);
        FFT_Y_SPLIT = [real(FFT_Y_COMPLEX) ; imag(FFT_Y_COMPLEX)];
        % Run denoiser
        [FFT_DENOISED_SPLIT_2, FFT_NOISY_SPLIT_2, ~] = RunDenoiser(FFT_Y_SPLIT, SNR, denoiserNet);
        FFT_DENOISED_COMPLEX_2 = FFT_DENOISED_SPLIT_2(1:32, :) + FFT_DENOISED_SPLIT_2(33:64, :)*1i;
        FFT_DENOISED_COMPLEX_1 = FFT_DENOISED_SPLIT_1(1:32, :) + FFT_DENOISED_SPLIT_1(33:64, :)*1i;
        %% Combining halves
        FFT_DENOISED_COMPLEX = [FFT_DENOISED_COMPLEX_1 FFT_DENOISED_COMPLEX_2];
        FFT_NOISY_SPLIT_1 = FFT_NOISY_SPLIT_1(1:2:end, 1:2:end);
        FFT_NOISY_SPLIT_2 = FFT_NOISY_SPLIT_2(1:2:end, 1:2:end);
        FFT_NOISY_COMPLEX_1 = FFT_NOISY_SPLIT_1(1:32, :) + FFT_NOISY_SPLIT_1(33:64, :)*1i;
        FFT_NOISY_COMPLEX_2 = FFT_NOISY_SPLIT_2(1:32, :) + FFT_NOISY_SPLIT_2(33:64, :)*1i;
        FFT_NOISY_COMPLEX = [FFT_NOISY_COMPLEX_1 FFT_NOISY_COMPLEX_2];
        PILOTS_X_COMPLEX = PILOTS_X_SPLIT(1:32, :) + PILOTS_X_SPLIT(33:64, :)*1i;
        IFFT_NOISY_COMPLEX = ifft(FFT_NOISY_COMPLEX, 32);
        IFFT_DENOISED_COMPLEX = ifft(FFT_DENOISED_COMPLEX, 32);
        NOISY_PILOTS_Y_COMPLEX = PILOTS_X_COMPLEX;
        NOISY_PILOTS_Y_COMPLEX(PILOT_LOCS) = IFFT_NOISY_COMPLEX(PILOT_LOCS);
        NOISY_PILOTS_Y_SPLIT = [real(NOISY_PILOTS_Y_COMPLEX) ; imag(NOISY_PILOTS_Y_COMPLEX)];
        DENOISED_PILOTS_Y_COMPLEX = PILOTS_X_COMPLEX;
        DENOISED_PILOTS_Y_COMPLEX(PILOT_LOCS) = IFFT_DENOISED_COMPLEX(PILOT_LOCS);
        DENOISED_PILOTS_Y_SPLIT = [real(DENOISED_PILOTS_Y_COMPLEX) ; imag(DENOISED_PILOTS_Y_COMPLEX)];
        H_COMPLEX = CHANNEL_H_SPLIT(1:32, :) + CHANNEL_H_SPLIT(33:64, :)*1i;
        [H_LS_NOISY_COMPLEX, ~] = RunLSMMSE(PILOTS_X_SPLIT, ...
            NOISY_PILOTS_Y_SPLIT, ...
            CHANNEL_H_SPLIT, PILOT_LOCS, 32, SNR, false);
        [H_LS_DENOISED_COMPLEX, ~] = RunLSMMSE(PILOTS_X_SPLIT, ...
            DENOISED_PILOTS_Y_SPLIT, ...
            CHANNEL_H_SPLIT, PILOT_LOCS, 32, SNR, false);        
        MSE_LS_RAW = [MSE_LS_RAW CalculateMSE(H_COMPLEX, H_LS_NOISY_COMPLEX)];
        MSE_LS_DEN = [MSE_LS_DEN CalculateMSE(H_COMPLEX, H_LS_DENOISED_COMPLEX)];
    end
    MSE_LS_AV_R = MSE_LS_AV_R + MSE_LS_RAW;
    MSE_LS_AV_D = MSE_LS_AV_D + MSE_LS_DEN;
end
MSE_LS_AV_R = MSE_LS_AV_R ./ AV;
MSE_LS_AV_D = MSE_LS_AV_D ./ AV;

figure();
subplot(1,2,2);
hold on;
plot((MSE_LS_AV_R), '-x');
plot((MSE_LS_AV_D), '--o');
legend("MSE of noisy output", "MSE of cleaned output");
subplot(1,2,1);
hold on;
semilogy(10*log10(MSE_NOISE_AV_R), '-x');
semilogy(10*log10(MSE_NOISE_AV_D), '--o');
legend("MSE of Noisy Output", "MSE of Cleaned Output");

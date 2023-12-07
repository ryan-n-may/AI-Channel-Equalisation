function [FFT_O, FFT_Y_NOISY, FFT_Y_CLEAN, NOISY_Q] = RunDenoiser(FFT_Y, SNR, denoiserNet)
    % Duplicate "image" before adding AWGN
    FFT_Y_R = repelem(FFT_Y, 2, 2); % 128 by 128
    % Generate AWGN
    awgn_channel = comm.AWGNChannel( ...
                "NoiseMethod", "Signal to noise ratio (SNR)", ...
                "SNR", SNR, ...
                "SignalPower", 1 ...
                );
    FFT_Y_CLEAN = FFT_Y_R;
    FFT_Y_NOISY = awgn_channel(FFT_Y_R);
    
    % Denoiser
    load("ClassifierModel.mat", "net");
    imwrite(mat2gray(FFT_Y_NOISY), "Temp.bmp");
    FFT_Y_NOISY_IMG = imread("Temp.bmp");
    NOISY_Q = classify(net, FFT_Y_NOISY_IMG);
    
    if NOISY_Q == "1"
        FFT_O = predict(denoiserNet, FFT_Y_R);
    else 
        FFT_O = FFT_Y_NOISY(1:2:end, 1:2:end);
    end
end
       

        

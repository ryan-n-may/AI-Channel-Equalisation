function [H_LS, H_MMSE] = RunLSMMSE(PILOTS_X, PILOTS_Y, H, PilotLocs, L, SNR, pipeInNoise)
        PILOTS_Y_Complex = PILOTS_Y(1:32, :) + PILOTS_Y(33:64, :).*1i;
        PILOTS_X_Complex = PILOTS_X(1:32, :) + PILOTS_X(33:64, :).*1i;
        PILOTS_Y_Complex_Minimised = PILOTS_Y_Complex(PilotLocs).';
        PILOTS_X_Complex_Minimised = PILOTS_X_Complex(PilotLocs).';
        if pipeInNoise
            awgn_channel = comm.AWGNChannel( ...
                "NoiseMethod", "Signal to noise ratio (SNR)", ...
                "SNR", SNR, ...
                "SignalPower", 1 ...
                );
            PILOTS_X_Complex_Minimised = awgn_channel(PILOTS_X_Complex_Minimised);
            PILOTS_Y_Complex_Minimised = awgn_channel(PILOTS_Y_Complex_Minimised);
        end
        MessageLocs = [];
        for k = 1:1:32 
            MessageLocs = [MessageLocs; k];
        end
        [H_LS, ~] = LS(PILOTS_Y_Complex_Minimised, PILOTS_X_Complex_Minimised, PilotLocs, MessageLocs);
        H_Complex = H(1:32, :) + H(33:64, :)*1i;
        H_MMSE = MMSE(H_LS, H_Complex, L, SNR);
end
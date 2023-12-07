function [H_LSTM] = RunLSTM(PILOTS_X, LSTM_INPUT, lstm, LSTMnet, pipeInNoise, SNR)
        if pipeInNoise
            awgn_channel = comm.AWGNChannel( ...
                "NoiseMethod", "Signal to noise ratio (SNR)", ...
                "SNR", SNR, ...
                "SignalPower", 1 ...
                );
            LSTM_INPUT = awgn_channel(LSTM_INPUT);
            LSTM_INPUT(1:32, :) = PILOTS_X(1:32, :);
            LSTM_INPUT(65:96, :) = PILOTS_X(33:64, :);
        end
        [~, LSTMchannelEstimation] = lstm.TestLSTM(LSTMnet, LSTM_INPUT);
        H_LSTM = LSTMchannelEstimation(1:32, :) + LSTMchannelEstimation(33:64, :)*1i;
end
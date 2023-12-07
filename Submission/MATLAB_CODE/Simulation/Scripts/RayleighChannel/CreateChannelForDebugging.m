clear variables;

% Channel simulation configuration
includeAWGN             = false;
includeChannel          = true;
Channels                = 1;
TransmissionsPerChannel = 1;
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

MDS                     = [1 10 10000];
SamplingRate            = [1 1 100];

CHANNEL_SAMPLE          = [];
MMSE                    = [];

for i  = 1:3
    mds = MDS(i);
    sr = SamplingRate(i);
    [~,~,~,~,~,CHANNEL_H,~,~,~,~] = GenerateLSTMData( ...
                    Channels, ...
                    TransmissionsPerChannel, ...
                    M, ...
                    Scaling, ...
                    SNR, ...
                    mds, ...
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
                    sr, ...
                    100);
    
    CHANNEL_H_C = CHANNEL_H(1:32) + CHANNEL_H(33:64);
    CHANNEL_SAMPLE = [CHANNEL_SAMPLE CHANNEL_H_C];
end

figure();
subplot(2,3,1)
plot(10*log10(abs(CHANNEL_SAMPLE(:, 1))));
subplot(2,3,2)
plot(10*log10(abs(CHANNEL_SAMPLE(:, 2))));
subplot(2,3,3)
plot(10*log10(abs(CHANNEL_SAMPLE(:, 3))));

subplot(2,3,4)
plot(10*log10(abs(fft(Samples(:, 1)))));
subplot(2,3,5)
plot(10*log10(abs(fft(Samples(:, 2)))));
subplot(2,3,6)
plot(10*log10(abs(fft(Samples(:, 3)))));



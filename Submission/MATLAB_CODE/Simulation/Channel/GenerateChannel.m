function [rayleigh_channel, awgn_channel] = GenerateChannel(M, SNR, MDS, Scaling, Custom, FS, P) 
    if Custom == false
        P                       = 100;
        FS                      = 1;
        EPSELLON                = 0.00000001;     
        rayc = GenerateRayleighChannel(P, M, MDS, FS, EPSELLON);
    else 
        rayc = GenerateRayleighChannel(P, M, MDS, FS, 0.00000001);
    end
    rayleigh_channel = InterpolateAndSmooth(rayc, Scaling, false).';
    awgn_channel = comm.AWGNChannel( ...
                "NoiseMethod", "Signal to noise ratio (SNR)", ...
                "SNR", SNR, ...
                "SignalPower", 1 ...
                );
end
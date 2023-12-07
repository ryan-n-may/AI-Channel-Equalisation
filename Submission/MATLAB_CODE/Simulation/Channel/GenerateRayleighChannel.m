function [rayc] = GenerateRayleighChannel(P, M, fm, fs, epselonn)
    for p = 1:P+1
        % Bessel autocorrelation method
        vector_corr(p) = besselj(0, 2*pi*fm*(p-1)/(fs*1000));
    end
    autocorrelation_matrix = toeplitz(vector_corr(1:P))+eye(P)*epselonn;
    AR_paramaters = -inv(autocorrelation_matrix) * vector_corr(2:P+1)';
    segma_u = autocorrelation_matrix(1,1) + vector_corr(2:P+1)*AR_paramaters;
    KKK = 2000;
    h = filter(1, [1 AR_paramaters.'], wgn(M+KKK, 1, 10*log10(segma_u), 'complex'));
    chann = h(KKK+1:end, :);
    rayc = chann;
end
% LS estimator takes channel class as input, clones the channel to
% isolate it, and performs equalisation on cloned channel. 
function [H_LS, pilot_h] = LS(rx_pilots, tx_pilots, pilot_locs, message_locs)
    pilot_h = rx_pilots ./ tx_pilots;
    % t1 is location of pilots 
    t1 = pilot_locs;
    % t3 is the whole message length
    t3 = message_locs;
    % interpolate pilot transfer function
    H_LS = interp1(t1, pilot_h, t3, 'linear');
    % remove nans
    H_LS(isinf(H_LS)) = NaN + NaN*1i;
    H_LS = fillmissing(H_LS, 'linear');
    %H_LS(isnan(H_LS)) = 0.0001;
end
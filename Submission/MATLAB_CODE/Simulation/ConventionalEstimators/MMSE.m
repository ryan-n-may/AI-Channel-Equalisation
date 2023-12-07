function W = MMSE(ghatLS, H, L, EbNo)
    %P = 1;
    %W = (H') / ((H' * H) + (1.0/P * eye(L)));    
    %W = W';
    beta = 17/9;
    Rgg = H*H';
    WW = Rgg/(Rgg+(beta/(EbNo))*eye(L));
    ghat = WW*ghatLS(1:L);
    W = ghat;
end
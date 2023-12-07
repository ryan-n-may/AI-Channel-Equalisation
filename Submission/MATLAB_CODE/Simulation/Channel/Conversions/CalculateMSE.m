function [E] = CalculateMSE(A, B)
    E = 0;
    for i = 1:size(A, 1)
        a = A(i);
        b = B(i);
        d1 = abs(real(a) - real(b));
        d2 = abs(imag(a) - imag(b));
        E = E + abs(sqrt(d1^2 + d2^2));
    end
    E = E / size(A, 1);
end
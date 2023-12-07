function [rayc_O] = InterpolateAndSmooth(rayc, scaling, visualise)
    rayc_R = real(rayc);
    rayc_I = imag(rayc);

    x_R = (1:length(rayc_R))';
    y_R = rayc_R;  
    x_Ri = (0:scaling:length(rayc_R));
    y_Ri = interp1(x_R, y_R, x_Ri, 'linear');
    y_Ri = smooth(y_Ri);
    
    x_I = (1:length(rayc_I))';
    y_I = rayc_I;   
    x_Ii = (0:scaling:length(rayc_I));
    y_Ii = interp1(x_I, y_I, x_Ii, 'linear');
    y_Ii = smooth(y_Ii);
    
    rayc_O = y_Ri + 1i.*y_Ii;
    rayc_O = rayc_O(1:length(rayc_I)/scaling, 1:end);
    
    if visualise == true
        figure();
        plot(10*log10(abs(rayc)));
        title("Unaltered rayleigrealh channel");
        figure();
        plot(10*log10(abs(rayc_O)));
        title("Smoothed and interpolated rayleigh channel");
        disp("Length of channel before interpolation: " + length(rayc));
        disp("Length of channel after interpolation: " + length(rayc_O));
    end
end
function PlotLSTMOutput(Plot1, Plot2, Plot3, title)
    figure("Name", title)
    hold on;
    subplot(1,3,1);
    scatter(real(Plot1), imag(Plot1));
    subplot(1,3,2);
    scatter(real(Plot2), imag(Plot2));
    subplot(1,3,3);
    scatter(real(Plot3), imag(Plot3));
end
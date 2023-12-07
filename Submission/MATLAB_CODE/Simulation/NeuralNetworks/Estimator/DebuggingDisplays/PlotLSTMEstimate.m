function PlotLSTMEstimate(H, Prediction, title)
    figure("Name", title);
    hold on;
    plot(H);
    plot(Prediction, '--');
    xlabel("Real | Imaginary Channel Response *Symbol time.");
    ylabel("Absolute Gain");
    legend("H", "Prediction");
end
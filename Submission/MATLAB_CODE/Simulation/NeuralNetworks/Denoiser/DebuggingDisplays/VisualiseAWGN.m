function VisualiseAWGN(X, Y, O, title, l1, l2, l3)
    X_s = X(:, 1);
    Y_s = Y(:, 1);
    O_s = O(:, 1);
    figure("Name", title)
    hold on
    plot(X_s, '--')
    plot(Y_s, '--o')
    plot(O_s, '--*')
    legend(l1, l2, l3)
    hold off
end
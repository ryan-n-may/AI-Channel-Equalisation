function DrawMIMOData(X, Y, O, title)
    figure("Name", title)
    subplot(1,3,1)
    imshow(X)
    subplot(1,3,2)
    imshow(Y)
    subplot(1,3,3)
    imshow(O)
end
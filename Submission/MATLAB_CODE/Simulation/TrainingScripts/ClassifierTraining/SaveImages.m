clear variables;
clear all;

for i = 1:1:4000
    SNR = 50;
    ImageMatrix = GenerateImage(SNR);
    ImageGray = mat2gray(ImageMatrix);
    imwrite(ImageGray, "Simulation/ClassifierImages/0/img_"+SNR+"_"+i+".bmp");
end

for i = 1:1:4000
    SNR = 5;
    ImageMatrix = GenerateImage(SNR);
    ImageGray = mat2gray(ImageMatrix);
    imwrite(ImageGray, "Simulation/ClassifierImages/1/img_"+SNR+"_"+i+".bmp");
end
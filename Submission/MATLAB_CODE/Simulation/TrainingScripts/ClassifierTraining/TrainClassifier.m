clear all;
clear variables;

digitDatasetPath = pwd + "/Simulation/ClassifierImages";
imds = imageDatastore(digitDatasetPath, ...
    'IncludeSubfolders',true,'LabelSource','foldernames');


figure;
perm = randperm(100,10);
for i = 1:10
    subplot(2,5,i);
    imshow(imds.Files{perm(i)});
end

labelCount = countEachLabel(imds);

img = readimage(imds,1);
sz = size(img);

numTrainFiles = 2000;
[imdsTrain,imdsValidation] = splitEachLabel(imds,numTrainFiles,'randomize');

classifier = Classifier;
classifier = classifier.GenerateClassifier(imdsValidation);

net = trainNetwork(imdsTrain,classifier.layers,classifier.options);

YPred = classify(net,imdsValidation);
YValidation = imdsValidation.Labels;

accuracy = sum(YPred == YValidation)/numel(YValidation);

save("ClassifierModel.mat", "net");
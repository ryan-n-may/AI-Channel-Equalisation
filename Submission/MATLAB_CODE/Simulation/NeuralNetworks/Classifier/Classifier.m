classdef Classifier 
    properties 
       layers;
       options;
    end
    methods
        function Obj = GenerateClassifier(Obj, imdsValidation)
            Obj.layers = [
                imageInputLayer([128 128 1])
                
                convolution2dLayer(3,8,'Padding','same')
                batchNormalizationLayer
                reluLayer
                
                maxPooling2dLayer(2,'Stride',2)
                
                convolution2dLayer(3,16,'Padding','same')
                batchNormalizationLayer
                reluLayer
                
                maxPooling2dLayer(2,'Stride',2)
                
                convolution2dLayer(3,32,'Padding','same')
                batchNormalizationLayer
                reluLayer
                
                fullyConnectedLayer(2)
                softmaxLayer
                classificationLayer
            ];
            Obj.options = trainingOptions('sgdm', ...
                'InitialLearnRate',0.01, ...
                'MaxEpochs',4, ...
                'Shuffle','every-epoch', ...
                'ValidationData',imdsValidation, ...
                'ValidationFrequency',5, ...
                'Verbose',false, ...
                'Plots','training-progress');   
        end
        function [Obj, net] = TrainClassifier(Obj, D)
            net = trainNetwork(D, Obj.layers, Obj.options);
        end
        function [Obj, Y] = TestClassifier(Obj, net, X)
            Y = predict(net, X, 'MiniBatchSize', 1);
        end
    end
end

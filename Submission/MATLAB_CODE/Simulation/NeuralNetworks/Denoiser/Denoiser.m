classdef Denoiser 
    properties 
       layers;
       options;
    end
    methods
        function Obj = GenerateDenoiser(Obj, ...
                InputSize, ...
                MaxEpochs, ...
                InitialLearningRate, ...
                LearnRateDropPeriod, ...
                LearnRateDropFactor)

            
            REGRESSION_LAYERS = [
                %% REGRESSION LAYER
                  convolution2dLayer([2,2], 10, "Stride", 1, "Padding", [1 0 1 0], "Name", "Regression Input Layer")
                  reluLayer
                  convolution2dLayer([2,2], 10, "Stride", 1, "Padding", [1 0 1 0])
                  reluLayer
                  batchNormalizationLayer
                  convolution2dLayer([2,2], 10, "Stride", 1, "Padding", [1 0 1 0])
                  reluLayer
                  batchNormalizationLayer
                  convolution2dLayer(1, 1, "Name", "Regression Output")
                  % 256, 256
            ];
            

            OUTPUT_LAYERS = [
                  convolution2dLayer([1,1], 1, "Name", "OUTPUT INPUT")
                  averagePooling2dLayer(4, "Stride", 4)
                  regressionLayer("Name", "Output")
            ];


            INPUT_LAYERS = [ ...
                  imageInputLayer([128 128 1])
                  resize2dLayer("OutputSize", [256, 256], "Name", "Input");
               ];

            Obj.options = trainingOptions(...
                'adam', ...
                'MaxEpochs', MaxEpochs, ...
                'Plots', 'training-progress', ...
                'InitialLearnRate', InitialLearningRate, ...
                'LearnRateSchedule','piecewise',...
                'LearnRateDropPeriod', LearnRateDropPeriod,...
                'LearnRateDropFactor', LearnRateDropFactor,...
                'Verbose', 1);

            Obj.layers = layerGraph(INPUT_LAYERS);
            Obj.layers = addLayers(Obj.layers, REGRESSION_LAYERS);
            Obj.layers = addLayers(Obj.layers, OUTPUT_LAYERS);

            Obj.layers = connectLayers(Obj.layers, "Input", "Regression Input Layer");
            
            Obj.layers = connectLayers(Obj.layers, "Regression Output", "OUTPUT INPUT");

            figure;
            plot(Obj.layers);
        end
        function [Obj, net] = TrainDenoiser(Obj, X, Y)
            net = trainNetwork(X, Y, Obj.layers, Obj.options);
        end
        function [Obj, Y] = TestDenoiser(Obj, net, X)
            Y = predict(net, X, 'MiniBatchSize', 1);
        end
    end
end

WITH_DENOISING_CreateTrainingData;
%fileName = getLatestFile("CheckpointPath/");
fileName = "1PM.mat";
load("CheckpointPath/" + fileName, "net")  
load("LSTMTRAININGDATA.mat", "LSTM_INPUT", "CHANNEL_H");
load("TrainedEstimator.mat", "lstm");

lstm = lstm.Mute();
[lstm, LSTMnet] = lstm.TrainLSTM(LSTM_INPUT, CHANNEL_H, true, net);
save("TrainedEstimator.mat", "LSTMnet", "lstm");

function [file] = getLatestFile(filedir)
    directory = dir(filedir);
    directory = directory(find(~cellfun(@isfolder,{directory(:).name})));
    [~, I] = max([directory(:).datenum]);
    if ~isempty(I)
        file = directory(I).name;
        disp(file);
    end
end

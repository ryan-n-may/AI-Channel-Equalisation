# AI-Channel-Equalisation
Using AI to equalise distortion and white noise in a multipath communications channel.

## The Channel Model:
The channel model is a SISO system with QAM modulation in an OFDM system of 32 subcarriers. 

![channel](https://github.com/ryan-n-may/AI-Channel-Equalisation/blob/main/Submission/Design%20Diagrams/Channel.png)

## The Estimator: 
The estimator model uses a 2 layered bi-lstm model connected via a fully-connected layer. This model estimates the time-domain time-varied channel response given the recieved signal data and the known transmission data.

![estimator](https://github.com/ryan-n-may/AI-Channel-Equalisation/blob/main/Submission/Design%20Diagrams/ESTIMATOR_MODEL.png)

### The LSTM cell:
The LSTM cell is theoretically modelled as follows:

![lstm](https://github.com/ryan-n-may/AI-Channel-Equalisation/blob/main/Submission/Design%20Diagrams/LSTM_CELL.png)

## The Denoiser:
The purpose of the denoiser is to use a series of CNN layers, average pooling layers, and ReLU layers to remove of AWGN from the recieved signal.  The recieved signal is over-sampled.  The noise classification layer identifies noise in the received signal, and the denoiser layer removes noise from the recieved signal if noise is detected.

![denoiser](https://github.com/ryan-n-may/AI-Channel-Equalisation/blob/main/Submission/Design%20Diagrams/DENOISER_MODEL.png)

## The complete model:
The complete model combines estimation with noise removal. 

![completemodel](https://github.com/ryan-n-may/AI-Channel-Equalisation/blob/main/Submission/Design%20Diagrams/COMPLETE_MODEL.png)

# Performance: 
## Rayleigh channel simulation

![channel simulation](https://github.com/ryan-n-may/AI-Channel-Equalisation/blob/main/Submission/Report%20Figures/RAYLEIGH_SIMULATION.jpg)

## Denoiser performance 
Performance against AWGN & AWGN influenced channel estimation.

![denoiser performance](https://github.com/ryan-n-may/AI-Channel-Equalisation/blob/main/Submission/Report%20Figures/DENOISER_PERFORMANCE.jpg)

The following is a visualisation of denoiser performance: 

![denoiser visualisation](https://github.com/ryan-n-may/AI-Channel-Equalisation/blob/main/Submission/Report%20Figures/DRAW_SYMBOLS.jpg)

## Estimation performance against MMSE and LS

Performance in regard to MSE:

![estimation performance](https://github.com/ryan-n-may/AI-Channel-Equalisation/blob/main/Submission/Report%20Figures/ESTIMATE_MSE_PLOT.jpg)

Performance in regard to SER:

![estimation performance](https://github.com/ryan-n-may/AI-Channel-Equalisation/blob/main/Submission/Report%20Figures/ESTIMATE_SER_PLOT.jpg)

Estimation accuracy at 5 dB:

![50dB Accuracy](https://github.com/ryan-n-may/AI-Channel-Equalisation/blob/main/Submission/Report%20Figures/MSE_50dB.jpg)

Estimation accuracy at 50 dB:

![5 dB Accuracy](https://github.com/ryan-n-may/AI-Channel-Equalisation/blob/main/Submission/Report%20Figures/MSE_5dB.jpg)



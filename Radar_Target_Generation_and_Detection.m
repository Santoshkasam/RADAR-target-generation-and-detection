clear all
close all
clc;

%% Radar Specifications 
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Frequency of operation = 77GHz
% Max Range = 200m
% Range Resolution = 1 m
% Max Velocity = 100 m/s
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%speed of light = 3e8
%% User Defined Range and Velocity of target
% *%TODO* :
% define the target's initial position and velocity. Note : Velocity
% remains contant
R = 120;    % Initial distance of the target
V = -20;    % Velocity of the target


%% FMCW Waveform Generation

% *%TODO* :
%Design the FMCW waveform by giving the specs of each of its parameters.
% Calculate the Bandwidth (B), Chirp Time (Tchirp) and Slope (slope) of the FMCW
% chirp using the requirements above.

% RADAR system requirements
range_resolution = 1; % Units: meters (m)
C = 299792458;         % Speed of light, Units: m/s
r_max = 200;          % Maximum range, Units: m

% FMCW parameters
B = C/(2*range_resolution); 
Tchirp = ( 5.5 * 2 * r_max )/ C; 
slope = B / Tchirp

%Operating carrier frequency of Radar 
fc= 77e9;             %carrier freq

                                                          
%The number of chirps in one sequence. Its ideal to have 2^ value for the ease of running the FFT
%for Doppler Estimation. 
Nd=128;                   % #of doppler cells OR #of sent periods % number of chirps

%The number of samples on each chirp. 
Nr=1024;                  %for length of time OR # of range cells

% Timestamp for running the displacement scenario for every sample on each
% chirp
t=linspace(0,Nd*Tchirp,Nr*Nd); %total time for samples


%Creating the vectors for Tx, Rx and Mix based on the total samples input.
Tx=zeros(1,length(t)); %transmitted signal
Rx=zeros(1,length(t)); %received signal
Mix = zeros(1,length(t)); %beat signal

%Similar vectors for range_covered and time delay.
r_t=zeros(1,length(t));
td=zeros(1,length(t));


%% Signal generation and Moving Target simulation
% Running the radar scenario over the time.       
    
    
    % *%TODO* :
    %For each time stamp update the Range of the Target for constant velocity. 
    r_t = R + (V * t);
    % *%TODO* :
    %For each time sample we need update the transmitted and
    %received signal. 
    td = 2 * r_t/C;
    Tx = cos(2*pi*(fc*t + slope * (t.^2)/2));
    Rx = cos(2*pi*(fc*(t-td) + slope * ((t-td).^2)/2));
    
    % *%TODO* :
    %Now by mixing the Transmit and Receive generate the beat signal
    %This is done by element wise matrix multiplication of Transmit and
    %Receiver Signal
    Mix = Tx.* Rx;

%% RANGE MEASUREMENT


 % *%TODO* :
%reshape the vector into Nr*Nd array. Nr and Nd here would also define the size of
%Range and Doppler FFT respectively.
Mix = reshape(Mix, [Nr, Nd]); 
 % *%TODO* :
%run the FFT on the beat signal along the range bins dimension (Nr) and
%normalize.
Mix_fft = fft(Mix)/Nr; % Normalizing by the length of column
 % *%TODO* :
% Take the absolute value of FFT output
Mix_fft = abs(Mix_fft);
 % *%TODO* :
% Output of FFT is double sided signal, but we are interested in only one side of the spectrum.
% Hence we throw out half of the samples.
Mix_fft_1 = Mix_fft(1:length(Mix_fft)/2+1, 1);

%plotting the range
figure ('Name','Range from First FFT')
subplot(2,1,1)

 % *%TODO* :
 % plot FFT output 

plot(Mix_fft_1)
axis ([0 200 0 1]);


%% RANGE DOPPLER RESPONSE
% The 2D FFT implementation is already provided here. This will run a 2DFFT
% on the mixed signal (beat signal) output and generate a range doppler
% map.You will implement CFAR on the generated RDM


% Range Doppler Map Generation.

% The output of the 2D FFT is an image that has reponse in the range and
% doppler FFT bins. So, it is important to convert the axis from bin sizes
% to range and doppler based on their Max values.

Mix=reshape(Mix,[Nr,Nd]);

% 2D FFT using the FFT size for both dimensions.
sig_fft2 = fft2(Mix,Nr,Nd);

% Taking just one side of signal from Range dimension.
sig_fft2 = sig_fft2(1:Nr/2,1:Nd);
sig_fft2 = fftshift (sig_fft2);
RDM = abs(sig_fft2);
RDM = 10*log10(RDM) ;

%use the surf function to plot the output of 2DFFT and to show axis in both
%dimensions
doppler_axis = linspace(-100,100,Nd);
range_axis = linspace(-200,200,Nr/2)*((Nr/2)/400);
figure,surf(doppler_axis,range_axis,RDM);

%% CFAR implementation

%Slide Window through the complete Range Doppler Map

% *%TODO* :
%Select the number of Training Cells in both the dimensions.
Tr = 6;
Td = 10;
% *%TODO* :
%Select the number of Guard Cells in both dimensions around the Cell under 
%test (CUT) for accurate estimation
Gr = 3;
Gd = 3;

% *%TODO* :
% offset the threshold by SNR value in dB
offset = 6;

% *%TODO* :
%Create a vector to store noise_level for each iteration on training cells
noise_level = zeros(1,1);


% *%TODO* :
%design a loop such that it slides the CUT across range doppler map by
%giving margins at the edges for Training and Guard Cells.
%For every iteration sum the signal level within all the training
%cells. To sum convert the value from logarithmic to linear using db2pow
%function. Average the summed values for all of the training
%cells used. After averaging convert it back to logarithimic using pow2db.
%Further add the offset to it to determine the threshold. Next, compare the
%signal under CUT with this threshold. If the CUT level > threshold assign
%it a value of 1, else equate it to 0.

% Update Nr to half their values, since, only first half of the signal
% is considered

Nr = Nr/2;

% Initialize vector to hold threshold values 
threshold_cfar = zeros(Nr,Nd);
signal_cfar = zeros(Nr,Nd);

num_training_cells = (2*Tr+2*Gr+1)*(2*Td+2*Gd+1) - (2*Gr+1)*(2*Gd+1);

for r = (Tr+Gr+1) : (Nr-Tr-Gr) 

    for d = (Td+Gd+1) : (Nd-Td-Gd)
   % Use RDM[x,y] as the matrix from the output of 2D FFT for implementing
   % CFAR
    training_cells_sum = sum(db2pow(RDM(r-Gr-Tr:r+Gr+Tr, d-Gd-Td:d+Gd+Td)), 'all')...
                            - sum(db2pow(RDM(r-Gr:r+Gr,d-Gd:d+Gd)), 'all');
    noise_level = pow2db(training_cells_sum/num_training_cells);
    threshold_cfar(r,d) = noise_level + offset;
    
    if RDM(r,d) > threshold_cfar(r,d)
        signal = 1;
    else
        signal = 0;
    end
    
    % add signal value to the signal_cfar vector
    signal_cfar(r,d) = signal;  
    end
end

% *%TODO* :
% The process above will generate a thresholded block, which is smaller 
%than the Range Doppler Map as the CUT cannot be located at the edges of
%matrix. Hence,few cells will not be thresholded. To keep the map size same
% set those values to 0. 
 
    %Solution: The threshold block is intialized with zeros. Only those elements whose index 
    % is equal to that of the valid cut cells are updated with threshold
    % values. Hence, the elements whose corresponding thresold values are not calculated,
    % have zero as threshold value already. (which they are initiated with)





% *%TODO* :
%display the CFAR output using the Surf function like we did for Range
%Doppler Response output.
figure,surf(doppler_axis,range_axis,signal_cfar);
colorbar;


 
 
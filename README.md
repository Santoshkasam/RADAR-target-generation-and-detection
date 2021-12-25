# RADAR-target-generation-and-detection
In this project, an FMCW RADAR is configured. The transmit and recieved signals are processed uisng FFT and CFAR to determine the range and velocity of the target"

## Project overview
![radar overview](https://user-images.githubusercontent.com/48198017/147384345-3214cb23-d2a4-4d0f-8069-7702290f0dce.PNG)

The above picture outlines the project pipeline.

## FMCW RADAR system configuration
![image](https://user-images.githubusercontent.com/48198017/147384420-d3192d74-2397-49de-8b6f-86602ee84b20.png)

The initial range and velocity of the target are set to be: 
* R = 120 meters
* V = -20 meters/sec

The bandwidth, chirp time and slope of the chirp signal are calculated according to the following formulas
![image](https://user-images.githubusercontent.com/48198017/147384457-723a9aa0-503c-449f-8044-28e9135bb5da.png)
![image](https://user-images.githubusercontent.com/48198017/147384461-3810b13f-9b8c-461a-a30a-07ae3bb32c20.png)
![image](https://user-images.githubusercontent.com/48198017/147384466-1df91916-87f6-4fa7-b734-6a26885b5b88.png)

where Rmax is the maximum range of the RADAR and c is the speed of light.

## Modeling signal propogation for moving target scenario

The transmission and recieved signals are charecterised by the following equations.

![image](https://user-images.githubusercontent.com/48198017/147384507-82b52a36-bce1-4c37-bee6-ff042bfbea8b.png)

The beat signal is computed as product of transmission and recieved signal. The result is charecterised by the following equation: 
![image](https://user-images.githubusercontent.com/48198017/147384524-02758f9b-a970-4db9-acc4-8ba42eef068d.png)

## FFT: Range estimation
A 1D FFT is implimented on the best signal to estimate the range of the target. 

FFT implimentation: 
* The beat signal is reshaped in to a 2D vector of size (Nr, Nd). where, Nr is the sampling frequency per chirp and Nd is the total number of a chirps in a chirp sequence. 
* FFT is ran on the beat signal along the range bins dimension (Nr)
* The output of the FFT is normalized
* Since the second halt of the output is a mirror image of the first half, only the first half of the image is retained. 
* The output is plotted 
* The peak rightly estimates the range of the target as follows: 
![range estimation](https://user-images.githubusercontent.com/48198017/147384719-b3f7fbd1-6ced-4abc-86f4-9040fd3cfd05.jpg)

warning off
format compact
clc
clear all
close all

colorOrder = get(gca,'colorOrder');
%% SETUP_SRV02_EXP14_2D_GANTRY
    %
    % Sets the necessary parameters to run the SRV02 Experiment #13: Position
    % Control of 2-DOF Robot laboratory using the "s_srv02_2d_robot" and
    % "q_srv02_2d_robot" Simulink diagrams.
    % 
    % Copyright (C) 2008 Quanser Consulting Inc.
    %
    clear all;
    qc_get_step_size =1/1000; %0.001;
    deltaT = qc_get_step_size;
    Ts = qc_get_step_size;
    nPoints = (50 * 3000) -1;
%
%% Initialization Settings(DONT CHANGE ANYTHING !!)
    EXT_GEAR_CONFIG = 'HIGH';
    ENCODER_TYPE = 'E';
    TACH_OPTION = 'YES';
    LOAD_TYPE = 'NONE';
    K_AMP = 1;
    AMP_TYPE = 'VoltPAQ';
    VMAX_DAC = 10;
    ROTPEN_OPTION = '2DGANTRY-E';
    PEND_TYPE = 'MEDIUM_12IN';
    THETA_MAX = 35 * pi/180;
    ALPHA_MAX = 15.0 * pi/180;
    CONTROL_TYPE = 'AUTO';   
    X0 = pi/180*[0, 0, 0, 0];
    [ Rm, kt, km, Kg, eta_g, Beq, Jm, Jeq_noload, eta_m, K_POT, K_TACH, K_ENC, VMAX_AMP, IMAX_AMP ] = config_srv02( EXT_GEAR_CONFIG, ENCODER_TYPE, TACH_OPTION, AMP_TYPE, LOAD_TYPE );
    [ g, mp, Lp, lp, Jp_cm, Bp, RtpnOp, RtpnOff, K_POT_PEN ] = config_sp( PEND_TYPE, ROTPEN_OPTION );
    [ Lb, Jarm, K_POT_2DP, K_ENC_2DP ] = config_2d_gantry( Jeq_noload );
    K_ENC_2DIP = [-1,1].*K_ENC_2DP;
    wcf_1 = 2 * pi * 5;
    zetaf_1 = 0.9;
    wcf_2 = wcf_1;
    zetaf_2 = zetaf_1;

    %
%%%
%%%%
%%%%%
%%%%%% DO NOT CHANGE ANYTHING ABOVE THIS AREA !! Place your code below.
%%%%
%%%
%

%% Exercise 1

% Define the uncertain parameters Mp, Lp, Jp, and Co 
% using the command "ureal"
Mp = ureal('Mp', 0.1270, 'Percentage', 50);
Lp = ureal('Lp', 0.3111, 'Percentage', 50);
Jp = ureal('Jp', 0.0012, 'Percentage', 50);
Co = ureal('Co', 0.1285, 'Percentage', 10);

Lr = 0.1270; 
theta =  0;
alpha =  0;
dtheta =  0;
dalpha =  0;
Jr = 0.0083;
Dr = 0.0690;
g = 9.810;

Adelta = [0         0         1         0;
      0         0         0         1;
      0   ((Lr*Lp^3*Mp^2*dtheta^2)/2 + Lr*g*Lp^2*Mp^2)/(Jr*Mp*Lp^2 + Jp*(4*Mp*Lr^2 + 4*Jr)) - ((dalpha*dtheta*Lp^4*Mp^2)/2 + 2*Jp*dalpha*dtheta*Lp^2*Mp)/(Jr*Mp*Lp^2 + Jp*(4*Mp*Lr^2 + 4*Jr)),- ((Jp*(4*Mp*alpha*dalpha*Lp^2 + 8*Dr))/2 + (Lp^4*Mp^2*alpha*dalpha)/2)/(Jr*Mp*Lp^2 + Jp*(4*Mp*Lr^2 + 4*Jr)) - (- Lr*alpha*dtheta*Lp^3*Mp^2 + Dr*Lp^2*Mp)/(Jr*Mp*Lp^2 + Jp*(4*Mp*Lr^2 + 4*Jr)),-((alpha*dtheta*Lp^4*Mp^2)/2 + 2*Jp*alpha*dtheta*Lp^2*Mp)/(Jr*Mp*Lp^2 + Jp*(4*Mp*Lr^2 + 4*Jr));
      0   (dtheta^2*(Lp^2*Lr^2*Mp^2 + Jr*Lp^2*Mp) + 2*Lp*Lr^2*Mp^2*g + 2*Jr*Lp*Mp*g)/(Jr*Mp*Lp^2 + Jp*(4*Mp*Lr^2 + 4*Jr)) - (Lp^3*Lr*Mp^2*dalpha*dtheta)/(Jr*Mp*Lp^2 + Jp*(4*Mp*Lr^2 + 4*Jr)), (2*alpha*dtheta*(Lp^2*Lr^2*Mp^2 + Jr*Lp^2*Mp))/(Jr*Mp*Lp^2 + Jp*(4*Mp*Lr^2 + 4*Jr)) - (Lr*alpha*dalpha*Lp^3*Mp^2 + 2*Dr*Lr*Lp*Mp)/(Jr*Mp*Lp^2 + Jp*(4*Mp*Lr^2 + 4*Jr)),-(Lp^3*Lr*Mp^2*alpha*dtheta)/(Jr*Mp*Lp^2 + Jp*(4*Mp*Lr^2 + 4*Jr)) ];
  
Bdelta = [0; 
      0;
      (4*Co*Jp)/(Jr*Mp*Lp^2 + Jp*(4*Mp*Lr^2 + 4*Jr)) + (Co*Lp^2*Mp)/(Jr*Mp*Lp^2 + Jp*(4*Mp*Lr^2 + 4*Jr));
      (2*Co*Lp*Lr*Mp)/(Jr*Mp*Lp^2 + Jp*(4*Mp*Lr^2 + 4*Jr))];

Cdelta = [1  0  0  0;
          0  1  0  0];
 
Ddelta = [0; 0];

eigA_nominal = eig(Adelta.NominalValue);

%% Exercise 3

% System matrix definition

A = [Adelta, zeros(size(Adelta));
    zeros(size(Adelta)), Adelta];

B = [Bdelta, zeros(size(Bdelta));
    zeros(size(Bdelta)), Bdelta];

C = [Cdelta, zeros(size(Cdelta));
    zeros(size(Cdelta)), Cdelta];

D = [Ddelta, zeros(size(Ddelta));
    zeros(size(Ddelta)), Ddelta];

G = ss(A,B,C,D);
Pnom = G.NominalValue;

% Uncertainty block definition (iM = input-Multiplicative)
wiM = udyn('wiM', [1,1]);
WiM = 10*[wiM, 0;
           0, wiM];

delta = udyn('delta', [2,2]);

%% Exercise 4
% Design and compute the controller, and call it Chinf
% Chinf = hinfsyn(...)

s = tf('s');

Wu = eye(2,2) * tf(0.05);

Wr = eye(4,4) * 1/(1+s);

wp.opt1 = 1/(2*0.0025);
wp.opt2 = 1/(2*0.0251);
wp.opt3 = 1/(2*0.0010);

Wp1 = wp.opt1 * ((s/7 + 1)/(s/8e-3 + 1) + 1) * eye(4,4);
Wp2 = wp.opt2 * ((s/7 + 1)/(s/8e-3 + 1) + 1) * eye(4,4);
Wp3 = wp.opt3 * ((s/7 + 1)/(s/8e-3 + 1) + 1) * eye(4,4);

Wn = eye(4,1) * tf(deg2rad(0.3));

% Input and Output name definition
inputs = {'u_delta', 'r', 'n', 'u'};
outputs = {'y_delta', 'z_u', 'z_p', 'y'};

G.InputName = 'u_tilde';
G.OutputName = 'y';

Wu.InputName = 'u';
Wu.OutputName = 'z_u';

Wr.InputName = 'r';
Wr.OutputName = 'z_r';

Wp1.InputName = 'e_ref';
Wp1.OutputName = 'z_p';

Wp2.InputName = 'e_ref';
Wp2.OutputName = 'z_p';

Wp3.InputName = 'e_ref';
Wp3.OutputName = 'z_p';

Wn.InputName = 'n';
Wn.OutputName = 'z_n';

WiM.InputName = 'u';
WiM.OutputName = 'y_delta';

delta.InputName = 'y_delta';
delta.OutputName = 'u_delta';

sum1 = sumblk('u_tilde = u_delta + u', 2);
sum2 = sumblk('e_ref = y + r', 4);
sum3 = sumblk('y_tilde = y + z_n');

P1 = connect(G, Wu, Wr, Wp1, Wn, WiM, sum1, sum2, sum3, inputs, outputs);
P2 = connect(G, Wu, Wr, Wp2, Wn, WiM, sum1, sum2, sum3, inputs, outputs);
P3 = connect(G, Wu, Wr, Wp3, Wn, WiM, sum1, sum2, sum3, inputs, outputs);

% Controller design
[K1, N1, gamma1] = hinfsyn(P1, 4, 2);
[K2, N2, gamma2] = hinfsyn(P2, 4, 2);
[K3, N3, gamma3] = hinfsyn(P3, 4, 2);

% What is the γ value found to be minimal? gamma2
% Is the robust performance condition fulfilled? no
% Check robust stability condition, is that kept? no

Chinf = K1;

%% NB: To run the simulation, the nominal model has to be in the workspace with the variable name "Pnom"
%
%%%
%%%%
%%%%%
%%%%%% Closed loop simulation environment
%%%%
%%%
%
% NB: To run the simulation, the nominal model has to be loaded to the
% workspace with the variable name "Pnom".

[ah,bh,ch,dh] = ssdata(Chinf);


figure(1)
clf;
simTime = 10;
xinit=(pi/180)*[3 3 0 0 3 3 0 0];

try
sim('Simhinf.slx')
subplot(2,1,1)
grid on
hold on
    plot(simStates.Time,simStates.Data(:,1),'linewidth',2)
    plot(simStates.Time,simStates.Data(:,3),'linewidth',2)    
    plot(simStates.Time,simStates.Data(:,2),'--','linewidth',2)
    plot(simStates.Time,simStates.Data(:,4),'--','linewidth',2)
    legend('thetaX','alphaX','thetaY','alphaY','NthetaX','NalphaX','NthetaY','NalphaY')
    ylabel('Angle [DEG]')

subplot(2,1,2)
grid on
hold on
    plot(simVoltage.Time, simVoltage.Data(:,1),'linewidth',2)
    plot(simVoltage.Time, simVoltage.Data(:,2),'--','linewidth' ,2)
    legend('Voltage X','Voltage Y')
    ylabel('Voltage [V]')
    axis([0 simTime -11 11])
catch e
    disp('Simulation failed')
end
OCL=1;

%%
%load('labb_LQR_controller.mat')
%open('ExperimentRobustControl')

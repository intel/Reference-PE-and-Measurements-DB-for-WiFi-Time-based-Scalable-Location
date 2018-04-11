% KFclass definition & methods

% For questions/comments contact: 
% leor.banin@intel.com, 
% ofer.bar-shalom@intel.com, 
% nir.dvorecki@intel.com,
% yuval.amizur@intel.com

% Copyright (C) 2018 Intel Corporation
% SPDX-License-Identifier: BSD-3-Clause

classdef KFclass < handle
    
    properties
        P                   % KF Covariance Matrix
        X                   % KF State vector
        sysNoisePos         % System noise variance vector for position states
        sysNoiseClk         % System noise variance vector for clock states
        t                   % KF time (client/cSTA time)
        stateN              % Total number of states
        clkN                % number of clock states pairs
        Xoffset_Index       % index vector of all clock offset in the state vector X
        Xdrift_index        % index vector of all clock drift in the state vector X
        Xoffset             % a vector of all the clock offset states (copied from X)
        Xdrift              % a vector of all the clock drift states (copied from X)
        
        NO_CLK_TRACKING     % Flag to effectively disable clock tracking
    end
    
    methods
        
        function obj = KFclass(cfg)
            obj.clkN = cfg.maxSTAid; % should be init to the maximal bSTA index

            obj.stateN = 3 + 2*obj.clkN;
            
            obj.Xoffset_Index = 3 + 1:2:obj.stateN;
            obj.Xdrift_index = 3 + 2:2:obj.stateN;
            
            obj.sysNoiseClk = [1e-15 1e-7].^2; % [sec^2 dif^2]
            obj.sysNoisePos = [1 1 0.001] .^2; % [m^2]      
            
            obj.NO_CLK_TRACKING = cfg.disableClkTracking;
           
            % ---------------------------------------
            % outlier filtering may be added here...
            % ---------------------------------------            
        end
        
        % KF Prediction
        function predictKF(obj,F,Q)
            obj.X  = F * obj.X;          % calculate X n/n-1
            obj.P  = F * obj.P * F' + Q; % calculate P n/n-1
        end
        
        % KF Update
        function updateKF(obj,y,H,R,hi)
            K = obj.P * H' / (H * obj.P * H' + R); % calculate K - filter gain   
            obj.X = obj.X + K*(y - hi);            % calculate X - Update states
            obj.P    = obj.P   - K * H * obj.P;    % calculate P - Update states covariance
        end
        
        function SetOffsetByIndex(obj,initOffset,index)
            z        = obj.Xoffset_Index(index);
            obj.X(z) = initOffset;
            obj.Xoffset = obj.X(obj.Xoffset_Index);
        end
        
        function obj = initKF(obj,initTs,initPos)
            obj.t = initTs;         % Init. EKF time

            Xinit = zeros(obj.stateN,1);
            Xinit(1:3) = initPos;   % Initialize EKF client position states
            
            ClockOffsetSigma = 10e-3;    % Init. offset sigma 
            ClockDriftSigma  = 100e-6;   % Init. clock drift sigma
            latSigma         = 3;        % Init. lateral sigma
            Zsigma           = 0.5;      % Init. height sigma
            
            PinitPerClk = diag([ClockOffsetSigma,ClockDriftSigma].^2);
            PinitPerPos = diag([latSigma,latSigma,Zsigma].^2);
            
            Pinit = obj.BuildBigMat(PinitPerPos,PinitPerClk);
            
            % init KF:
            obj.X  = Xinit; % Init state vector
            obj.P  = Pinit; % Init state covariance matrix
            
            % ---- Update easy-access vectors ------
            obj.Xoffset = obj.X(obj.Xoffset_Index);
            obj.Xdrift = obj.X(obj.Xdrift_index);
            % --------------------------------------
        end
        
        function out = BuildBigMat(obj,posMat,clkMat)
            out = zeros(obj.stateN);
            out(1:3,1:3) = posMat;
            for k = 0:obj.clkN-1
                s = 4 + 2*k;
                out(s:s+1,s:s+1) = clkMat;
            end
        end
        
        function F = CreateF(obj,dt)
            FperPos = eye(3);
            FperClk  = [1 dt ; 0 1 ];
            F = obj.BuildBigMat(FperPos,FperClk);
        end
        
        function Q = CreateQ(obj, dt)
            QperPos = diag( dt * obj.sysNoisePos );

            if obj.NO_CLK_TRACKING && dt > 10e-3
                % setting high system noise, making the offset and drift
                % states to have a very little on the updated outcome.
                obj.X(obj.Xoffset_Index) =  obj.X(obj.Xoffset_Index) + 1e-6*randn(obj.clkN,1);
                
                QperClk = diag( [1e-6 1e-6].^2 );
                
            else
                QperClk = diag( dt * obj.sysNoiseClk );
            end
            
            Q = obj.BuildBigMat(QperPos,QperClk);
            
        end
        
        function H = CreateH(obj,type,staTx,staRx)
            H = zeros(1,obj.stateN);
            if strcmp(type,'RX_BY_CSTA')
                H(1:3) = (obj.X(1:3)' - staTx.pos') / norm (obj.X(1:3)' - staTx.pos')/3e8;
                H(obj.Xoffset_Index(staTx.index)) = -1;% ToD
            elseif strcmp(type,'BSTA_TO_BSTA')
                H(obj.Xoffset_Index(staRx.index)) =  1; % ToA
                H(obj.Xoffset_Index(staTx.index)) = -1; % ToD
            end
        end
        
        function hi = CreateHx(obj,type,staTx,staRx)
            if strcmp(type,'RX_BY_CSTA')
                Xpos = obj.X(1:3)';
                hi = norm(Xpos -  staTx.pos')/3e8 -  obj.Xoffset(staTx.index);
            elseif strcmp(type,'BSTA_TO_BSTA')
                tof = norm(staTx.pos - staRx.pos)/3e8;
                hi = obj.Xoffset(staRx.index) - obj.Xoffset(staTx.index) + tof; 
            end
        end
        
       function R = CreateR(~,measType)
            if strcmp(measType,'BSTA_TO_BSTA') % bSTA to bSTA
                R = (3e-9)^2; 
            elseif strcmp(measType,'RX_BY_CSTA') % Rx by client
                R = (6e-9)^2; % higher meas. var. since client is mobile
            end
       end
        
        % Convert bSTA time to KF time (Client time).
        function KFtime = GetKFtime(obj,localTime,index)
            KFtime = localTime - obj.Xoffset(index);
        end
        
        % ----------------------------------------------
        function posEst = Run(obj,y,t,staTx,staRx,measType)   
            dt = max(0,t - obj.t);  % time difference from last update             
            obj.t = obj.t + dt;     % update current KF time
          
            F = obj.CreateF(dt);    % generate the states transition matrix
            Q = obj.CreateQ(dt);    % generate the system noise covariance matrix
            obj.predictKF(F,Q);     % Do KF prediction
            
            % ---- Update easy-access vectors ------
            obj.Xoffset = obj.X(obj.Xoffset_Index);
            obj.Xdrift = obj.X(obj.Xdrift_index);
            % --------------------------------------
            
            H  = obj.CreateH(measType,staTx,staRx);
            hi = obj.CreateHx(measType,staTx,staRx);
            R  = obj.CreateR(measType);
            % ------------------------------------------------
            % Measurement outlier filtering may be added here...
            % ------------------------------------------------            
            obj.updateKF(y,H,R,hi); % Do KF update

            % ---- Update easy-access vectors ------
            obj.Xoffset = obj.X(obj.Xoffset_Index); % Clock offsets vector
            obj.Xdrift = obj.X(obj.Xdrift_index);   % Clock drift vector
            % --------------------------------------

            posEst = obj.X(1:3); % updated current position estimation vector

        end % function Run
    end
end





% RunPE - main positioning engine loop.
% usage:[posEst,pValid] = RunPE(cfg, measTable)

% For questions/comments contact: 
% leor.banin@intel.com, 
% ofer.bar-shalom@intel.com, 
% nir.dvorecki@intel.com,
% yuval.amizur@intel.com

% Copyright (C) 2018 Intel Corporation
% SPDX-License-Identifier: BSD-3-Clause

function [posEst,pValid] = RunPE(cfg, measTable)

measN = size(measTable,1);
KF = KFclass(cfg); % Kalman Filter Constructor

INIT_KF = 1;  % KF Initialization flag
lastPacketId = nan;
lastTxid = nan;
isSTAinit = false(cfg.maxSTAid,1); % vector to indicate if offset was init per bSTA

posEst = nan(3,measN);
pValid = false(measN,1);

for k = 1:measN
    [packetId,type,txId,rxId,txTime,rxTime,staTx,staRx] = ParseMeasLine(measTable(k,:));

    if INIT_KF
        % KF initiliazation is done on the first packet received by the client.
        if type==0 % Rx by cSTA
            KF.initKF(rxTime,cfg.initPos);
            INIT_KF = 0;
            initOffset = txTime - rxTime;
            KF.SetOffsetByIndex(initOffset,txId);
            isSTAinit(txId) = true;
        end     
        continue;
    else
        
        % After INIT_KF, for each new bSTA (one that was never seen before)
        % initialize its relative offset within the KF
        if isClient(rxId) % rx by cSTA
            if ~isSTAinit(txId)
                % bSTA to cSTA & bSTA not init --> init bSTA
                initOffset = rxTime - txTime + KF.Xoffset(txId);
                KF.SetOffsetByIndex(initOffset,txId);
                isSTAinit(txId) = true;
                continue;
            end
        else % isBsta(rxId)
            if ~isSTAinit(txId) && isSTAinit(rxId)
                % bSTA to bSTA & tx bSTA not init --> init tx bSTA
                initOffset = txTime - rxTime + KF.Xoffset(rxId);
                KF.SetOffsetByIndex(initOffset,txId);
                isSTAinit(txId) = true;
                continue;
            elseif isSTAinit(txId) && ~isSTAinit(rxId)
                % bSTA to bSTA & rx bSTA not init --> init rx bSTA
                initOffset = rxTime - txTime + KF.Xoffset(txId);
                KF.SetOffsetByIndex(initOffset,rxId);
                isSTAinit(rxId) = true;
                continue;
            elseif  ~isSTAinit(txId) && ~isSTAinit(rxId)
                % bSTA to bSTA & both are not init --> skip this measurement
                continue;
            end
        end
        
        % Every packet is defined uniquely by its packetId and txId
        % If the new measurement differ from the last packet
        % the time of new packet is obtained using KF.GetKFtime
        if packetId ~= lastPacketId || txId ~= lastTxid % new packet detected
            kfTime = KF.GetKFtime(txTime,txId);  % convert txTime to cSTA clock
            lastPacketId = packetId;
            lastTxid = txId;
        end
        
        % prepare the measurement for KF
        meas = rxTime - txTime;

        % Run KF
        if type % bSTA to bSTA
            posEst(:,k) = KF.Run(meas,kfTime,staTx,staRx,'BSTA_TO_BSTA'); 
        else    % bSTA to cSTA
            posEst(:,k) = KF.Run(meas,kfTime,staTx,[],'RX_BY_CSTA'); 
            pValid(k) = true;
        end
                    
    end % INIT_KF
    % ---------------------------------------
    % outlier filtering may be added here...
    % ---------------------------------------
end % for k = 1:measN


end

% ------------------------------------------------------------------------
function [pId,type,txId,rxId,txTime,rxTime,staTx,staRx] = ParseMeasLine(measLine)

% line Format: packetId,type,txId,rxId,txPos,rxPos,txTime,rxTime
pId = measLine(1);
type = measLine(2);
txId = measLine(3);
rxId = measLine(4);
txTime = measLine(11);
rxTime = measLine(12);
%----------------------------------------------------------
staTx.index = txId;           % Transmitting bSTA ID
staTx.pos = measLine(5:7)';   % Transmitting bSTA position
staRx.index = rxId;           % Receiver bSTA ID (not used if client)
staRx.pos = measLine(8:10)';  % Receiver bSTA position (not used if client)
%----------------------------------------------------------

end

function c = isClient(id)
c = id < 0;
end

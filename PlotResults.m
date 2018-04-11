% PlotResults displays estimated and reference trajectories on venue map.
% In addition, it plots the empirical cumulative distribution function
% Usage: PlotResults(cfg,posMat,bPos,refPos)

% For questions/comments contact: 
% leor.banin@intel.com, 
% ofer.bar-shalom@intel.com, 
% nir.dvorecki@intel.com,
% yuval.amizur@intel.com

% Copyright (C) 2018 Intel Corporation
% SPDX-License-Identifier: BSD-3-Clause

function PlotResults(cfg,posMat,bPos,refPos)

% Plot Ref. and Estimated Trajectories on Map
figure;subplot(1,2,1);cla;hold on;axis equal
ImgData = imread(cfg.mapFile);
FloorPlan = image(ImgData, ...
            'XData', cfg.xMinMax, ...
            'YData', fliplr(cfg.yMinMax));
axis([-12, 6.7, -5 28])
uistack(FloorPlan, 'bottom');
set(gca,'Ydir','normal');
plot(posMat(:,1),posMat(:,2),'b.','MarkerSize',6,'MarkerFaceColor','b')
plot(refPos(:,1),refPos(:,2),'r.','MarkerSize',8,'LineWidth',4)
plot(bPos(:,1),bPos(:,2),'ro','MarkerSize',8,'LineWidth',3);
xlabel('x [m]')
ylabel('y [m]')

title(cfg.name)

leg1 = legend('$\hat\mathbf{p}$','$\mathbf{p}$','bSTA','Location','southwest');
set(leg1,'Interpreter','latex');

% Plot Positioning Error Empirical CDF (ECDF)
Nsamp = length(posMat(:,1));
posErr = zeros(Nsamp,1);
for kk = 1:Nsamp
    posErr(kk) = norm(posMat(kk,:)-refPos(kk,:));
end

[X,Y] = CalcEcdf(posErr);
subplot(1,2,2); hold on;grid on; box on
plot(X,Y,'-','LineWidth',2)
xlabel('Position Error [m]')
ylabel('CDF [%]')
title(cfg.name)
end

% -----------------------------------------------------
function [X,Y] = CalcEcdf(in)
N = length(in);
in_s = sort(in);
Y = (1:N)/N*100;
X=in_s(:);Y=Y(:);
end


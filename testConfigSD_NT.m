function cfg = testConfigSD_NT()
cfg = testConfigSD();
cfg.disableClkTracking = 1;
cfg.name = [cfg.name,' NT'];
end
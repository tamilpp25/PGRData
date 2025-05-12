---@class XInstrumentSimulatorControl : XControl
---@field private _Model XInstrumentSimulatorModel
local XInstrumentSimulatorControl = XClass(XControl, "XInstrumentSimulatorControl")
function XInstrumentSimulatorControl:OnInit()
    --初始化内部变量
end

function XInstrumentSimulatorControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XInstrumentSimulatorControl:RemoveAgencyEvent()

end

function XInstrumentSimulatorControl:OnRelease()
    XLog.Error("这里执行Control的释放")
end

return XInstrumentSimulatorControl
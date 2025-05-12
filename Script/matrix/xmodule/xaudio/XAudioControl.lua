---@class XAudioControl : XControl
---@field private _Model XAudioModel
local XAudioControl = XClass(XControl, "XAudioControl")
function XAudioControl:OnInit()
    --初始化内部变量
end

function XAudioControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XAudioControl:RemoveAgencyEvent()

end

function XAudioControl:OnRelease()
    XLog.Error("这里执行Control的释放")
end

return XAudioControl
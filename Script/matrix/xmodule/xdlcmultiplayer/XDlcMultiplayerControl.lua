---@class XDlcMultiplayerControl : XControl
---@field private _Model XDlcMultiplayerModel
local XDlcMultiplayerControl = XClass(XControl, "XDlcMultiplayerControl")

function XDlcMultiplayerControl:OnInit()
    --初始化内部变量
end

function XDlcMultiplayerControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XDlcMultiplayerControl:RemoveAgencyEvent()

end

function XDlcMultiplayerControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
end

return XDlcMultiplayerControl
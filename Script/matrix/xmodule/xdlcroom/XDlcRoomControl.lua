---@class XDlcRoomControl : XControl
---@field private _Model XDlcRoomModel
local XDlcRoomControl = XClass(XControl, "XDlcRoomControl")

function XDlcRoomControl:OnInit()
    --初始化内部变量
end

function XDlcRoomControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XDlcRoomControl:RemoveAgencyEvent()

end

function XDlcRoomControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
end

return XDlcRoomControl
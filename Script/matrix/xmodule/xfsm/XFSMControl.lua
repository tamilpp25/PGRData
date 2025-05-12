---@class XFSMControl : XControl
---@field private _Model XFSMModel
local XFSMControl = XClass(XControl, "XFSMControl")
function XFSMControl:OnInit()
    --初始化内部变量
end

function XFSMControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XFSMControl:RemoveAgencyEvent()

end

function XFSMControl:OnRelease()
end

return XFSMControl
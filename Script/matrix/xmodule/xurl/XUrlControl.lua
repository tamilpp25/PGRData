---@class XUrlControl : XControl
---@field private _Model XUrlModel
local XUrlControl = XClass(XControl, "XUrlControl")
function XUrlControl:OnInit()
    --初始化内部变量
end

function XUrlControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XUrlControl:RemoveAgencyEvent()

end

function XUrlControl:OnRelease()

end

return XUrlControl
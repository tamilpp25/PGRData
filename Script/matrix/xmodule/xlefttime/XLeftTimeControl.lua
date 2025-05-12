---@class XLeftTimeControl : XControl
---@field private _Model XLeftTimeModel
local XLeftTimeControl = XClass(XControl, "XLeftTimeControl")
function XLeftTimeControl:OnInit()
    --初始化内部变量
end

function XLeftTimeControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XLeftTimeControl:RemoveAgencyEvent()

end

function XLeftTimeControl:OnRelease()
end

return XLeftTimeControl
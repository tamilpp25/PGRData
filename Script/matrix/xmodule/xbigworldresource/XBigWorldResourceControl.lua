---@class XBigWorldResourceControl : XControl
---@field private _Model XBigWorldResourceModel
local XBigWorldResourceControl = XClass(XControl, "XBigWorldResourceControl")
function XBigWorldResourceControl:OnInit()
    --初始化内部变量
end

function XBigWorldResourceControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldResourceControl:RemoveAgencyEvent()

end

function XBigWorldResourceControl:OnRelease()
end

return XBigWorldResourceControl
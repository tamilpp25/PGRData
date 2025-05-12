---@class XBigWorldCharacterControl : XControl
---@field private _Model XBigWorldCharacterModel
local XBigWorldCharacterControl = XClass(XControl, "XBigWorldCharacterControl")
function XBigWorldCharacterControl:OnInit()
    --初始化内部变量
end

function XBigWorldCharacterControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldCharacterControl:RemoveAgencyEvent()

end

function XBigWorldCharacterControl:OnRelease()
end

return XBigWorldCharacterControl
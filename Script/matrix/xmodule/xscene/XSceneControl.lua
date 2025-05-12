---@class XSceneControl : XControl
---@field private _Model XSceneModel
local XSceneControl = XClass(XControl, "XSceneControl")
function XSceneControl:OnInit()
end

function XSceneControl:AddAgencyEvent()
end

function XSceneControl:RemoveAgencyEvent()

end

function XSceneControl:OnRelease()
end

return XSceneControl
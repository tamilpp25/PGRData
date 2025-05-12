---@class XSkyGardenControl : XControl
---@field private _Model XSkyGardenModel
---@field private _Agency XSkyGardenAgency
local XSkyGardenControl = XClass(XControl, "XSkyGardenControl")
function XSkyGardenControl:OnInit()
end

function XSkyGardenControl:AddAgencyEvent()
end

function XSkyGardenControl:RemoveAgencyEvent()
end

function XSkyGardenControl:OnRelease()
end

return XSkyGardenControl
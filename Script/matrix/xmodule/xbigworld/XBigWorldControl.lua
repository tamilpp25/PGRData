---@class XBigWorldControl : XControl
---@field private _Model XBigWorldModel
---@field private _Agency XBigWorldAgency
local XBigWorldControl = XClass(XControl, "XBigWorldControl")
function XBigWorldControl:OnInit()
    self:GetAgency()
end

function XBigWorldControl:AddAgencyEvent()
end

function XBigWorldControl:RemoveAgencyEvent()
end

function XBigWorldControl:OnRelease()
end

--region 主界面跳转

function XBigWorldControl:OpenMenu()
    self._Agency:OpenMenu()
end

function XBigWorldControl:OpenQuest()
    self._Agency:OpenQuest()
end

function XBigWorldControl:OpenBackpack()
    self._Agency:OpenBackpack()
end

function XBigWorldControl:OpenMessage()
    self._Agency:OpenMessage()
end

function XBigWorldControl:OpenTeam()
    self._Agency:OpenTeam()
end

function XBigWorldControl:OpenExplore()
    self._Agency:OpenExplore()
end

function XBigWorldControl:OpenPhoto()
    self._Agency:OpenPhoto()
end

function XBigWorldControl:OpenTeaching()
    self._Agency:OpenTeaching()
end

function XBigWorldControl:OpenSetting()
    self._Agency:OpenSetting()
end

function XBigWorldControl:OpenMap()
    self._Agency:OpenMap()
end

function XBigWorldControl:OpenFashion(characterId, typeIndex)
    self._Agency:OpenFashion(characterId, typeIndex)
end

function XBigWorldControl:Exit()
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():Exit()
end

--endregion 主界面跳转

return XBigWorldControl
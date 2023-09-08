local XRobot = require("XEntity/XRobot/XRobot")

---@class XUiTaikoMasterGridRoleSelect : XUiNode
---@field _Control XTaikoMasterControl
local XUiTaikoMasterGridRoleSelect = XClass(XUiNode, "XUiTaikoMasterGridRoleSelect")

function XUiTaikoMasterGridRoleSelect:OnStart()
end

function XUiTaikoMasterGridRoleSelect:OnEnable()
    self:Refresh()
end

function XUiTaikoMasterGridRoleSelect:SetData(robotId)
    ---@type XRobot
    self._Robot = XRobot.New(robotId)
    self.PanelSelected.gameObject:SetActiveEx(false)
    self.TxtCurObj.gameObject:SetActiveEx(false)
    self.PanelTry.gameObject:SetActiveEx(false)
end

function XUiTaikoMasterGridRoleSelect:Refresh(selectRobotId, teamPos)
    if not XTool.IsNumberValid(selectRobotId) then
        return
    end
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    local isInTeam = self._Control:GetIsInTeam(self._Robot:GetId())
    local curTeamEntityId = self._Control:GetTeam():GetEntityId(teamPos)
    self.PanelSelected.gameObject:SetActiveEx(selectRobotId == self._Robot:GetId())
    self.TxtCurObj.gameObject:SetActiveEx(curTeamEntityId == self._Robot:GetId() and isInTeam)
    self.RImgHeadIcon:SetRawImage(XCharacterCuteConfig.GetCuteModelSmallHeadIcon(self._Robot:GetCharacterId()))
    self.Txt1.text = ag:GetCharacterName(self._Robot:GetCharacterId())
    self.Txt2.text = ag:GetCharacterTradeName(self._Robot:GetCharacterId())
end

return XUiTaikoMasterGridRoleSelect
local BasePanel = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
--==================
--超级爬塔 爬塔 结算界面信息面板控件
--==================
local XUiStTsRoleInfoPanel = XClass(BasePanel, "XUiStTsRoleInfoPanel")

function XUiStTsRoleInfoPanel:InitPanel()
    self:InitTeamInfo()
    self:InitRoleList()
    self:InitText()
end

function XUiStTsRoleInfoPanel:InitTeamInfo()
    self.Team = XDataCenter.SuperTowerManager.GetTeamByStageType(XDataCenter.SuperTowerManager.StageType.LllimitedTower)
    self.TeamMember = {}
    for i = 1,3 do
        local entityId = self.Team:GetEntityIdByTeamPos(i)
        local entityRole = XDataCenter.SuperTowerManager.GetRoleManager():GetRole(entityId)
        self.TeamMember[i] = entityRole
    end
end

function XUiStTsRoleInfoPanel:InitRoleList()
    self.GridRole.gameObject:SetActiveEx(false)
    for i = 1, 3 do
        local newRoleGo = CS.UnityEngine.Object.Instantiate(self.GridRole.gameObject, self.RoleContent)
        local role = {}
        XTool.InitUiObjectByUi(role, newRoleGo)
        if self.TeamMember[i] then
            role.RImgIcon:SetRawImage(self.TeamMember[i]:GetCharacterViewModel():GetBigHeadIcon())
            role.GameObject:SetActiveEx(true)
        end
    end
end

function XUiStTsRoleInfoPanel:InitText()
    self.TxtPlayerName.text = XPlayer.Name
    for i = 1, 3 do
        if self.TeamMember[i] and self["TxtMemberName" .. i] then
            self["TxtMemberName" .. i].text = self.TeamMember[i]:GetCharacterViewModel():GetTradeName()
        end
    end
    local timeStr = XTime.TimestampToLocalDateTimeString(XTime.GetServerNowTimestamp())
    local strs = string.Split(timeStr, " ")
    self.TxtTimeDay.text = strs and strs[1] or ""
    self.TxtTimeHour.text = strs and strs[2] or ""
end

return XUiStTsRoleInfoPanel
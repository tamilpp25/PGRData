--######################## XUiTeamSkillGrid ########################
local XUiTeamSkillGrid = XClass(nil, "XUiTeamSkillGrid")

function XUiTeamSkillGrid:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

function XUiTeamSkillGrid:SetData(buffData, isActive, currentCount, maxCount)
    self.RImgSkillIcon:SetRawImage(buffData.Icon)
    self.TxtSkillName.text = string.format( "%s(%s/%s)", buffData.Name, currentCount, maxCount)
    self.TxtSkillDesc.text = buffData.Desc
    self.PanelSelect.gameObject:SetActiveEx(isActive)
    self.PanelNone.gameObject:SetActiveEx(not isActive)
end

--######################## XUiChildPanel ########################

local XUiChildPanel = XClass(nil, "XUiChildPanel")

function XUiChildPanel:Ctor(ui)
    self.GuildWarManager = XDataCenter.GuildWarManager
    XUiHelper.InitUiClass(self, ui)
end

function XUiChildPanel:SetData(team)
    local entityId
    for i = 1, 3 do
        entityId = team:GetEntityIdByTeamPos(i)
        self["RImgIcon" .. i].gameObject:SetActiveEx(entityId > 0 
            and self.GuildWarManager.CheckIsSpecialRole(entityId))
    end
end

--######################## XUiGuildWarBattleRoleRoom ########################
local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiGuildWarBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiGuildWarBattleRoleRoom")

function XUiGuildWarBattleRoleRoom:Ctor(team, stageId)
    self.GuildWarManager = XDataCenter.GuildWarManager
    self.Team = team
end

function XUiGuildWarBattleRoleRoom:GetChildPanelData()
    return {
        assetPath = XUiConfigs.GetComponentUrl("UpCharacterIcon"),
        proxy = XUiChildPanel,
        proxyArgs = { "Team" },
    }
end

function XUiGuildWarBattleRoleRoom:GetRoleDetailProxy()
    return require("XUi/XUiGuildWar/XUiGuildWarBattleRoomRoleDetail")
end

function XUiGuildWarBattleRoleRoom:CreateCustomTipGo(panel)
    panel.gameObject:SetActiveEx(true)
    local go = panel:LoadPrefab(XUiConfigs.GetComponentUrl("UPCharacterTeamSkills"))
    local teamSkillGrid = XUiTeamSkillGrid.New(go)
    local teamBuff = self.GuildWarManager.GetSpecialTeamBuff()
    if teamBuff == nil then return end
    local currentCount, maxCount, isActive = self.GuildWarManager.CheckIsSpecialTeam(self.Team:GetEntityIds())
    teamSkillGrid:SetData(teamBuff, isActive, currentCount, maxCount)
end

-- return : bool 是否开启自动关闭检查
--          , number 自动关闭的时间戳(秒)
--          , function 每秒更新的回调 function(isClose) isClose标志是否到达结束时间
function XUiGuildWarBattleRoleRoom:GetAutoCloseInfo()
    return true, self.GuildWarManager.GetRoundEndTime(), function(isClose)
        if isClose then
            self.GuildWarManager.OnActivityEndHandler()
        end
    end
end

return XUiGuildWarBattleRoleRoom

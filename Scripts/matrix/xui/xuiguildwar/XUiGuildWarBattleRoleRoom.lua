--######################## XUiTeamSkillGrid ########################
local XUiTeamSkillGrid = XClass(nil, "XUiTeamSkillGrid")

function XUiTeamSkillGrid:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

function XUiTeamSkillGrid:SetData(buffData, isActive, currentCount, maxCount)
    self.RImgSkillIcon:SetRawImage(buffData.Icon)
    self.TxtSkillName.text = string.format("%s(%s/%s)", buffData.Name, currentCount, maxCount)
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
    -- 特攻标记换了地方显示
    for i = 1, 3 do
        local uiIcon = self["RImgIcon" .. i]
        uiIcon.gameObject:SetActiveEx(false)
    end
end

--######################## XUiGuildWarBattleRoleRoom ########################
local XUiGuildWarFlagSpecialAndAssistant = require("XUi/XUiGuildWar/Assistant/XUiGuildWarFlagSpecialAndAssistant")
local XPartner = require("XEntity/XPartner/XPartner")
local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiGuildWarBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiGuildWarBattleRoleRoom")

function XUiGuildWarBattleRoleRoom:Ctor(team, stageId)
    self.GuildWarManager = XDataCenter.GuildWarManager
    ---@type XGuildWarTeam
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
    local currentCount, maxCount, isActive = self.GuildWarManager.CheckIsSpecialTeam(self.Team:GetMembers())
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

function XUiGuildWarBattleRoleRoom:AOPOnCharacterClickBefore(rootUi, index)
    RunAsyn(function()
        local oldMember = rootUi.Team:GetMember(index)
        local oldEntityId = oldMember and oldMember:GetEntityId()
        XLuaUiManager.Open("UiGuildWarCharacterSelect", rootUi.Team , index)
        local signalCode, newMemberData = XLuaUiManager.AwaitSignal("UiGuildWarCharacterSelect", "UpdateEntityId", self)
        if signalCode ~= XSignalCode.SUCCESS then return end
        local newEntityId = newMemberData and newMemberData.EntityId
        if oldEntityId == newEntityId then return end
        if not rootUi.Team:GetMember(index) then return end
        -- 播放音效
        local soundType = XFavorabilityConfigs.SoundEventType.MemberJoinTeam
        if rootUi.Team:GetCaptainPos() == index then
            soundType = XFavorabilityConfigs.SoundEventType.CaptainJoinTeam
        end
        rootUi.FavorabilityManager.PlayCvByType(newMemberData.EntityId, soundType)
    end)
    return true
end

function XUiGuildWarBattleRoleRoom:AOPHideCharacterLimits()
    return true
end

function XUiGuildWarBattleRoleRoom:ClearErrorTeamEntityId(team)
    team:KickOutInvalidMembers()
end

---@param team XGuildWarTeam
function XUiGuildWarBattleRoleRoom:AOPGoPartnerCarry(team, pos)
    team:GoPartnerCarry(pos)
    return true
end

-- 检查是否满足关卡配置的强制性条件
-- return : bool
function XUiGuildWarBattleRoleRoom:CheckStageForceConditionWithTeamEntityId(team, stageId, showTip)
    local fubenManager = XDataCenter.FubenManager
    local _, forceConditionIds = fubenManager.GetConditonByMapId(stageId)
    return fubenManager.CheckFightConditionByTeamData(forceConditionIds, team:GetEntityIds(), showTip)
end

-- 根据实体id获取角色视图数据
-- return : XCharacterViewModel
function XUiGuildWarBattleRoleRoom:GetCharacterViewModelByEntityId(entityId)
    local member = self.Team:GetMemberByEntityId(entityId)
    return member and member:GetCharacterViewModel() or nil
end

-- 通过实体Id获取角色Id，基本上只要实现好GetCharacterViewModelByEntityId接口可不必处理该接口
-- return : number 角色id
function XUiGuildWarBattleRoleRoom:GetCharacterIdByEntityId(entityId)
    local viewModel = self:GetCharacterViewModelByEntityId(entityId)
    if viewModel == nil then return end
    return viewModel:GetId()
end

-- 获取实体战力，如有特殊战力计算公式，可重写
-- return : number 战力
function XUiGuildWarBattleRoleRoom:GetRoleAbility(entityId)
    local member = self.Team:GetMemberByEntityId(entityId)
    return member:GetAbility()
end

-- 根据实体Id获取伙伴实体
-- return : XPartner
function XUiGuildWarBattleRoleRoom:GetPartnerByEntityId(entityId)
    local member = self.Team:GetMemberByEntityId(entityId)
    if not member then return nil end
    local partnerId = member:GetPartner()
    if not partnerId then
        return nil
    end
    return XPartner.New(nil, partnerId, true)
end

-- 进入战斗
-- team : XTeam
-- stageId : number
function XUiGuildWarBattleRoleRoom:EnterFight(team, stageId, challengeCount, isAssist)    
    XDataCenter.GuildWarManager.RequestSetTeam(team:GetTeamInfo(), function()
        XUiGuildWarBattleRoleRoom.Super.EnterFight(self, team, stageId, challengeCount, isAssist)
    end)
end

function XUiGuildWarBattleRoleRoom:AOPRefreshRoleInfosAfter(uiRoom)
    if not uiRoom.UiPanelGuildwarTips1 then
        uiRoom.UiPanelGuildwarTips1 = XUiGuildWarFlagSpecialAndAssistant.New(uiRoom.PanelGuildwarTips1)
    end
    if not uiRoom.UiPanelGuildwarTips2 then
        uiRoom.UiPanelGuildwarTips2 = XUiGuildWarFlagSpecialAndAssistant.New(uiRoom.PanelGuildwarTips2)
    end
    if not uiRoom.UiPanelGuildwarTips3 then
        uiRoom.UiPanelGuildwarTips3 = XUiGuildWarFlagSpecialAndAssistant.New(uiRoom.PanelGuildwarTips3)
    end
    uiRoom.UiPanelGuildwarTips1:Update(uiRoom.Team:GetMember(1))
    uiRoom.UiPanelGuildwarTips2:Update(uiRoom.Team:GetMember(2))
    uiRoom.UiPanelGuildwarTips3:Update(uiRoom.Team:GetMember(3))
end

return XUiGuildWarBattleRoleRoom

local pairs = pairs
local ipairs = ipairs
local ANIMATION_OPEN = "AniBfrtDeployBegin"

local XUiGridEchelon = require("XUi/XUiBfrt/XUiGridEchelon")

---@class XUiBfrtDeploy
local XUiBfrtDeploy = XLuaUiManager.Register(XLuaUi, "UiBfrtDeploy")

function XUiBfrtDeploy:OnAwake()
    XDataCenter.BfrtManager.InitTeamCaptainPos()
    XDataCenter.BfrtManager.InitTeamFirstFightPos()
    self:AutoAddListener()
    self.GridEchelon.gameObject:SetActiveEx(false)
    self:ResetGroupInfo()
end

function XUiBfrtDeploy:OnStart(groupId)
    self:InitGroupInfo(groupId)
    self:PlayAnimation(ANIMATION_OPEN)
end

function XUiBfrtDeploy:OnDestroy()
    for index, echelonId in ipairs(self.FightInfoIdList) do
        XDataCenter.BfrtManager.InitTeamCaptainPos()
        XDataCenter.BfrtManager.InitTeamFirstFightPos()
    end
    self:ResetGroupInfo()
end

function XUiBfrtDeploy:ResetGroupInfo()
    self.GroupId = nil
    self.FightInfoIdList = {}
    self.LogisticsInfoIdList = {}
    self.FightTeamList = {}
    self.LogisticsTeamList = {}
    self.CharacterIdListWrap = {}
    self.FightTeamGridList = {}
    self.LogisticsTeamGridList = {}
end

function XUiBfrtDeploy:InitGroupInfo(groupId)
    if not groupId then
        XLog.Error("XUiBfrtDeploy:InitGroupInfo error: groupId not Exist.")
        return
    end
    self.GroupId = groupId
    self.FightInfoIdList = XDataCenter.BfrtManager.GetFightInfoIdList(groupId)
    self.LogisticsInfoIdList = XDataCenter.BfrtManager.GetLogisticsInfoIdList(groupId)
    self.FightTeamList = XDataCenter.BfrtManager.GetFightTeamList(groupId)
    self.LogisticsTeamList = XDataCenter.BfrtManager.GetLogisticsTeamList(groupId)

    self:UpdateEchelonList()
end

function XUiBfrtDeploy:AutoAddListener()
    self.BtnAutoTeam.CallBack = function() self:OnBtnAutoTeamClick() end
    self.BtnFight.CallBack = function() self:OnBtnFightClick() end
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnQuickDeploy.CallBack = function() self:OnBtnQuickDeployClick() end
end

function XUiBfrtDeploy:OnBtnFightClick()
    --先检查挑战次数
    local groupId = self.GroupId
    local baseStageId = XDataCenter.BfrtManager.GetBaseStage(groupId)
    local chanllengeNum = XDataCenter.BfrtManager.GetGroupFinishCount(baseStageId)
    local maxChallengeNum = XDataCenter.BfrtManager.GetGroupMaxChallengeNum(baseStageId)
    if maxChallengeNum > 0 and chanllengeNum >= maxChallengeNum then
        XUiManager.TipMsg(CS.XTextManager.GetText("FubenChallengeCountNotEnough"))
        return
    end

    --再检查队伍
    local fightTeamList = self.FightTeamList
    local logisticsTeamList = self.LogisticsTeamList
    local checkTeamCb = function()
        self:Close()
        XLuaUiManager.Open("UiBfrtInfo", groupId, fightTeamList)
    end

    XDataCenter.BfrtManager.CheckTeam(groupId, fightTeamList, logisticsTeamList, checkTeamCb)
end

function XUiBfrtDeploy:OnBtnAutoTeamClick()
    local fightTeamList, logisticsTeamList, anyMemberInTeam = XDataCenter.BfrtManager.AutoTeam(self.GroupId)
    if not anyMemberInTeam then
        XUiManager.TipMsg(CS.XTextManager.GetText("BfrtAutoTeamNoMember"))
        return
    end

    self.FightTeamList, self.LogisticsTeamList = fightTeamList, logisticsTeamList
    self:UpdateEchelonList()
end

function XUiBfrtDeploy:OnBtnQuickDeployClick()
    local groupId = self.GroupId
    local saveCb = function()
        self:UpdateEchelonList()
    end
    self:OpenChildUi("UiBfrtQuickDeploy", groupId, self, saveCb)
end

function XUiBfrtDeploy:OnBtnBackClick()
    self:Close()
end

function XUiBfrtDeploy:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiBfrtDeploy:UpdateEchelonList()
    local passCondition = true

    local data = {
        EchelonType = nil,
        BfrtGroupId = self.GroupId,
        EchelonId = nil,
        EchelonIndex = nil,
        BaseStage = XDataCenter.BfrtManager.GetBaseStage(self.GroupId),
    }

    for index, echelonId in ipairs(self.FightInfoIdList) do
        data.EchelonType = XDataCenter.BfrtManager.EchelonType.Fight
        data.EchelonId = echelonId
        data.EchelonIndex = index
        data.TeamList = self.FightTeamList
        data.CharacterIdListWrap = self.CharacterIdListWrap

        local grid = self.FightTeamGridList[index]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridEchelon)
            grid = XUiGridEchelon.New(self, ui, data)
            grid.Transform:SetParent(self.PanelEchelonContent, false)
            grid.GameObject:SetActiveEx(true)
            grid.GameObject.name = tostring(echelonId)
            self.FightTeamGridList[index] = grid
        else
            grid:UpdateEchelonInfo(data)
        end

        passCondition = passCondition and grid.ConditionPassed
    end

    for i = #self.FightInfoIdList + 1, #self.FightTeamList do
        self.FightTeamList[i] = nil
    end

    for index, echelonId in ipairs(self.LogisticsInfoIdList) do
        data.EchelonType = XDataCenter.BfrtManager.EchelonType.Logistics
        data.EchelonId = echelonId
        data.EchelonIndex = index
        data.TeamList = self.LogisticsTeamList
        data.CharacterIdListWrap = self.CharacterIdListWrap

        local grid = self.LogisticsTeamGridList[index]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridEchelon)
            grid = XUiGridEchelon.New(self, ui, data)
            grid.Transform:SetParent(self.PanelEchelonContent, false)
            grid.GameObject:SetActiveEx(true)
            grid.GameObject.name = tostring(echelonId)
            self.LogisticsTeamGridList[index] = grid
        else
            grid:UpdateEchelonInfo(data)
        end

        passCondition = passCondition and grid.ConditionPassed
    end

    for i = #self.LogisticsInfoIdList + 1, #self.LogisticsTeamList do
        self.LogisticsTeamList[i] = nil
    end

    -- self.PanelDanger.gameObject:SetActiveEx(not passCondition)
    self.PanelDanger.gameObject:SetActiveEx(false)

    local allTeamEmpty = self:CheckAllTeamEmpty()
    self.BtnQuickDeploy.gameObject:SetActiveEx(not allTeamEmpty)
end

function XUiBfrtDeploy:CheckIsInTeamList(characterId, curEchelonIndex)
    if not characterId or characterId == 0 then
        return
    end

    for echelonIndex, team in pairs(self.FightTeamList) do
        if curEchelonIndex ~= echelonIndex then
            for _, id in pairs(team) do
                if id == characterId then
                    return echelonIndex, XDataCenter.BfrtManager.EchelonType.Fight
                end
            end
        end
    end

    for echelonIndex, team in pairs(self.LogisticsTeamList) do
        if curEchelonIndex ~= echelonIndex then
            for _, id in pairs(team) do
                if id == characterId then
                    return echelonIndex, XDataCenter.BfrtManager.EchelonType.Logistics
                end
            end
        end
    end
end

function XUiBfrtDeploy:CheckAllTeamEmpty()
    for echelonIndex, team in pairs(self.FightTeamList) do
        for _, id in pairs(team) do
            if id and id > 0 then
                return false
            end
        end
    end

    for echelonIndex, team in pairs(self.LogisticsTeamList) do
        for _, id in pairs(team) do
            if id and id > 0 then
                return false
            end
        end
    end

    return true
end

function XUiBfrtDeploy:FindTeamPos(characterId)
    if not characterId or characterId <= 0 then return end

    local findTeam, findPos

    for _, team in pairs(self.FightTeamList) do
        for pos, id in pairs(team) do
            if id == characterId then
                findTeam = team
                findPos = pos
                break
            end
        end
    end

    if not findTeam then
        for _, team in pairs(self.LogisticsTeamList) do
            for pos, id in pairs(team) do
                if id == characterId then
                    findTeam = team
                    findPos = pos
                    break
                end
            end
        end
    end

    return findTeam, findPos
end

function XUiBfrtDeploy:CharacterSwapEchelon(oldCharacterId, newCharacterId)
    local oldTeam, oldCharacterPos = self:FindTeamPos(oldCharacterId)
    local newTeam, newCharacterPos = self:FindTeamPos(newCharacterId)

    if oldTeam and oldCharacterPos then
        oldTeam[oldCharacterPos] = newCharacterId
    end

    if newTeam and newCharacterPos then
        newTeam[newCharacterPos] = oldCharacterId
    end
end
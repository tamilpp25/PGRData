local XUiGridQuickDeployTeam = require("XUi/XUiBfrt/XUiGridQuickDeployTeam")

local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiBfrtQuickDeploy = XLuaUiManager.Register(XLuaUi, "UiBfrtQuickDeploy")

function XUiBfrtQuickDeploy:OnAwake()
    self.GridQuickDeployTeam.gameObject:SetActiveEx(false)
    self:AutoAddListener()
end

function XUiBfrtQuickDeploy:OnStart(groupId, rootUi, saveCb)
    self.GroupId = groupId
    self.RootUi = rootUi
    self.SaveCb = saveCb
    self.StageIds = XDataCenter.BfrtManager.GetStageIdList(groupId)
    self.FightInfoIdList = XDataCenter.BfrtManager.GetFightInfoIdList(groupId)
    self.LogisticsInfoIdList = XDataCenter.BfrtManager.GetLogisticsInfoIdList(groupId)
    self.TeamGridList = {}
end

function XUiBfrtQuickDeploy:OnEnable()
    self:UpdateView()
    XDataCenter.UiPcManager.OnUiEnable(self)
end

function XUiBfrtQuickDeploy:OnDisable()
    self.OldSelectCharacterId = nil
    self.OldTeam = nil
    self.OldPos = nil

    if self.LastSelectGrid then
        self.LastSelectGrid:SetSelect(false)
        self.LastSelectGrid = nil
    end
    XDataCenter.UiPcManager.OnUiDisableAbandoned(true, self)
end

function XUiBfrtQuickDeploy:GetTeamCharacterType(team)
    for _, characterId in pairs(team or {}) do
        if characterId ~= 0 then
            return XMVCA.XCharacter:GetCharacterType(characterId)
        end
    end
end

function XUiBfrtQuickDeploy:UpdateView()
    local fightTeamList = self.RootUi.FightTeamList
    local logisticsTeamList = self.RootUi.LogisticsTeamList
    local fightInfoIdList = self.FightInfoIdList
    local logisticsInfoIdList = self.LogisticsInfoIdList

    local memberClickCb = function(characterId, grid, pos, team, characterLimitType)
        local oldSelectCharacterId = self.OldSelectCharacterId
        if oldSelectCharacterId then
            if not (characterId == 0 and oldSelectCharacterId == 0)
            and characterId ~= oldSelectCharacterId then
                local swapFunc = function(isReset)
                    self:SwapTeamPos(self.OldTeam, self.OldPos, team, pos, isReset)
                    self:UpdateView()

                    grid:ShowEffect()
                    self.LastSelectGrid:ShowEffect()
                    self.LastSelectGrid:SetSelect(false)
                    self.LastSelectGrid = nil

                    self.OldSelectCharacterId = nil
                    self.OldTeam = nil
                    self.OldPos = nil
                end

                local oldCharacterType = self:GetTeamCharacterType(self.OldTeam)
                local newCharacterType = self:GetTeamCharacterType(team)

                --仅当副本限制类型为构造体/感染体强制要求时赋值
                local oldForceCharacterType = XDataCenter.FubenManager.GetForceCharacterTypeByCharacterLimitType(self.OldCharacterLimitType)
                local newForceCharacterType = XDataCenter.FubenManager.GetForceCharacterTypeByCharacterLimitType(characterLimitType)

                --角色类型不符合副本限制类型
                if oldForceCharacterType and newCharacterType and oldForceCharacterType ~= newCharacterType
                or newForceCharacterType and oldCharacterType and newForceCharacterType ~= oldCharacterType then
                    XUiManager.TipText("SwapCharacterTypeIsNotMatch")
                    return
                end

                if characterLimitType == XFubenConfigs.CharacterLimitType.Isomer or
                    characterLimitType == XFubenConfigs.CharacterLimitType.Normal then
                    --角色类型不一致
                    if newCharacterType and oldCharacterType and oldCharacterType ~= newCharacterType then
                        local content = CSXTextManagerGetText("SwapCharacterTypeIsDiffirent")
                        local sureCallBack = function() swapFunc(true) end
                        XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, sureCallBack)
                        return
                    end
                end

                swapFunc()
                return
            end
        end

        if self.LastSelectGrid then
            self.LastSelectGrid:SetSelect(false)
        end
        self.LastSelectGrid = grid
        self.LastSelectGrid:SetSelect(true)
        self.LastSelectGrid:ShowEffect()

        self.OldSelectCharacterId = characterId
        self.OldTeam = team
        self.OldPos = pos
        self.OldCharacterLimitType = characterLimitType
    end

    local gridIndex = 1
    local teamGridList = self.TeamGridList
    local stageIds = self.StageIds
    local groupId = self.GroupId
    for index, echelonId in pairs(fightInfoIdList) do
        local teamGrid = teamGridList[gridIndex]
        if not teamGrid then
            local go = CSUnityEngineObjectInstantiate(self.GridQuickDeployTeam, self.PanelFormationTeamContent)
            teamGrid = XUiGridQuickDeployTeam.New(go, memberClickCb)
            teamGridList[gridIndex] = teamGrid
        end

        local team = fightTeamList[index]
        local characterLimitType = XFubenConfigs.GetStageCharacterLimitType(stageIds[index])
        teamGrid:Refresh(echelonId, team, index, XDataCenter.BfrtManager.EchelonType.Fight, characterLimitType, groupId)
        teamGrid.GameObject:SetActiveEx(true)

        gridIndex = gridIndex + 1
    end

    for index, echelonId in pairs(logisticsInfoIdList) do
        local teamGrid = teamGridList[gridIndex]
        if not teamGrid then
            local go = CSUnityEngineObjectInstantiate(self.GridQuickDeployTeam, self.PanelFormationTeamContent)
            teamGrid = XUiGridQuickDeployTeam.New(go, memberClickCb)
            teamGridList[gridIndex] = teamGrid
        end

        local team = logisticsTeamList[index]
        local characterLimitType = XFubenConfigs.GetStageCharacterLimitType(stageIds[index])
        teamGrid:Refresh(echelonId, team, index, XDataCenter.BfrtManager.EchelonType.Logistics, characterLimitType, groupId)
        teamGrid.GameObject:SetActiveEx(true)

        gridIndex = gridIndex + 1
    end

    for i = gridIndex + 1, #teamGridList do
        teamGridList[i].GameObject:SetActiveEx(false)
    end
end

function XUiBfrtQuickDeploy:AutoAddListener()
    -- self.BtnClose.CallBack = function() self:Close() end
    self.BtnConfirm.CallBack = function() self:OnClickBtnConfirm() end
end

function XUiBfrtQuickDeploy:OnClickBtnConfirm()
    self.SaveCb()
    self:Close()
end

function XUiBfrtQuickDeploy:SwapTeamPos(oldTeam, oldCharacterPos, newTeam, newCharacterPos, isReset)
    local oldCharacterId = oldTeam[oldCharacterPos]
    local newCharacterId = newTeam[newCharacterPos]

    if oldTeam and oldCharacterPos then
        if isReset then
            for k in pairs(oldTeam) do
                oldTeam[k] = 0
            end
        end
        oldTeam[oldCharacterPos] = newCharacterId
    end

    if newTeam and newCharacterPos then
        if isReset then
            for k in pairs(oldTeam) do
                newTeam[k] = 0
            end
        end
        newTeam[newCharacterPos] = oldCharacterId
    end
end
local XUiChessPursuitGridQuickDeployTeam = require("XUi/XUiChessPursuit/XUi/QuickDeploy/XUiChessPursuitGridQuickDeployTeam")

local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiChessPursuitQuickDeploy = XLuaUiManager.Register(XLuaUi, "UiChessPursuitQuickDeploy")

function XUiChessPursuitQuickDeploy:OnAwake()
    self.GridQuickDeployTeam.gameObject:SetActiveEx(false)
    self:AutoAddListener()
end

function XUiChessPursuitQuickDeploy:OnStart(mapId, saveCb)
    self.MapId = mapId
    self.SaveCb = saveCb
    self.MapTeamGridList = XChessPursuitConfig.GetChessPursuitMapTeamGridList(mapId)
    self.TeamGridList = {}
    self.TeamDataList = {}
end

function XUiChessPursuitQuickDeploy:OnEnable()
    self:UpdateView()
end

function XUiChessPursuitQuickDeploy:OnDisable()
    self.OldSelectCharacterId = nil
    self.OldTeam = nil
    self.OldPos = nil

    if self.LastSelectGrid then
        self.LastSelectGrid:SetSelect(false)
        self.LastSelectGrid = nil
    end
end

function XUiChessPursuitQuickDeploy:OnDestroy()
    XDataCenter.ChessPursuitManager.ClearTempTeam()
end

function XUiChessPursuitQuickDeploy:GetTeamCharacterType(team)
    local id
    for _, characterId in pairs(team.TeamData or {}) do
        if characterId ~= 0 then
            id = XRobotManager.CheckIdToCharacterId(characterId)
            return XMVCA.XCharacter:GetCharacterType(id)
        end
    end
end

function XUiChessPursuitQuickDeploy:UpdateView()
    local memberClickCb = function(characterId, grid, pos, team, characterLimitType, teamGridIndex)
        local oldSelectCharacterId = self.OldSelectCharacterId
        if oldSelectCharacterId then
            if not (characterId == 0 and oldSelectCharacterId == 0)
            and characterId ~= oldSelectCharacterId then
                local swapFunc = function(isReset)
                    self:SwapTeamPos(self.OldTeam, self.OldPos, team, pos, isReset, teamGridIndex)
                    self:UpdateView()

                    grid:ShowEffect()
                    self.LastSelectGrid:ShowEffect()
                    self.LastSelectGrid:SetSelect(false)
                    self.LastSelectGrid = nil

                    self.OldSelectCharacterId = nil
                    self.OldTeam = nil
                    self.OldPos = nil
                    self.OldTeamGridIndex = nil
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

                --角色类型不一致
                if newCharacterType and oldCharacterType and oldCharacterType ~= newCharacterType then
                    local content = CSXTextManagerGetText("SwapCharacterTypeIsDiffirent")
                    local sureCallBack = function() swapFunc(true) end
                    XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, sureCallBack)
                    return
                end

                if not XDataCenter.ChessPursuitManager.CheckIsSwapTeamPos(self.OldTeamGridIndex, self.OldPos, teamGridIndex, pos) then
                    XUiManager.TipText("ChessPursuitNotSwitchCharacter")
                    return
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
        self.OldTeamGridIndex = teamGridIndex
    end

    --表的index从0开始
    for teamGridIndex, cubeIndex in ipairs(self.MapTeamGridList) do
        if not self.TeamDataList[teamGridIndex] then
            local teamData = XDataCenter.ChessPursuitManager.GetSaveTempTeamData(self.MapId, teamGridIndex) or {TeamData = {0,0,0}, CaptainPos = 1, FirstFightPos = 1}
            self.TeamDataList[teamGridIndex] = teamData
        end

        local teamGrid = self.TeamGridList[teamGridIndex]        
        if not teamGrid then
            local go = CSUnityEngineObjectInstantiate(self.GridQuickDeployTeam, self.PanelFormationTeamContent)
            teamGrid = XUiChessPursuitGridQuickDeployTeam.New(go, memberClickCb)
            self.TeamGridList[teamGridIndex] = teamGrid
        end
        local team = self.TeamDataList[teamGridIndex]
        teamGrid:Refresh(teamGridIndex, self.MapId, team)
        teamGrid.GameObject:SetActiveEx(true)
    end

    for i = #self.MapTeamGridList + 1, #self.TeamGridList do
        self.TeamGridList[i].GameObject:SetActiveEx(false)
    end
end

function XUiChessPursuitQuickDeploy:AutoAddListener()
    self.BtnConfirm.CallBack = function() self:OnClickBtnConfirm() end
end

function XUiChessPursuitQuickDeploy:OnClickBtnConfirm()
    self:SaveTeam()
    if self.SaveCb then
        self.SaveCb()
    end
    self:Close()
end

function XUiChessPursuitQuickDeploy:SaveTeam()
    XDataCenter.ChessPursuitManager.SaveTempTeamData(self.MapId)
end

function XUiChessPursuitQuickDeploy:SwapTeamPos(oldTeam, oldCharacterPos, newTeam, newCharacterPos, isReset, teamGridIndex)
    if not oldTeam or not oldTeam.TeamData or not oldCharacterPos or not newTeam or not newTeam.TeamData or not newCharacterPos then
        return
    end
    local oldCharacterId = oldTeam.TeamData[oldCharacterPos]
    local newCharacterId = newTeam.TeamData[newCharacterPos]

    if oldTeam and oldCharacterPos then
        if isReset then
            for k in pairs(oldTeam.TeamData) do
                oldTeam.TeamData[k] = 0
            end
        end
        oldTeam.TeamData[oldCharacterPos] = newCharacterId
    end

    if newTeam and newCharacterPos then
        if isReset then
            for k in pairs(newTeam.TeamData) do
                newTeam.TeamData[k] = 0
            end
        end
        newTeam.TeamData[newCharacterPos] = oldCharacterId
    end

    XDataCenter.ChessPursuitManager.QuickDeploySetPlayerTeamData(self.TeamDataList)
end
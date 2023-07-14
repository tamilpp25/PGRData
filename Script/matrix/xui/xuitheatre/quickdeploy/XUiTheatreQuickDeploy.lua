local XUiGridQuickDeployTeam = require("XUi/XUiTheatre/QuickDeploy/XUiGridQuickDeployTeam")

--肉鸽玩法编队调整
local XUiTheatreQuickDeploy = XLuaUiManager.Register(XLuaUi, "UiTheatreQuickDeploy")

function XUiTheatreQuickDeploy:OnAwake()
    self.AdventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
    self.AdventureMultiDeploy = self.AdventureManager:GetAdventureMultiDeploy()
    self.GridQuickDeployTeam.gameObject:SetActiveEx(false)
    self:AutoAddListener()
end

--stageId：TheatreStage表的Id
--teamList：XTheatreTeam的列表
function XUiTheatreQuickDeploy:OnStart(stageId, teamList, saveCb)
    self.TeamList = teamList
    self.StageId = stageId
    self.SaveCb = saveCb

    self.TeamGridList = {}
end

function XUiTheatreQuickDeploy:OnEnable()
    self:UpdateView()
end

function XUiTheatreQuickDeploy:OnDisable()
    self.OldTeamId = nil
    self.OldPos = nil

    if self.LastSelectGrid then
        self.LastSelectGrid:SetSelect(false)
        self.LastSelectGrid = nil
    end
end

function XUiTheatreQuickDeploy:UpdateView()
    local teamList = self.TeamList

    local memberClickCb = function(grid, pos, teamId)
        local grid = grid
        local oldTeamId = self.OldTeamId
        local oldPos = self.OldPos

        --队伍中有关卡进度
        if self.AdventureMultiDeploy:GetMultipleTeamIsWin(oldTeamId)
        or self.AdventureMultiDeploy:GetMultipleTeamIsWin(teamId)
        then
            XUiManager.TipText("StrongholdQuickDeployTeamLock")
            return
        end

        local sucCb = function()
            self:UpdateView()

            grid:ShowEffect()
            self.LastSelectGrid:ShowEffect()
            self.LastSelectGrid:SetSelect(false)
            self.LastSelectGrid = nil

            self.OldTeamId = nil
            self.OldPos = nil
        end

        local failCb = function()
            if self.LastSelectGrid then
                self.LastSelectGrid:SetSelect(false)
            end
            self.LastSelectGrid = grid

            self.LastSelectGrid:SetSelect(true)
            self.OldTeamId = teamId
            self.OldPos = pos
        end

        self:SwapTeamPos(oldTeamId, oldPos, teamId, pos, sucCb, failCb)
    end

    local teamGridList = self.TeamGridList
    local stageCount = XTheatreConfigs.GetTheatreStageCount(self.StageId)
    for index = 1, stageCount do
        local teamGrid = teamGridList[index]
        if not teamGrid then
            local go = XUiHelper.Instantiate(self.GridQuickDeployTeam, self.PanelFormationTeamContent)
            teamGrid = XUiGridQuickDeployTeam.New(go, memberClickCb)
            teamGridList[index] = teamGrid
        end

        local teamId = index
        teamGrid:Refresh(teamList, teamId)
        teamGrid.GameObject:SetActiveEx(true)
    end

    for i = stageCount + 1, #teamGridList do
        teamGridList.GameObject:SetActiveEx(false)
    end
end

function XUiTheatreQuickDeploy:AutoAddListener()
    self.BtnConfirm.CallBack = function() self:OnClickBtnConfirm() end
end

function XUiTheatreQuickDeploy:OnClickBtnConfirm()
    self.SaveCb()
    self:Close()
end

function XUiTheatreQuickDeploy:SwapTeamPos(oldTeamId, oldPos, newTeamId, newPos, sucCb, failCb)
    if not oldTeamId then failCb() return false end

    if oldTeamId == newTeamId and oldPos == newPos then failCb() return false end

    local teamList = self.TeamList

    local oldTeam = teamList[oldTeamId]
    local oldEntityId = oldTeam:GetEntityIdByTeamPos(oldPos)
    local newTeam = teamList[newTeamId]
    local newEntityId = newTeam:GetEntityIdByTeamPos(newPos)

    if not XTool.IsNumberValid(oldEntityId) and not XTool.IsNumberValid(newEntityId) then failCb() return false end

    local oldRole = XDataCenter.TheatreManager.GetCurrentAdventureManager():GetRole(oldEntityId)
    local newRole = XDataCenter.TheatreManager.GetCurrentAdventureManager():GetRole(newEntityId)

    local oldRawId = oldRole and oldRole:GetRawDataId()
    local newRawId = newRole and newRole:GetRawDataId()
    local oldCharacterType = XTool.IsNumberValid(oldRawId) and XEntityHelper.GetCharacterType(oldRawId)
    local newCharacterType = XTool.IsNumberValid(newRawId) and XEntityHelper.GetCharacterType(newRawId)

    local swapFunc = function()
        if oldCharacterType and newTeam:GetCharacterType() ~= oldCharacterType then
            newTeam:ClearEntityIds()
        end
        if newCharacterType and oldTeam:GetCharacterType() ~= newCharacterType then
            oldTeam:ClearEntityIds()
        end

        oldTeam:UpdateEntityTeamPos(newEntityId, oldPos, true)
        newTeam:UpdateEntityTeamPos(oldEntityId, newPos, true)

        sucCb()
    end

    if (oldCharacterType and newTeam:GetCharacterType() ~= oldCharacterType) or (newCharacterType and oldTeam:GetCharacterType() ~= newCharacterType) then
        --队伍中已经存在其他类型的角色（构造体/授格者）
        local content = CSXTextManagerGetText("TeamCharacterTypeNotSame")
        XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, swapFunc)
    else
        swapFunc()
    end
end
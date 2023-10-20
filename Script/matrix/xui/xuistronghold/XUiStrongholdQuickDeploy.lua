local XUiGridQuickDeployTeam = require("XUi/XUiStronghold/XUiGridQuickDeployTeam")

local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiStrongholdQuickDeploy = XLuaUiManager.Register(XLuaUi, "UiStrongholdQuickDeploy")

function XUiStrongholdQuickDeploy:OnAwake()
    self.GridQuickDeployTeam.gameObject:SetActiveEx(false)
    self:AutoAddListener()
end

function XUiStrongholdQuickDeploy:OnStart(groupId, teamList, saveCb)
    ---@type XStrongholdTeam[]
    self.TeamList = teamList
    ---@type XStrongholdTeam[]
    self.RecordTeamList = XTool.Clone(teamList)
    self.GroupId = groupId
    self.SaveCb = saveCb
    self.TeamListClip = XDataCenter.StrongholdManager.GetTeamListClipTemp(groupId, teamList)

    self.TeamGridList = {}
    self.BtnBack.gameObject:SetActiveEx(true)
end

function XUiStrongholdQuickDeploy:OnEnable()

    self:UpdateView()
end

function XUiStrongholdQuickDeploy:OnDisable()

    self.OldTeamId = nil
    self.OldPos = nil

    if self.LastSelectGrid then
        self.LastSelectGrid:SetSelect(false)
        self.LastSelectGrid = nil
    end
end

function XUiStrongholdQuickDeploy:UpdateView()
    local teamList = self.TeamList
    local teamListClip = self.TeamListClip

    local memberClickCb = function(grid, pos, teamId)

        local grid = grid

        local oldTeamId = self.OldTeamId
        local oldPos = self.OldPos

        --队伍中有关卡进度
        local groupId = self.GroupId
        if groupId then
            if XDataCenter.StrongholdManager.IsGroupStageFinished(groupId, oldTeamId)
            or XDataCenter.StrongholdManager.IsGroupStageFinished(groupId, teamId)
            then
                XUiManager.TipText("StrongholdQuickDeployTeamLock")
                return
            end
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
    for index, team in ipairs(teamListClip) do
        local teamGrid = teamGridList[index]
        if not teamGrid then
            local go = CSUnityEngineObjectInstantiate(self.GridQuickDeployTeam, self.PanelFormationTeamContent)
            teamGrid = XUiGridQuickDeployTeam.New(go, memberClickCb)
            teamGridList[index] = teamGrid
        end

        local teamId = index
        teamGrid:Refresh(teamList, teamId, self.GroupId)
        teamGrid.GameObject:SetActiveEx(true)
    end
    for i = #teamListClip + 1, #teamGridList do
        teamGridList.GameObject:SetActiveEx(false)
    end
end

function XUiStrongholdQuickDeploy:AutoAddListener()
    self.BtnConfirm.CallBack = function() self:OnClickBtnConfirm() end
    self:RegisterClickEvent(self.BtnBack, self.OnClickBack)
end

function XUiStrongholdQuickDeploy:OnClickBtnConfirm()
    self.SaveCb()
    self:Close()
end

function XUiStrongholdQuickDeploy:SwapTeamPos(oldTeamId, oldPos, newTeamId, newPos, sucCb, failCb)
    if not oldTeamId then failCb() return false end

    if oldTeamId == newTeamId and oldPos == newPos then failCb() return false end

    local teamList = self.TeamList

    local oldTeam = teamList[oldTeamId]
    local oldMember = XTool.Clone(oldTeam:GetMember(oldPos))
    local newTeam = teamList[newTeamId]
    local newMember = XTool.Clone(newTeam:GetMember(newPos))

    if oldMember:IsEmpty() and newMember:IsEmpty() then failCb() return false end

    local oldCharacterType = oldMember:GetCharacterType()
    local newCharacterType = newMember:GetCharacterType()

    local swapFunc = function()
        if newTeam:ExistDifferentCharacterType(oldCharacterType) then
            newTeam:Clear()
        end
        if oldTeam:ExistDifferentCharacterType(newCharacterType) then
            oldTeam:Clear()
        end

        oldTeam:SetMemberForce(oldPos, newMember)
        newTeam:SetMemberForce(newPos, oldMember)

        sucCb()
    end

    if newTeam:ExistDifferentCharacterType(oldCharacterType)
    or oldTeam:ExistDifferentCharacterType(newCharacterType)
    then
        --队伍中已经存在其他类型的角色（构造体/授格者）
        local content = CSXTextManagerGetText("TeamCharacterTypeNotSame")
        XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, swapFunc)

    else
        swapFunc()
    end

end

function XUiStrongholdQuickDeploy:OnClickBack()
    if self:CheckTeamChange() then
        local extraData = {}
        extraData.sureText = XUiHelper.GetText("StrongholdQuickDeploySave")
        extraData.closeText = XUiHelper.GetText("StrongholdQuickDeployBack")
        XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("StrongholdQuickDeployTitle"), XUiManager.DialogType.Normal, handler(self, self.Close), handler(self, self.OnClickBtnConfirm), extraData)
    end
    self:Close()
end

function XUiStrongholdQuickDeploy:CheckTeamChange()
    for i, oldTeam in ipairs(self.RecordTeamList) do
        local nowTeam = self.TeamList[i]
        if nowTeam:GetCaptainPos() ~= oldTeam:GetCaptainPos() or nowTeam:GetFirstPos() ~= oldTeam:GetFirstPos() then
            return true
        end
        local oldMembers = oldTeam:GetAllMembers()
        local nowMembers = nowTeam:GetAllMembers()
        for j, member in ipairs(oldMembers) do
            if member:GetRoleId() ~= nowMembers[j]:GetRoleId() then
                return true
            end
        end
    end
    return false
end
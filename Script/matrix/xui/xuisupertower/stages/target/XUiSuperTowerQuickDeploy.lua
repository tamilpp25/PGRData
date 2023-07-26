--===========================
--超级爬塔多波关卡快速设置界面
--===========================
local XUiSuperTowerQuickDeploy = XLuaUiManager.Register(XLuaUi, "UiSuperTowerQuickDeploy")
local XUiGridSTQuickDeployTeam = require("XUi/XUiSuperTower/Stages/Target/XUiGridSTQuickDeployTeam")
local XTeam = require("XEntity/XTeam/XTeam")
local CSTextManagerGetText = CS.XTextManager.GetText
local CSObjectInstantiate = CS.UnityEngine.Object.Instantiate
function XUiSuperTowerQuickDeploy:OnStart(stStage, callBack)
    self.STStage = stStage
    self.CallBack = callBack
    self:SetButtonCallBack()
    self.TeamGridList = {}
    self:InitPanel()
end

function XUiSuperTowerQuickDeploy:OnDestroy()

end

function XUiSuperTowerQuickDeploy:OnEnable()
    self:UpdatePanel()
end

function XUiSuperTowerQuickDeploy:OnDisable()
    self.OldStageId = nil
    self.OldPos = nil

    if self.LastSelectGrid then
        self.LastSelectGrid:SetSelect(false)
        self.LastSelectGrid = nil
    end
end

function XUiSuperTowerQuickDeploy:SetButtonCallBack()
    self.BtnConfirm.CallBack = function()
        self:OnBtnConfirmClick()
    end
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
end

function XUiSuperTowerQuickDeploy:InitPanel()
    self.TeamList = {}
    self.TmpTeamList = {}
    local stageIdList = self.STStage:GetStageId()
    for index, stageId in ipairs(stageIdList) do
        local team = XDataCenter.SuperTowerManager.GetTeamByStageId(stageId)
        local tmpTeam = XTeam.New()
        tmpTeam:CopyData(team)
        
        self.TeamList[index] = team
        self.TmpTeamList[index] = tmpTeam
    end
    self.GridQuickDeployTeam.gameObject:SetActiveEx(false)
end

function XUiSuperTowerQuickDeploy:UpdatePanel()
    local stageIdList = self.STStage:GetStageId()
    for index, stageId in ipairs(stageIdList) do
        local teamGrid = self.TeamGridList[index]
        if not teamGrid then
            local go = CSObjectInstantiate(self.GridQuickDeployTeam, self.PanelFormationTeamContent)
            teamGrid = XUiGridSTQuickDeployTeam.New(go, function(grid, pos, stageIndex)
                    self:memberClick(grid, pos, stageIndex)
                end)
            self.TeamGridList[index] = teamGrid
        end
        local tmpTeam = self.TmpTeamList[index]
        teamGrid:Refresh(index, self.STStage, tmpTeam)
        teamGrid.GameObject:SetActiveEx(true)
    end
    for i = #stageIdList + 1, #self.TeamGridList do
        self.TeamGridList[i].GameObject:SetActiveEx(false)
    end

end

function XUiSuperTowerQuickDeploy:memberClick(grid, pos, stageIndex)

    local oldStageIndex = self.OldStageIndex
    local oldPos = self.OldPos

    local sucCb = function()
        self:UpdatePanel()

        grid:ShowEffect()
        self.LastSelectGrid:ShowEffect()
        self.LastSelectGrid:SetSelect(false)
        self.LastSelectGrid = nil

        self.OldStageIndex = nil
        self.OldPos = nil
    end

    local failCb = function()
        if self.LastSelectGrid then
            self.LastSelectGrid:SetSelect(false)
        end
        self.LastSelectGrid = grid

        self.LastSelectGrid:SetSelect(true)
        self.OldStageIndex = stageIndex
        self.OldPos = pos
    end

    self:SwapTeamPos(oldStageIndex, oldPos, stageIndex, pos, sucCb, failCb)
end

function XUiSuperTowerQuickDeploy:SwapTeamPos(oldStageIndex, oldPos, newStageIndex, newPos, sucCb, failCb)
    if not oldStageIndex then failCb() return false end

    if oldStageIndex == newStageIndex and oldPos == newPos then failCb() return false end
    
    local roleManager = XDataCenter.SuperTowerManager.GetRoleManager()
    local oldTeam = self.TmpTeamList[oldStageIndex]
    local oldMemberId = oldTeam:GetEntityIdByTeamPos(oldPos) or 0
    local oldMember = roleManager:GetRole(oldMemberId)
    local newTeam = self.TmpTeamList[newStageIndex]
    local newMemberId = newTeam:GetEntityIdByTeamPos(newPos) or 0
    local newMember = roleManager:GetRole(newMemberId)
    
    if not oldMember and not newMember then failCb() return false end

    local oldCharacterType = oldMember and oldMember:GetCharacterType() or 0
    local newCharacterType = newMember and newMember:GetCharacterType() or 0

    local swapFunc = function()
        if self:ExistDifferentCharacterType(newTeam, oldCharacterType) then
            newTeam:Clear()
        end
        if self:ExistDifferentCharacterType(oldTeam, newCharacterType) then
            oldTeam:Clear()
        end

        oldTeam:UpdateEntityTeamPos(newMemberId, oldPos, true)
        newTeam:UpdateEntityTeamPos(oldMemberId, newPos, true)

        sucCb()
    end

    if self:ExistDifferentCharacterType(newTeam, oldCharacterType)
        or self:ExistDifferentCharacterType(oldTeam, newCharacterType)
        then
        --队伍中已经存在其他类型的角色（构造体/授格者）
        local content = CSXTextManagerGetText("TeamCharacterTypeNotSame")
        XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, swapFunc)
    else
        swapFunc()
    end
end

function XUiSuperTowerQuickDeploy:ExistDifferentCharacterType(team, characterType)
    local roleManager = XDataCenter.SuperTowerManager.GetRoleManager()
    local entityIdList = team:GetEntityIds()
    if characterType > 0 then
        for _,id in pairs(entityIdList) do
            local member = roleManager:GetRole(id)
            if member and member:GetCharacterType() ~= characterType then
                return true
            end
        end
    end
    return false
end

function XUiSuperTowerQuickDeploy:OnBtnConfirmClick()
    local stageIdList = self.STStage:GetStageId()
    for index, stageId in ipairs(stageIdList) do
        local team = self.TeamList[index]
        local tmpTeam = self.TmpTeamList[index]
        team:CopyData(tmpTeam)
    end

    self:Close()
    if self.CallBack then
        self.CallBack()
    end
end

function XUiSuperTowerQuickDeploy:OnBtnCloseClick()
    self:Close()
end
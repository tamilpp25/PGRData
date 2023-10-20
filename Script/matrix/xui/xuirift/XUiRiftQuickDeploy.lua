-- 大秘境 多队伍 快速编队调整界面
local XUiRiftQuickDeploy = XLuaUiManager.Register(XLuaUi, "UiRiftQuickDeploy")
local XUiGridRiftQuickDeployTeam = require("XUi/XUiRift/Grid/XUiGridRiftQuickDeployTeam")

function XUiRiftQuickDeploy:OnAwake()
    self.GridQuickDeployTeam.gameObject:SetActiveEx(false)
    self:AutoAddListener()
end

function XUiRiftQuickDeploy:AutoAddListener()
    self.BtnConfirm.CallBack = function() self:OnClickBtnConfirm() end
end

function XUiRiftQuickDeploy:OnStart(teamList, xStageGroup, saveCb)
    self.TeamList = teamList
    self.XStageGroup = xStageGroup
    self.SaveCb = saveCb

    self.TeamGridList = {}
end

function XUiRiftQuickDeploy:OnEnable()
    self:UpdateView()
end

function XUiRiftQuickDeploy:OnDisable()
    self.OldTeamId = nil
    self.OldPos = nil

    if self.LastSelectGrid then
        self.LastSelectGrid:SetSelect(false)
        self.LastSelectGrid = nil
    end
end

function XUiRiftQuickDeploy:UpdateView()
    local memberClickCb = function(memberGrid, memberPos, teamIndex)
        local grid = memberGrid
        local oldTeamId = self.OldTeamId
        local oldPos = self.OldPos

        --队伍中有关卡进度
        -- if self.XStageGroup:GetAllEntityStages()[index]:CheckHasPassed() then
        --     XUiManager.TipText("StrongholdQuickDeployTeamLock")
        --     return
        -- end
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
            self.OldTeamId = teamIndex
            self.OldPos = memberPos
        end

        self:SwapTeamPos(oldTeamId, oldPos, teamIndex, memberPos, sucCb, failCb)
    end

    for index = 1, #self.XStageGroup:GetAllEntityStages() do
        local teamGrid = self.TeamGridList[index]
        if not teamGrid then
            local go = CS.UnityEngine.Object.Instantiate(self.GridQuickDeployTeam, self.PanelFormationTeamContent)
            teamGrid = XUiGridRiftQuickDeployTeam.New(go, memberClickCb)
            self.TeamGridList[index] = teamGrid
        end

        teamGrid:Refresh(self.TeamList, index)
        teamGrid.GameObject:SetActiveEx(true)
    end
end

function XUiRiftQuickDeploy:OnClickBtnConfirm()
    for k, grid in pairs(self.TeamGridList) do
        grid:SaveCb()
    end
    self.SaveCb(self.TeamList)
    self:Close()
end

function XUiRiftQuickDeploy:SwapTeamPos(oldTeamId, oldPos, newTeamId, newPos, sucCb, failCb)
    if not oldTeamId then failCb() return false end
    if oldTeamId == newTeamId and oldPos == newPos then failCb() return false end

    local teamList = self.TeamList
    local oldTeam = teamList[oldTeamId]
    local newTeam = teamList[newTeamId]

    if XDataCenter.RiftManager.CheckRoleInMultiTeamLock(oldTeam) or XDataCenter.RiftManager.CheckRoleInMultiTeamLock(newTeam) then
        XUiManager.TipError(CS.XTextManager.GetText("StrongholdQuickDeployTeamLock"))
        failCb() 
        return false  
    end

    if oldTeam:CheckIsPosEmpty(oldPos) and newTeam:CheckIsPosEmpty(newPos) then 
        failCb() return false 
    end

    -- 交换位置
    if oldTeam == newTeam then --队内互换用这个接口
        oldTeam:SwitchEntityPos(oldPos, newPos)
    else
        local oldRoleId = oldTeam:GetEntityIdByTeamPos(oldPos)
        local newRoleId = newTeam:GetEntityIdByTeamPos(newPos)
        oldTeam:UpdateEntityTeamPos(newRoleId, oldPos, true)
        newTeam:UpdateEntityTeamPos(oldRoleId, newPos, true)
    end

    sucCb()
end
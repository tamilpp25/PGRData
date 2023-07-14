-- 大秘境 多队伍设置界面
local XUiRiftDeploy = XLuaUiManager.Register(XLuaUi, "UiRiftDeploy")
local XUiGridRiftDeploy = require("XUi/XUiRift/Grid/XUiGridRiftDeploy")

function XUiRiftDeploy:OnAwake()
    self.TeamGrids = {}
    self.EnterStageIndex = nil -- 这个字段用来检测当前第一个没通关的stage是列表中的第几个
    self:InitButton()
    self:InitTimes()
    self:AutoCheckTemplate()

    self.GridDeployTeam.gameObject:SetActiveEx(false)
end

function XUiRiftDeploy:InitButton()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
    self.BtnQuickDeploy.CallBack = function() self:OnBtnQuickDeployClick() end
    self.BtnAttr.CallBack = function() XLuaUiManager.Open("UiRiftAttribute") end
    self.BtnFight.CallBack = function() self:OnClickBtnFight() end
end

-- 32版本临时：检测线上玩家模板异常
function XUiRiftDeploy:AutoCheckTemplate()
    for teamId, xTeam in pairs(XDataCenter.RiftManager.GetMultiTeamData()) do
        local tempId = xTeam:GetAttrTemplateId()
        local temp = XDataCenter.RiftManager.GetAttrTemplate(tempId)
        if temp:IsEmpty() and tempId ~=  XRiftConfig.DefaultAttrTemplateId then
            XDataCenter.RiftManager.RiftSetTeamRequest(xTeam, XRiftConfig.DefaultAttrTemplateId)
        end
    end
end

function XUiRiftDeploy:OnStart(xStageGroup)
    self.XStageGroup = xStageGroup
    self.TeamList = XDataCenter.RiftManager.GetMultiTeamData()
end

function XUiRiftDeploy:OnEnable()
    self.Super.OnEnable(self)
    local doEnterFightFun = XDataCenter.RiftManager.GetIsEnterNextFightTrigger()
    if doEnterFightFun then
        doEnterFightFun()
        return
    end

    self:UpdateTeamList()
end

function XUiRiftDeploy:UpdateTeamList()
    local teamList = self.TeamList
    local xStageList = self.XStageGroup:GetAllEntityStages()
    for index = 1, #xStageList do
        local grid = self.TeamGrids[index]
        if not grid then
            local go = CS.UnityEngine.Object.Instantiate(self.GridDeployTeam, self.PanelTeamContent)
            grid = XUiGridRiftDeploy.New(go, self)
            self.TeamGrids[index] = grid
        end
        local xTeam = teamList[index]
        grid:Refresh(xTeam, self.XStageGroup, index)
        grid.GameObject:SetActiveEx(true)
        local xStage = xStageList[index]
        if not self.EnterStageIndex and not xStage:CheckHasPassed() then
            self.EnterStageIndex = index
        end
    end
end

function XUiRiftDeploy:OnBtnQuickDeployClick()
    local cloneTeamList = XTool.Clone(self.TeamList)
    for i, xCloneTeam in pairs(cloneTeamList) do
        xCloneTeam:UpdateAutoSave(false) -- 克隆的临时队伍，修改时不要自动保存到本地
    end
    local saveCb = function(afterChangeTeamList)
        for i, xCloneTeam in pairs(afterChangeTeamList) do
            xCloneTeam:UpdateAutoSave(true) -- 保存。将修改的克隆队伍赋值给自己的真实队伍，并开启保存功能，且先保存一次
            xCloneTeam:Save()
        end
        XDataCenter.RiftManager.ChangeMultiTeamData(afterChangeTeamList)
        self.TeamList = afterChangeTeamList
        self:UpdateTeamList()
    end
    XLuaUiManager.Open("UiRiftQuickDeploy", cloneTeamList, self.XStageGroup, saveCb)
end

function XUiRiftDeploy:OnClickBtnFight()
    if not self.EnterStageIndex then
        return
    end
    -- 检测队伍是否都有队长
    local xStageList = self.XStageGroup:GetAllEntityStages()
    local teamList = self.TeamList
    for index = 1, #xStageList do
        local xTeam = teamList[index]
        local captainRoleId = xTeam:GetCaptainPosEntityId()
        if not XTool.IsNumberValid(captainRoleId) then
            XUiManager.TipText("StrongholdEnterFightTeamListNoCaptain")
            return
        end

        local firstRoleId = xTeam:GetFirstFightPosEntityId()
        if not XTool.IsNumberValid(firstRoleId) then
            XUiManager.TipText("StrongholdEnterFightTeamListNoFirstPos")
            return
        end
    end
    
    local xCurTeam = teamList[self.EnterStageIndex]
    XDataCenter.RiftManager.EnterFight(xCurTeam)
end

function XUiRiftDeploy:OnClickBtnBack()
    self:Close()
end

function XUiRiftDeploy:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiRiftDeploy:OnDestroy()
    for _, grid in pairs(self.TeamGrids) do
        if grid.OnDestroy then
            grid:OnDestroy()
        end
    end
end

function XUiRiftDeploy:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.RiftManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end
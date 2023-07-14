--===========================
--超级爬塔多波关卡准备界面
--===========================
local XUiGridTargetStageTeam = require("XUi/XUiSuperTower/Stages/Target/XUiGridTargetStageTeam")
local XUiSuperTowerDeploy = XLuaUiManager.Register(XLuaUi, "UiSuperTowerDeploy")
local CSTextManagerGetText = CS.XTextManager.GetText
local CSObjectInstantiate = CS.UnityEngine.Object.Instantiate
local StartIndex = 1
function XUiSuperTowerDeploy:OnStart(stStage)
    self.STStage = stStage
    self:SetButtonCallBack()
    self.TeanGrids = {}
    self.GridDeployTeam.gameObject:SetActiveEx(false)
    self:ClearTeamExtraData()
    local endTime = XDataCenter.SuperTowerManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.SuperTowerManager.HandleActivityEndTime()
        end
    end)
end

function XUiSuperTowerDeploy:OnDestroy()

end

function XUiSuperTowerDeploy:OnEnable()
    XUiSuperTowerDeploy.Super.OnEnable(self)
    self:UpdatePanel()
end

function XUiSuperTowerDeploy:OnDisable()
    XUiSuperTowerDeploy.Super.OnDisable(self)
end

function XUiSuperTowerDeploy:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnFight.CallBack = function()
        self:OnBtnFightClick()
    end
    self.BtnAutoTeam.CallBack = function()
        self:OnBtnAutoTeamClick()
    end
    self.BtnQuickDeploy.CallBack = function()
        self:OnBtnQuickDeployClick()
    end
    self.BtnAutoPulgin.CallBack = function()
        self:OnBtnAutoPulginClick()
    end
end

function XUiSuperTowerDeploy:UpdatePanel()
    self:UpdatePaneTeam()
end

function XUiSuperTowerDeploy:UpdatePaneTeam()
    local stageIdList = self.STStage:GetStageId()

    for index,stageId in pairs(stageIdList) do
        local grid = self.TeanGrids[index]
        if not grid then
            local go = CSObjectInstantiate(self.GridDeployTeam, self.PanelTeamContent)
            grid = XUiGridTargetStageTeam.New(go)
            self.TeanGrids[index] = grid
        end
        grid:UpdataGrid(index, self.STStage)
        grid.GameObject:SetActiveEx(true)
    end

    for index = #stageIdList + 1, #self.TeanGrids do
        self.TeanGrids[index].GameObject:SetActiveEx(false)
    end
end

function XUiSuperTowerDeploy:OnBtnBackClick()
    self:Close()
end

function XUiSuperTowerDeploy:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiSuperTowerDeploy:OnBtnFightClick()
    if not XDataCenter.SuperTowerManager.CheckActivityIsInTime() then
        XUiManager.TipText("STOverTimeHint")
        self:OnBtnMainUiClick()
        return
    end

    --检查队伍列表中所有需要的队伍是否均有队长/首发
    local allHasCaptain, allHasFirstPos = XDataCenter.SuperTowerManager.CheckTeamListAllHasCaptainAndFirstPos(self.STStage)
    if not allHasCaptain then
        XUiManager.TipText("STMultiTeamTeamListNoCaptain")
        return
    end
    if not allHasFirstPos then
        XUiManager.TipText("STMultiTeamTeamListNoFirstPos")
        return
    end

    local targetStageId = self.STStage:GetStageId()[StartIndex]
    local teamList = {}
    for index,stageId in pairs(self.STStage:GetStageId() or {}) do
        local team = stageId and XDataCenter.SuperTowerManager.GetTeamByStageId(stageId)
        teamList[index] = team
    end

    XDataCenter.SuperTowerManager.GetStageManager():ResetTempProgress()
    XDataCenter.SuperTowerManager.GetTeamManager():SetTargetFightTeam(teamList, targetStageId, function()
            XDataCenter.SuperTowerManager.EnterFight(targetStageId)
            self:Close()
        end)
    
end

function XUiSuperTowerDeploy:OnBtnAutoTeamClick()
    XDataCenter.SuperTowerManager.AutoTeam(self.STStage)
    self:UpdatePanel()
end

function XUiSuperTowerDeploy:OnBtnQuickDeployClick()
    XLuaUiManager.Open("UiSuperTowerQuickDeploy", self.STStage, function ()
            self:UpdatePanel()
    end)    
end

function XUiSuperTowerDeploy:OnBtnAutoPulginClick()
    XDataCenter.SuperTowerManager.AutoPulgin(self.STStage)
    self:UpdatePanel()
end

function XUiSuperTowerDeploy:ClearTeamExtraData()
    --获取目标关卡的所有关卡
    local stageIds = self.STStage:GetStageId()
    --获取所有对应队伍，清除其插件纪录
    for index, stageId in pairs(stageIds) do
        local team = XDataCenter.SuperTowerManager.GetTeamByStageId(stageId)
        local extraData = team:GetExtraData()
        if extraData then extraData:Clear() end
    end
end
local XUiGridDeployTeam = require("XUi/XUiTheatre/MultiDeploy/XUiGridDeployTeam")

local CsXTextManagerGetText = CsXTextManagerGetText

local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.red,
    [false] = CS.UnityEngine.Color.black,
}

-- 肉鸽玩法多队伍编队界面
local XUiTheatreDeploy = XLuaUiManager.Register(XLuaUi, "UiTheatreDeploy")

function XUiTheatreDeploy:OnAwake()
    self.TeamGrids = {}
    self:AutoAddListener()

    self.GridDeployTeam.gameObject:SetActiveEx(false)
    self.AdventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
    self.AdventureMultiDeploy = self.AdventureManager:GetAdventureMultiDeploy()
    self:InitPanelTool()
end

function XUiTheatreDeploy:OnStart(theatreStageId)
    self.TheatreStageId = theatreStageId
    self.AdventureMultiDeploy:ClipMembers(XTheatreConfigs.GetTheatreStageCount(theatreStageId))
    self.TeamList = self.AdventureMultiDeploy:GetTeamList()
end

function XUiTheatreDeploy:OnEnable()
    self:Refresh()
end

function XUiTheatreDeploy:OnDestroy()
    for _, grid in pairs(self.TeamGrids) do
        if grid.OnDestroy then
            grid:OnDestroy()
        end
    end
end

function XUiTheatreDeploy:OnReleaseInst()
    return {CurrBattleIndex = self.CurrBattleIndex, TheatreStageId = self.TheatreStageId}
end

function XUiTheatreDeploy:OnResume(datas)
    self.CurrBattleIndex = datas.CurrBattleIndex
    self.TheatreStageId = datas.TheatreStageId
end

function XUiTheatreDeploy:InitPanelTool()
    self.RImgTool.gameObject:SetActiveEx(false)
end

function XUiTheatreDeploy:Refresh()
    self:UpdateTeamList()
    self:UpdatePanelTool()
end

function XUiTheatreDeploy:UpdatePanelTool()
    self.TxtTool.text = XUiHelper.GetText("TheatreRestartCount", self.AdventureManager:GetPlayableCount())  --剩余重开次数
end

function XUiTheatreDeploy:UpdateTeamList()
    local theatreStageId = self.TheatreStageId

    local stageCount = XTheatreConfigs.GetTheatreStageCount(theatreStageId)
    for index = 1, stageCount do
        local grid = self.TeamGrids[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridDeployTeam, self.PanelTeamContent)
            grid = XUiGridDeployTeam.New(go, self)
            self.TeamGrids[index] = grid
        end

        grid:Refresh(index, theatreStageId)
        grid.GameObject:SetActiveEx(true)
    end

    for index = stageCount + 1, #self.TeamGrids do
        local grid = self.TeamGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end
end

function XUiTheatreDeploy:AutoAddListener()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
    self.BtnFormation.CallBack = function() self:OnClickBtnFormation() end
    self.BtnFight.CallBack = function() self:OnClickBtnFight() end
    self.BtnAutoTeam.CallBack = function() self:OnClickBtnAutoTeam() end
    self.BtnElectricTips.CallBack = function() self:OnClickBtnTool() end
    self.BtnTool.CallBack = function() self:OnClickBtnTool() end
end

function XUiTheatreDeploy:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiTheatreDeploy:OnClickBtnFormation()
    if self.AdventureMultiDeploy:CheckMultipleTeamEmpty() then
        XUiManager.TipText("StrongholdDeployQucikDeployEmpty")
        return
    end

    local cb = function()
        self:UpdateTeamList()
    end
    XLuaUiManager.Open("UiTheatreQuickDeploy", self.TheatreStageId, self.TeamList, cb)
end

function XUiTheatreDeploy:OnClickBtnFight()
    local theatreStageId = self.TheatreStageId
    local nextBattleIndex = self.AdventureMultiDeploy:GetNextBattleIndex()
    self.CurrBattleIndex = nextBattleIndex

    if not XTool.IsNumberValid(nextBattleIndex) then
        return
    end
    self.AdventureMultiDeploy:RequestSetMultiTeam(function()
        XDataCenter.TheatreManager.SetAutoMultiFight(true)
        XDataCenter.TheatreManager.SetCurFightStageIndex(nextBattleIndex)
        self.AdventureManager:EnterFight(theatreStageId, nextBattleIndex)
    end, theatreStageId)
end

function XUiTheatreDeploy:OnClickBtnAutoTeam()
    self.AdventureMultiDeploy:AutoTeam(self.TeamList)
    self:UpdateTeamList()
end

function XUiTheatreDeploy:OnClickBtnTool()
    local helpDataKey = XDataCenter.TheatreManager.GetReopenHelpKey()
    XUiManager.ShowHelpTip(helpDataKey)
end
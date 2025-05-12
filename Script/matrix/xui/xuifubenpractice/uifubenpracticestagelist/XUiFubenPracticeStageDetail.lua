local XUiGridStageStar = require("XUi/XUiFubenMainLineDetail/XUiGridStageStar")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
--- UiFubenPracticeStageListRoot的子界面，关卡详情页
local XUiFubenPracticeStageDetail = XLuaUiManager.Register(XLuaUi, "UiFubenPracticeStageDetail")
local DescCount = 3

function XUiFubenPracticeStageDetail:OnAwake()
    self.StarGridList = {}
    self:InitStarPanels()
    self.GridList = {}
    self.BtnEnter.CallBack = function() self:OnBtnEnterClick() end
    self.GridCommon.gameObject:SetActiveEx(false)
    self.TextAT.gameObject:SetActiveEx(false)
    self.TxtATNums.gameObject:SetActiveEx(false)
end

function XUiFubenPracticeStageDetail:OnStart(rootUi)
    self.RootUi = rootUi
end

function XUiFubenPracticeStageDetail:InitStarPanels()
    for i = 1, DescCount do
        self.StarGridList[i] = XUiGridStageStar.New(self[string.format("GridStageStar%d", i)])
    end
end

function XUiFubenPracticeStageDetail:SetStageDetail(stageId, id)
    self.Id = id
    self.StageId = stageId
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    self.TxtTitle.text = self.StageCfg.Description
    for i = 1, DescCount do
        self.StarGridList[i]:Refresh(self.StageCfg.StarDesc[i], true)
    end
    self:UpdateRewards()
    XLuaUiManager.SetMask(true)
    self:PlayAnimation("AnimBegin", function()
            XLuaUiManager.SetMask(false)
        end)
end

function XUiFubenPracticeStageDetail:UpdateRewards()
    local rewardId = self.StageCfg.FirstRewardShow
    if rewardId == 0 then
        for i = 1, #self.GridList do
            self.GridList[i].GameObject:SetActiveEx(false)
        end
        return
    end

    local rewards = XRewardManager.GetRewardList(rewardId)
    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                grid = XUiGridCommon.New(self, ui)
                grid.Transform:SetParent(self.PanelDropContent, false)
                self.GridList[i] = grid
            end
            grid:Refresh(item)
            grid:SetReceived(XDataCenter.FubenNewCharActivityManager.CheckStagePass(self.StageId))
            grid.GameObject:SetActiveEx(true)
        end
    end
end

function XUiFubenPracticeStageDetail:OnBtnEnterClick()
    --判断是否结束
    local activityCfg = XFubenNewCharConfig.GetDataById(self.Id)
    local endTime = XFunctionManager.GetEndTimeByTimeId(activityCfg.TimeId)
    local nowTime = XTime.GetServerNowTimestamp()
    if nowTime > endTime then
        XUiManager.TipText("KoroCharacterActivityEnd")
        XLuaUiManager.RunMain()
        return
    end

    if XDataCenter.FubenManager.CheckPreFight(self.StageCfg) then
        if self.RootUi then
            self.RootUi:ClearNodesSelect()
        end
        self.RootUi:CloseStageDetails()
        --self:Close() 
        XLuaUiManager.Open("UiBattleRoleRoom", self.StageCfg.StageId
        , XDataCenter.TeamManager.GetXTeamByStageId(self.StageCfg.StageId)
        , require("XUi/XUiNewChar/XUiTutoriaBattleRoleRoom"))
    end
end

function XUiFubenPracticeStageDetail:CloseDetailWithAnimation()
    XLuaUiManager.SetMask(true)
    self:PlayAnimation("AnimEnd", function()
            XLuaUiManager.SetMask(false)
            self:Close()
        end)
end

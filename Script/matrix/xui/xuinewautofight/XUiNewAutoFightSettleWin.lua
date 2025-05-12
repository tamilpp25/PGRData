local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridWinRole = require("XUi/XUiSettleWin/XUiGridWinRole")
local XUiPanelExpBar = require("XUi/XUiSettleWinMainLine/XUiPanelExpBar")
local XUiGridAutoFightRewardLine = require("XUi/XUiNewAutoFight/XUiGridAutoFightRewardLine")

local XUiNewAutoFightSettleWin = XLuaUiManager.Register(XLuaUi, "UiNewAutoFightSettleWin")

function XUiNewAutoFightSettleWin:OnAwake()
    self:InitComponent()
    self:InitDynamicTable()
end

function XUiNewAutoFightSettleWin:OnStart(beginData, winData)
    if beginData == nil or winData == nil then
        self:OnAnimationDone()
        return
    end

    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(beginData.StageId)
    self.Count = beginData.Times
    self.BeginData = beginData
    self.WinData = winData

    self:InitInfo()
end

function XUiNewAutoFightSettleWin:InitComponent()
    self.BtnConfirm.gameObject:SetActiveEx(false)
    self.BtnConfirm.CallBack = function() self:OnBtnConfirmClick() end
end

function XUiNewAutoFightSettleWin:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelRewards)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridAutoFightRewardLine)
    self.GridRewardLine.gameObject:SetActiveEx(false)
end

function XUiNewAutoFightSettleWin:UpdateDynamicTable(rewardLineList)
    self.RewardLineList = rewardLineList
    self.IsListCompleted = false
    self.GridCount = #self.RewardLineList
    self.DynamicTable:SetDataSource(self.RewardLineList)
    self.DynamicTable:ReloadDataSync()
end

function XUiNewAutoFightSettleWin:InitInfo()
    self.TxtStageName.text = XDataCenter.FubenManager.GetStageName(self.BeginData.StageId)

    self:InitRewardCharacterList(self.BeginData.CharExp)
    self:UpdatePlayerInfo(self.BeginData)

    local sweepRewards = self.WinData.SweepRewards
    if not sweepRewards or next(sweepRewards) == nil then
        self:OnAnimationDone()
    else
        self:UpdateDynamicTable(sweepRewards)
    end
end

-- 角色奖励列表
function XUiNewAutoFightSettleWin:InitRewardCharacterList(charExps)
    self.GridWinRole.gameObject:SetActive(false)
    if self.StageCfg.RobotId and #self.StageCfg.RobotId > 0 then
        for i = 1, #self.StageCfg.RobotId do
            if self.StageCfg.RobotId[i] > 0 then
                local ui = CS.UnityEngine.Object.Instantiate(self.GridWinRole)
                local grid = XUiGridWinRole.New(self, ui)
                grid.Transform:SetParent(self.PanelRoleContent, false)
                grid:UpdateRobotInfo(self.StageCfg.RobotId[i])
                grid.GameObject:SetActive(true)
            end
        end
    else
        local count = #charExps
        if count <= 0 then
            return
        end

        for _, exp in pairs(charExps) do
            local ui = CS.UnityEngine.Object.Instantiate(self.GridWinRole)
            local grid = XUiGridWinRole.New(self, ui)
            grid.Transform:SetParent(self.PanelRoleContent, false)
            local cardExp = XDataCenter.FubenManager.GetCardExp(self.StageCfg.StageId, true)
            grid:UpdateRoleInfo(exp, cardExp * self.Count)
            grid.GameObject:SetActive(true)
        end
    end
end

-- 玩家经验
function XUiNewAutoFightSettleWin:UpdatePlayerInfo(data)
    if not data or not next(data) then return end

    local lastLevel = data.RoleLevel
    local lastExp = data.RoleExp
    local lastMaxExp = XPlayerManager.GetMaxExp(lastLevel, XPlayer.IsHonorLevelOpen())
    local curLevel = XPlayer.GetLevelOrHonorLevel()
    local curExp = XPlayer.Exp
    local curMaxExp = XPlayerManager.GetMaxExp(curLevel, XPlayer.IsHonorLevelOpen())
    local txtLevelName = XPlayer.IsHonorLevelOpen() and CS.XTextManager.GetText("HonorLevel") or nil

    local teamExp = XDataCenter.FubenManager.GetTeamExp(self.StageCfg.StageId, true)
    local addExp = teamExp * self.Count
    self.PlayerExpBar = self.PlayerExpBar or XUiPanelExpBar.New(self.PanelPlayerExpBar)
    self.PlayerExpBar:LetsRoll(lastLevel, lastExp, lastMaxExp, curLevel, curExp, curMaxExp, addExp, txtLevelName)
end

function XUiNewAutoFightSettleWin:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rewardGoodsList = self.RewardLineList[index]
        grid:Refresh(rewardGoodsList, index, self.IsListCompleted)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self.IsListCompleted = true

        local grids = self.DynamicTable:GetGrids()
        self.GridIndex = 1
        self.CurAnimationTimer = XScheduleManager.Schedule(function()
            local item = grids[self.GridIndex]
            if item then
                item:Show()
            end
            self.GridIndex = self.GridIndex + 1
            if self.GridIndex > self.GridCount then
                self:OnAnimationDone()
                self:StopSchedule()
            end
        end, 0, self.GridCount, 0)
    end
end

function XUiNewAutoFightSettleWin:OnAnimationDone()
    self.BtnConfirm.gameObject:SetActiveEx(true)
    XDataCenter.FunctionEventManager.UnLockFunctionEvent()
end

function XUiNewAutoFightSettleWin:OnBtnConfirmClick()
    self:Close()
end

function XUiNewAutoFightSettleWin:StopSchedule()
    if self.CurAnimationTimer then
        XScheduleManager.UnSchedule(self.CurAnimationTimer)
        self.CurAnimationTimer = nil
    end
end

function XUiNewAutoFightSettleWin:OnDisable()
    self:StopSchedule()
end
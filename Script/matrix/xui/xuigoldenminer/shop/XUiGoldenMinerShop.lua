local XUiShopGrid = require("XUi/XUiGoldenMiner/Shop/XUiShopGrid")
local XUiItemPanel = require("XUi/XUiGoldenMiner/Panel/XUiItemPanel")
local XUiBuffPanel = require("XUi/XUiGoldenMiner/Panel/XUiBuffPanel")

local BtnGroupType = {
    BuyItem = 1,
    LevelUp = 2,
}

--黄金矿工商店界面
local XUiGoldenMinerShop = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerShop")

function XUiGoldenMinerShop:OnAwake()
    self.DataDb = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
    self:RegisterButtonEvent()
    self:InitDynamicList()
    self:InitBtnGroup()
    self.ItemPanel = XUiItemPanel.New(self.PanelSkillParent)
    self.BuffPanel = XUiBuffPanel.New(self.PanelBuffParent, self, handler(self, self.ShowBuffTips))
    self.TextCurScoreChange.gameObject:SetActiveEx(false)
    self.BtnTipsClose.gameObject:SetActiveEx(false)
end

function XUiGoldenMinerShop:OnStart()
    self.CurStageId = self.DataDb:GetCurStageId()
    self.PanelTabBtn:SelectIndex(BtnGroupType.BuyItem)
    self:InitTimes()
    self:CloseBuffTips()
end

function XUiGoldenMinerShop:OnEnable()
    XUiGoldenMinerShop.Super.OnEnable(self)
    self:Refresh()
end

function XUiGoldenMinerShop:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.GoldenMinerManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XDataCenter.GoldenMinerManager.HandleActivityEndTime()
            return
        end
    end, nil, 0)
end

function XUiGoldenMinerShop:InitBtnGroup()
    self.BtnGroupData = {
        self.DataDb:GetMinerShopDbs(true),
        XGoldenMinerConfigs.GetUpgradeLocalIdList()
    }
    self.CurSelectBtnIndex = nil

    local btnGroup = {
        self.BtnBuyItem,
        self.BtnLevelUp,
    }
    self.PanelTabBtn:Init(btnGroup, function(index) self:OnSelectButton(index) end)
end

function XUiGoldenMinerShop:InitDynamicList()
    local buyCb = handler(self, self.Refresh)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiShopGrid, self, buyCb)
    self.DynamicTable:SetDelegate(self)
    self.GridShop.gameObject:SetActiveEx(false)
end

function XUiGoldenMinerShop:Refresh()
    self.TextTargetScore.text = XUiHelper.GetText("GoldenMinerShopTargetScore", self.DataDb:GetCurStageTargetScore())
    self:UpdateTextCurScore()
    self.ItemPanel:UpdateItemColumns()
    self.BuffPanel:UpdateBuff()
    self.DynamicTable:ReloadDataSync()
end

function XUiGoldenMinerShop:UpdateTextCurScore()
    local score = self.DataDb:GetStageScores()
    if not self.OriginScore then
        self.OriginScore = score
        self.TextCurScore.text = XUiHelper.GetText("GoldenMinerPlayCurScore", score)
    elseif self.OriginScore ~= score then
        self:PlayCurScoreChangeAnima(self.OriginScore - score, self.OriginScore)
        self.OriginScore = score
    end
end

function XUiGoldenMinerShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local curSelectBtnIndex = self.CurSelectBtnIndex
        local itemId = (curSelectBtnIndex == BtnGroupType.BuyItem and not XTool.IsTableEmpty(self.DataList[index]) and self.DataList[index]:GetGoldItemId()) or 0
        local upgradeLocalId = curSelectBtnIndex == BtnGroupType.LevelUp and self.DataList[index]
        grid:Refresh(itemId, upgradeLocalId, index)
    end
end

function XUiGoldenMinerShop:OnSelectButton(index)
    if self.CurSelectBtnIndex == index then
        return
    end
    self.CurSelectBtnIndex = index
    self.DataList = self.BtnGroupData[index]
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataSync(1)
    -- self:PlayAnimation("QieHuan")
end

function XUiGoldenMinerShop:RegisterButtonEvent()
    self:RegisterClickEvent(self.BtnEnterNextStage, self.OnBtnEnterNextStageClick)
    self:RegisterClickEvent(self.BtnTipsClose, self.CloseBuffTips)
end

function XUiGoldenMinerShop:OnBtnEnterNextStageClick()
    local stageId = self.DataDb:GetCurStageId()
    XDataCenter.GoldenMinerManager.RequestGoldenMinerEnterStage(stageId, function()
        XLuaUiManager.PopThenOpen("UiGoldenMinerBattle")
    end)
end

function XUiGoldenMinerShop:PlayCurScoreChangeAnima(changeScore, originScore)
    self.TextCurScoreChange.text = -changeScore
    self.TextCurScoreChange.gameObject:SetActiveEx(true)
    self:PlayAnimation("NumberEnable")
    self:StopCurScoreChangeAnima()

    local scores = self.DataDb:GetStageScores()
    self.CurScoreChangeAnima = XUiHelper.Tween(1, function(f)
        self.TextCurScore.text = XUiHelper.GetText("GoldenMinerPlayCurScore", math.floor(originScore - changeScore * f))
    end, function()
        self.TextCurScoreChange.gameObject:SetActiveEx(false)
        self.TextCurScore.text = XUiHelper.GetText("GoldenMinerPlayCurScore", self.DataDb:GetStageScores())
    end)
end

function XUiGoldenMinerShop:StopCurScoreChangeAnima()
    if self.CurScoreChangeAnima then
        XScheduleManager.UnSchedule(self.CurScoreChangeAnima)
        self.CurScoreChangeAnima = nil
    end
end

function XUiGoldenMinerShop:ShowBuffTips(buffId)
    self.TxtTips.text = XGoldenMinerConfigs.GetBuffDesc(buffId)
    self.PanelTips.gameObject:SetActiveEx(true)
    self:PlayAnimation("PanelTipsEnable")
    self.BtnTipsClose.gameObject:SetActiveEx(true)
end

function XUiGoldenMinerShop:CloseBuffTips()
    self:PlayAnimation("PanelTipsDisable")
    self.BtnTipsClose.gameObject:SetActiveEx(false)
end
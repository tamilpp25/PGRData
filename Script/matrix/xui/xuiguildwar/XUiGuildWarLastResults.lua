local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
-- 轮次结算界面
local XUiGuildWarLastResults = XLuaUiManager.Register(XLuaUi, "UiGuildWarLastResults")

function XUiGuildWarLastResults:OnAwake()
    self.GuildWarManager = XDataCenter.GuildWarManager
    self.CloseCallBack = nil
    -- 奖励列表
    self.DynamicTable = XDynamicTableNormal.New(self.RewardList)
    self.DynamicTable:SetProxy(XUiGridCommon)
    self.DynamicTable:SetDelegate(self)
    self.GridReward.gameObject:SetActiveEx(false)
    self.RewardDatas = nil
    self:RegisterUiEvents()
end

-- settleData : XGuildWarSettleData
function XUiGuildWarLastResults:OnStart(settleData, closeCallBack)
    self.CloseCallBack = closeCallBack
    self.TxtTitle.text = self.GuildWarManager.GetDifficultyName(settleData.DifficultyId)
    self.TxtTotalTime.text = XUiHelper.GetTime(settleData.PassUseSecond, XUiHelper.TimeFormatType.DAY_HOUR)
    self.TxtTotalActivation.text = settleData.TotalActivation
    self.TxtSelfActivation.text = settleData.PlayerActivation
    self.TxtSelfScore.text = settleData.PlayerPoints
    self.TxtTip.text = settleData.IsPass > 0 and XUiHelper.GetText("GuildWarSettleTipWin") 
        or XUiHelper.GetText("GuildWarSettleTipLose")
    -- 奖励数据
    local rewardId = self.GuildWarManager.GetRoundSettleReward(settleData.DifficultyId, settleData.IsPass)
    self.RewardDatas = XRewardManager.GetRewardList(rewardId) or {}
    self.DynamicTable:SetDataSource(self.RewardDatas)
    self.DynamicTable:ReloadDataSync(1)
end

--######################## 私有方法 ########################

function XUiGuildWarLastResults:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

function XUiGuildWarLastResults:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.RewardDatas[index])
    end
end

function XUiGuildWarLastResults:Close()
    if self.CloseCallBack then
        self.CloseCallBack()
    end
    XUiGuildWarLastResults.Super.Close(self)
end

return XUiGuildWarLastResults
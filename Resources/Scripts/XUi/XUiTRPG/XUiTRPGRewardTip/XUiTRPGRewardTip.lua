local XUiTRPGRewardGrid = require("XUi/XUiTRPG/XUiTRPGRewardTip/XUiTRPGRewardGrid")

--领取奖励弹窗
local XUiTRPGRewardTip = XLuaUiManager.Register(XLuaUi, "UiTRPGRewardTip")

function XUiTRPGRewardTip:OnAwake()
    self:AutoAddListener()
    self.GridPrequelCheckPointReward.gameObject:SetActiveEx(false)
end

function XUiTRPGRewardTip:OnStart(rewardIdList, truthRoadGroupId, secondMainId)
    self.RewardIdList = rewardIdList
    self.TruthRoadGroupId = truthRoadGroupId
    self.SecondMainId = secondMainId
    self:InitDynamicTable()
    self:Refresh()
end

function XUiTRPGRewardTip:AutoAddListener()
    self:RegisterClickEvent(self.BtnMask, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
end

function XUiTRPGRewardTip:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewRewardList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiTRPGRewardGrid, self, self.TruthRoadGroupId, self.SecondMainId)
end

function XUiTRPGRewardTip:Refresh()
    self.DynamicTable:SetDataSource(self.RewardIdList)
    self.DynamicTable:ReloadDataSync()
end

function XUiTRPGRewardTip:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rewardId = self.RewardIdList[index]
        grid:Refresh(rewardId)
    end
end
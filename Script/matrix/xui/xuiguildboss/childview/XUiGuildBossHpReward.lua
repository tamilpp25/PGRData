local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGuildBossHpReward = XClass(nil, "XUiGuildBossHpReward")
local XUiGuildBossHpRewardItem = require("XUi/XUiGuildBoss/Component/XUiGuildBossHpRewardItem")

function XUiGuildBossHpReward:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiGuildBossHpReward:InitComponent()
    self.BtnClose.CallBack = function() self:Close() end

    self.GridReward.gameObject:SetActiveEx(false)
    self.RewardDynamicTable = XDynamicTableNormal.New(self.RewardDynamicTable)
    self.RewardDynamicTable:SetProxy(XUiGuildBossHpRewardItem, self.RootUi)
    self.RewardDynamicTable:SetDelegate(self)
end

function XUiGuildBossHpReward:Show()
    self.GameObject:SetActiveEx(true)
    self:Refresh()
    XDataCenter.UiPcManager.OnUiEnable(self)
end

function XUiGuildBossHpReward:Close()
    self.GameObject:SetActiveEx(false)
    self.RootUi.Effect.gameObject:SetActiveEx(self.RootUi.IsShowEffect)
    XDataCenter.UiPcManager.OnUiDisableAbandoned(true, self)
end


function XUiGuildBossHpReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.RewardIdList[index], index)
    end
end

-- override
function XUiGuildBossHpReward:Refresh()
    self.RewardIdList = XGuildBossConfig.GeHpRewardIdList()
    self.RewardDynamicTable:SetDataSource(self.RewardIdList)
    self.RewardDynamicTable:ReloadDataASync()
end

return XUiGuildBossHpReward
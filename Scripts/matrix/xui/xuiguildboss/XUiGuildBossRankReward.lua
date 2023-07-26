local XUiGuildBossRankReward = XLuaUiManager.Register(XLuaUi, "UiGuildBossRankReward")
local XUiGuildBossRankRewardItem = require("XUi/XUiGuildBoss/Component/XUiGuildBossRankRewardItem")

function XUiGuildBossRankReward:OnAwake()
    self:InitComponent()
end

function XUiGuildBossRankReward:OnStart()

end

function XUiGuildBossRankReward:OnDestroy()

end

function XUiGuildBossRankReward:InitComponent()
    self.TxtTitle.text = CS.XTextManager.GetText("GuildBossRankRewardTitle")
    self.TxtDesc.text = CS.XTextManager.GetText("GuildBossRankRewardDesc")
    
    self.BtnClose.CallBack = function() self:Close() end
    
    self.GridRankReward.gameObject:SetActiveEx(false)
    self.RewardDynamicTable = XDynamicTableNormal.New(self.RankRewardList)
    self.RewardDynamicTable:SetProxy(XUiGuildBossRankRewardItem, self)
    self.RewardDynamicTable:SetDelegate(self)
end

function XUiGuildBossRankReward:OnEnable()
    self:Refresh()
end

function XUiGuildBossRankReward:OnDisable()
end


function XUiGuildBossRankReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.RankRewardData[index], index)
    end
end

-- override
function XUiGuildBossRankReward:Refresh()
    self.RankRewardData = XGuildBossConfig.GeRankRewardIdList()
    self.RewardDynamicTable:SetDataSource(self.RankRewardData)
    self.RewardDynamicTable:ReloadDataASync()
end

return XUiGuildBossRankReward
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
--工会boss个人排行榜组件
local XUiGuildBossRankRewardItem = XClass(nil, "XUiGuildBossRankRewardItem")

function XUiGuildBossRankRewardItem:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.RewardItems = {}
    self.GridReward.gameObject:SetActiveEx(false)
    self.OnGridCreateCB = function(grid, data) self:OnGridCreate(grid, data) end
end

function XUiGuildBossRankRewardItem:Refresh(id)
    self.TxtRank.text = XGuildBossConfig.GetRankPercentName(id) -- 1%-5%
    local datas = XRewardManager.GetRewardList(XGuildBossConfig.GetRankRewardId(id))
    XUiHelper.CreateTemplates(self.RootUi, self.RewardItems, datas, XUiGridCommon.New, self.GridReward, self.PanelRewardList, self.OnGridCreateCB)
end

function XUiGuildBossRankRewardItem:OnGridCreate(grid, data)
    grid:Refresh(data)
end

return XUiGuildBossRankRewardItem
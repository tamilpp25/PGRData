--工会boss个人排行榜组件
local XUiGuildBossHpRewardItem = XClass(nil, "XUiGuildBossHpRewardItem")

function XUiGuildBossHpRewardItem:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.RewardItems = {}
    self.GridCommon.gameObject:SetActiveEx(false)
    self.OnGridCreateCB = function(grid, data) self:OnGridCreate(grid, data) end
end

function XUiGuildBossHpRewardItem:Refresh(id)
    self.TxtTaskName.text = CS.XTextManager.GetText("GuildBossHpRewardName", XGuildBossConfig.GetHpPercent(id)) -- Boss生命值降至{0}%可领取
    local datas = XRewardManager.GetRewardList(XDataCenter.GuildBossManager.GetHpRewardId(id))
    XUiHelper.CreateTemplates(self.RootUi, self.RewardItems, datas, XUiGridCommon.New, self.GridCommon, self.PanelReward, self.OnGridCreateCB)
end

function XUiGuildBossHpRewardItem:OnGridCreate(grid, data)
    grid:Refresh(data)
end

return XUiGuildBossHpRewardItem
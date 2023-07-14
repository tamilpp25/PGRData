local XUiBabelTowerRankReward = XClass(nil, "XUiBabelTowerRankReward")
local XUiGridRankRewardItem = require("XUi/XUiFubenBabelTower/XUiGridRankRewardItem")


function XUiBabelTowerRankReward:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)

    self.DynamicTable = XDynamicTableNormal.New(self.List.gameObject)
    self.DynamicTable:SetProxy(XUiGridRankRewardItem)
    self.DynamicTable:SetDelegate(self)

    self.BtnBlock.CallBack = function() self:OnBtnBlockClick() end
    self.BtnTanchuangClose.CallBack = function() self:OnBtnTanchuangClose() end

end

function XUiBabelTowerRankReward:OnDynamicTableEvent(event,index,grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.RankRewards[index]
        if not data then return end
        grid:Refresh(data)
    end
end

-- 刷新排名
function XUiBabelTowerRankReward:Refresh()
    self.GameObject:SetActiveEx(true)
    local rankLevel = XDataCenter.FubenBabelTowerManager.GetRankLevel()
    if rankLevel <= 0 then return end
    self.RankRewards = XFubenBabelTowerConfigs.GetBabelTowerRankReward(rankLevel)
    self.DynamicTable:SetDataSource(self.RankRewards)
    self.DynamicTable:ReloadDataASync()

    if self.TxtRankTitle then
        local activityNo = XDataCenter.FubenBabelTowerManager.GetCurrentActivityNo()
        if activityNo and activityNo > 0 then
            self.TxtRankTitle.text = XFubenBabelTowerConfigs.GetActivityRankTitle(activityNo)
        end
    end
end

function XUiBabelTowerRankReward:OnBtnBlockClick()
    self.GameObject:SetActiveEx(false)
end

function XUiBabelTowerRankReward:OnBtnTanchuangClose()
    self.GameObject:SetActiveEx(false)
end

return XUiBabelTowerRankReward
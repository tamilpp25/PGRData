local XUiBabelTowerRankInfo = XClass(nil, "XUiBabelTowerRankInfo")
local XUiBabelTowerMyRankInfos = require("XUi/XUiFubenBabelTower/XUiBabelTowerMyRankInfos")
local XUiBabelTowerRankReward = require("XUi/XUiFubenBabelTower/XUiBabelTowerRankReward")
local XUiGridRankItemInfo = require("XUi/XUiFubenBabelTower/XUiGridRankItemInfo")


function XUiBabelTowerRankInfo:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    -- 我的排名
    self.MyRankInfos = XUiBabelTowerMyRankInfos.New(self.PanelMyBossRank, self.UiRoot)
    -- 奖励
    self.RankReward = XUiBabelTowerRankReward.New(self.PanelRankReward, self.UiRoot)

    self.DynamicTable = XDynamicTableNormal.New(self.PlayerRankList.gameObject)
    self.DynamicTable:SetProxy(XUiGridRankItemInfo)
    self.DynamicTable:SetDelegate(self)

    -- TxtCurTime
    self.BtnRankReward.CallBack = function() self:OnBtnRankRewardClick() end
end

function XUiBabelTowerRankInfo:UpdateCurTime(timeStr)
    self.TxtCurTime.text = timeStr
end

function XUiBabelTowerRankInfo:OnDynamicTableEvent(event,index,grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.RankInfos[index]
        if not data then return end
        grid:Refresh(data)
    end
end

-- 刷新排名
function XUiBabelTowerRankInfo:Refresh()
    self.CurScore, self.CurRank, self.TotalRank = XDataCenter.FubenBabelTowerManager.GetScoreInfos()
    self.RankInfos = XDataCenter.FubenBabelTowerManager.GetRankInfos()

    self.DynamicTable:SetDataSource(self.RankInfos)
    self.DynamicTable:ReloadDataASync()
    self.PanelNoRank.gameObject:SetActiveEx(#self.RankInfos <= 0)
    self.TxtIos.gameObject:SetActiveEx(false)

    self.MyRankInfos:Refresh()

    -- 更新奖励按钮
    self.BtnRankReward.gameObject:SetActiveEx(false)
    self.RewardText.gameObject:SetActiveEx(false)
    local activityNo = XDataCenter.FubenBabelTowerManager.GetCurrentActivityNo()
    if not activityNo then return end
    local activityTemplate = XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(activityNo)
    if not activityTemplate then return end
    self.BtnRankReward.gameObject:SetActiveEx(activityTemplate.RankType == XFubenBabelTowerConfigs.RankType.RankAndReward)
    self.RewardText.gameObject:SetActiveEx(activityTemplate.RankType == XFubenBabelTowerConfigs.RankType.OnlyRank)

end

function XUiBabelTowerRankInfo:OnBtnRankRewardClick()
    self.RankReward:Refresh()
end

return XUiBabelTowerRankInfo
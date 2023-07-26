local XUiPanelUnionKillRankReward = XClass(nil, "XUiPanelUnionKillRankReward")
local XUiGridUnionRewardItem = require("XUi/XUiFubenUnionKill/XUiGridUnionRewardItem")

function XUiPanelUnionKillRankReward:Ctor(ui, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = root

    XTool.InitUiObject(self)
    self.BtnTanchuangClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnBlock.CallBack = function() self:OnBtnBlockClick() end

    self.DynamicTableReward = XDynamicTableNormal.New(self.BossScoreList.gameObject)
    self.DynamicTableReward:SetProxy(XUiGridUnionRewardItem)
    self.DynamicTableReward:SetDelegate(self)

end

function XUiPanelUnionKillRankReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.RankRewards[index]
        if not data then return end
        grid:Refresh(data, self.CurRankLevel)
    end
end

function XUiPanelUnionKillRankReward:Refresh(rankSelectLevel)
    self.GameObject:SetActiveEx(true)

    self.CurRankLevel = 1
    local unionKillInfo = XDataCenter.FubenUnionKillManager.GetUnionKillInfo()
    if unionKillInfo then
        local sectionId = unionKillInfo.CurSectionId
        local sectionInfo = XDataCenter.FubenUnionKillManager.GetSectionInfoById(sectionId)
        if sectionInfo then
            self.CurRankLevel = sectionInfo.RankLevel
        end
    end
    self.CurRankLevel = rankSelectLevel or self.CurRankLevel
    self.RankRewards = XFubenUnionKillConfigs.GetUnionRewardListByLevel(self.CurRankLevel)

    self.DynamicTableReward:Clear()
    self.DynamicTableReward:SetDataSource(self.RankRewards)
    self.DynamicTableReward:ReloadDataASync()
end

function XUiPanelUnionKillRankReward:OnBtnBlockClick()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelUnionKillRankReward:OnBtnCloseClick()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelUnionKillRankReward
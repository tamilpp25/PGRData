local XUiUpgradeCollection = XLuaUiManager.Register(XLuaUi, "UiUpgradeCollection")

function XUiUpgradeCollection:OnStart(collectionId,qualityData,cb)
    self.BtnCancel.CallBack = function()
        self:Close()
        XScheduleManager.ScheduleOnce(function()
                if cb then cb() end
            end, 1)
    end

    local rewardGoods = XRewardManager.CreateRewardGoods(collectionId)

    self:Refresh(rewardGoods,self.GridCommonBefore,qualityData.BeforeQuality)
    self:Refresh(rewardGoods,self.GridCommonAfter,qualityData.AfterQuality)
end

function XUiUpgradeCollection:Refresh(rewardGoods,gridCommon,quality)
    local grid = XUiGridCommon.New(self,gridCommon)
    local levelIcon = XDataCenter.MedalManager.GetLevelIcon(rewardGoods.TemplateId,quality)
    grid:SetSyncQuality(quality)
    grid:SetSyncLevelIcon(levelIcon)
    grid:Refresh(rewardGoods, nil, nil, false)
end

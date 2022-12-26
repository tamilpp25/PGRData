local XUiMoeWarPreparationRewardGrid = XClass(nil, "XUiMoeWarPreparationRewardGrid")

function XUiMoeWarPreparationRewardGrid:Ctor(ui, updatePanelPhasesRewardCb, gearId, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.RootUi = rootUi
    self.UpdatePanelPhasesRewardCb = updatePanelPhasesRewardCb
    self.GearId = gearId
    self:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnReceiveClick)
end

function XUiMoeWarPreparationRewardGrid:Init()
    self.TxtCurStage.text = XMoeWarConfig.GetPreparationGearNeedCount(self.GearId)
    local grid = XUiGridCommon.New(self.RootUi, self.GridCommon)
    local rewardId = XMoeWarConfig.GetPreparationGearShowRewardId(self.GearId)
    self.Rewards = rewardId > 0 and XRewardManager.GetRewardList(rewardId) or {}
    if self.Rewards[1] then
        grid:Refresh(self.Rewards[1])
    end
end

function XUiMoeWarPreparationRewardGrid:Refresh()
    local activityId = XMoeWarConfig.GetPreparationActivityIdInTime()
    if not activityId then
        return
    end

    local preGearId = XMoeWarConfig.GetPreparationActivityPrePreparationGear(activityId, self.GearId)
    local preGearNeedCount = preGearId and XMoeWarConfig.GetPreparationGearNeedCount(preGearId) or 0

    local isGetReward = XDataCenter.MoeWarManager.IsPreparationGetRewardGears(self.GearId)
    self.PanelFinish.gameObject:SetActiveEx(isGetReward)

    local needCount = XMoeWarConfig.GetPreparationGearNeedCount(self.GearId) - preGearNeedCount
    local haveCount = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.MoeWarPreparationItemId)
    haveCount = math.max(haveCount - preGearNeedCount, 0)
    local isCanReward = haveCount >= needCount

    self.ImgEffect.gameObject:SetActiveEx(not isGetReward and isCanReward)
end

function XUiMoeWarPreparationRewardGrid:OnBtnReceiveClick()
    local isGetReward = XDataCenter.MoeWarManager.IsPreparationGetRewardGears(self.GearId)
    local needCount = XMoeWarConfig.GetPreparationGearNeedCount(self.GearId)
    local haveCount = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.MoeWarPreparationItemId)
    local isCanReceive = haveCount >= needCount

    if not isCanReceive then
        local templateId = self.Rewards[1] and self.Rewards[1].TemplateId
        XLuaUiManager.Open("UiTip", templateId)
    elseif (isGetReward) or not XDataCenter.MoeWarManager.CheckRespondItemIsMax() then  --已领取的不检查道具是否满了
        XDataCenter.MoeWarManager.RequestMoeWarPreparationGearReward(self.GearId, handler(self, self.Refresh))
    end
end

function XUiMoeWarPreparationRewardGrid:GetGearId()
    return self.GearId
end

return XUiMoeWarPreparationRewardGrid
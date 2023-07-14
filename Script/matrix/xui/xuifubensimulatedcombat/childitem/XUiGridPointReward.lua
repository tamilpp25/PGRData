local XUiGridPointReward = XClass(nil, "XUiGridPointReward")
 
function XUiGridPointReward:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.BtnClick.CallBack = function() self:OnBtnRewardClick() end
end

function XUiGridPointReward:UpdateData(data, nextData, pointCounts)
    self.PointRewardId = data.Id
    self.NeedPoint = data.NeedPoint
    self.RewardId = data.RewardId
    self.ShowItem = data.ShowItem
    self.TxtCurStage.text = self.NeedPoint
    self.PointCounts = pointCounts
    if nextData then
        self.NextNeedPoint = nextData.NeedPoint
    end
   
    if self.ShowItem and self.ShowItem ~= 0 then
        local item = {}
        item.Id = self.ShowItem
        item.Count = data.ShowItemNum
        self.GridCommon.gameObject:SetActiveEx(true)
        self.ImgActive.gameObject:SetActiveEx(false)
        self.Grid = XUiGridCommon.New(self.RootUi, self.GridCommon)
        self.Grid:Refresh(item)
    else
        self.GridCommon.gameObject:SetActiveEx(false)
        self.ImgActive.gameObject:SetActiveEx(true)
    end
    self:UpdateState()
end

function XUiGridPointReward:UpdateState()

    self.Red.gameObject:SetActiveEx(false)
    self.PanelFinish.gameObject:SetActiveEx(false)
    if self.PointCounts >= self.NeedPoint then
        if not XDataCenter.FubenSimulatedCombatManager.CheckPointRewardGet(self.PointRewardId) then
            self.Red.gameObject:SetActiveEx(true)
        else
            self.PanelFinish.gameObject:SetActiveEx(true)
        end
        if not self.NextNeedPoint then
            self.PanelPassedLine.fillAmount = (self.PointCounts - self.NeedPoint) > 0 and 1 or 0
        elseif self.PointCounts < self.NextNeedPoint then
            self.PanelPassedLine.fillAmount = (self.PointCounts - self.NeedPoint) / (self.NextNeedPoint - self.NeedPoint)
        else
            self.PanelPassedLine.fillAmount = 1
        end
    else
        self.PanelPassedLine.fillAmount = 0
    end
end

function XUiGridPointReward:OnBtnRewardClick()
    local itemList = XRewardManager.GetRewardList(self.RewardId)

    if self.PointCounts >= self.NeedPoint then
        if not XDataCenter.FubenSimulatedCombatManager.CheckPointRewardGet(self.PointRewardId) then
            XDataCenter.FubenSimulatedCombatManager.GetPointReward(self.PointRewardId, function(reward)
                XUiManager.OpenUiObtain(reward, CS.XTextManager.GetText("Award"))
                self:UpdateState()
            end)
        else
            XUiManager.TipError(CS.XTextManager.GetText("SpecialPointRewardIsGet"))
        end
    elseif self.ShowItem and self.ShowItem ~= 0 then
        -- local item = XDataCenter.ItemManager.GetItem(self.ShowItem)
        -- local data = {
        --     Id = item.Id,
        --     Count = item ~= nil and tostring(item.Count) or "0"
        -- }
        -- XLuaUiManager.Open("UiTip", data)   
        self.Grid:OnBtnClickClick()
    else
        XUiManager.OpenUiTipReward(itemList)
    end
end

return XUiGridPointReward
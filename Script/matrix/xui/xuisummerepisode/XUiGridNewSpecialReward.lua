local XUiGridNewSpecialReward = XClass(nil, "XUiGridNewSpecialReward")

function XUiGridNewSpecialReward:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.BtnClick.CallBack = function() self:OnBtnRewardClick() end
end

function XUiGridNewSpecialReward:UpdateData(data, nextData, pointCounts)
    self.PointRewardId = data.Id
    self.NeedPoint = data.NeedPoint
    self.RewardId = data.RewardId
    self.ShowItem = data.ShowItem
    self.TxtCurStage.text = self.NeedPoint
    self.PointCounts = pointCounts
    local nextNeedPoint
    if nextData then
        nextNeedPoint = nextData.NeedPoint
    end
    self.Red.gameObject:SetActiveEx(false)
    self.PanelFinish.gameObject:SetActiveEx(false)
   
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
    
    if pointCounts >= self.NeedPoint then
        if not XDataCenter.FubenSpecialTrainManager.CheckPointRewardGet(self.PointRewardId) then
            self.Red.gameObject:SetActiveEx(true)
        else
            self.PanelFinish.gameObject:SetActiveEx(true)
        end
        if not nextNeedPoint then
            self.PanelPassedLine.fillAmount = 0
        elseif pointCounts < nextNeedPoint then
            self.PanelPassedLine.fillAmount = (pointCounts - self.NeedPoint) / (nextNeedPoint - self.NeedPoint) 
        else
            self.PanelPassedLine.fillAmount = 1
        end
    else
        self.PanelPassedLine.fillAmount = 0
    end
end

function XUiGridNewSpecialReward:OnBtnRewardClick()
    local itemList = XRewardManager.GetRewardList(self.RewardId)

    if self.PointCounts >= self.NeedPoint then
        if not XDataCenter.FubenSpecialTrainManager.CheckPointRewardGet(self.PointRewardId) then
            XDataCenter.FubenSpecialTrainManager.SpecialTrainPointRewardRequest(self.PointRewardId, function(reward)
                XUiManager.OpenUiObtain(reward, CS.XTextManager.GetText("Award"))
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

return XUiGridNewSpecialReward
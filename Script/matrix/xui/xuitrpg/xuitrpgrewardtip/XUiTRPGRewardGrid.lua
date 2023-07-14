local XUiTRPGRewardGrid = XClass(nil, "XUiTRPGRewardGrid")

function XUiTRPGRewardGrid:Ctor(ui, rootUi, truthRoadGroupId, secondMainId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.TruthRoadGroupId = truthRoadGroupId
    self.SecondMainId = secondMainId
    XTool.InitUiObject(self)

    self.BtnFinish.CallBack = function() self:OnBtnFinishClick() end

    self.GridList = {}
end

function XUiTRPGRewardGrid:Refresh(trpgRewardId)
    self.TRPGRewardId = trpgRewardId

    local ret = XDataCenter.TRPGManager.CheckRewardCondition(trpgRewardId, self.SecondMainId)
    self.TxtTaskName.text = self.SecondMainId and XTRPGConfigs.GetSecondMainReceiveDesc(trpgRewardId) or XTRPGConfigs.GetRewardReceiveDesc(trpgRewardId)

    local isReceiveReward = XDataCenter.TRPGManager.IsReceiveReward(trpgRewardId)
    self.BtnFinish:SetDisable(not ret, ret)
    self.BtnFinish.gameObject:SetActiveEx(not isReceiveReward)
    self.ImgAlreadyFinish.gameObject:SetActiveEx(isReceiveReward)

    local rewardId = XTRPGConfigs.GetRewardId(trpgRewardId)
    self:RefreshTreasureList(rewardId)

    self:CheckRefreshProgress()
end

function XUiTRPGRewardGrid:CheckRefreshProgress()
    local curPercent
    local receivePercent
    if self.TruthRoadGroupId then
        curPercent = XDataCenter.TRPGManager.GetTruthRoadPercent(self.TruthRoadGroupId)
        receivePercent = XTRPGConfigs.GetTruthRoadRewardRecivePercent(self.TruthRoadGroupId, self.TRPGRewardId)
    elseif self.SecondMainId then
        curPercent = XDataCenter.TRPGManager.GetSecondMainStagePercent(self.SecondMainId)
        receivePercent = XTRPGConfigs.GetSecondMainRewardRecivePercent(self.SecondMainId, self.TRPGRewardId)
    else
        self.ProgressBg.gameObject:SetActiveEx(false)
        self.TxtTaskNumQian.gameObject:SetActiveEx(false)
        return
    end
    self:RefreshProgress(curPercent, receivePercent)
end

function XUiTRPGRewardGrid:RefreshProgress(curPercent, receivePercent)
    if receivePercent <= 0 then
        self.ImgProgress.fillAmount = 0
    else
        self.ImgProgress.fillAmount = math.min(curPercent / receivePercent, 1)
    end
    self.TxtTaskNumQian.text = CS.XTextManager.GetText("TRPGAlreadyobtainedCount", math.floor(curPercent * 100) .. "%", math.floor(receivePercent * 100) .. "%")

    self.ProgressBg.gameObject:SetActiveEx(true)
    self.TxtTaskNumQian.gameObject:SetActiveEx(true)
end

function XUiTRPGRewardGrid:RefreshTreasureList(rewardId)
    local rewards = XRewardManager.GetRewardList(rewardId)
    if not rewards then return end

    for i, item in ipairs(rewards) do
        local grid = self.GridList[i]
        if not grid then
            if i == 1 then
                grid = XUiGridCommon.New(self.RootUi, self.GridCommon)
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                grid = XUiGridCommon.New(self.RootUi, ui)
                grid.Transform:SetParent(self.PanelRewardContent, false)
            end
            self.GridList[i] = grid
        end
        grid:Refresh(item)
        grid.GameObject:SetActiveEx(true)
    end

    for j = 1, #self.GridList do
        if j > #rewards then
            self.GridList[j].GameObject:SetActive(false)
        end
    end
end

function XUiTRPGRewardGrid:OnBtnFinishClick()
    local rewardId = XTRPGConfigs.GetRewardId(self.TRPGRewardId)
    local rewards = XRewardManager.GetRewardList(rewardId)
    if not rewards then return end

    --如果成功获得奖励时是否有道具会超出最大限制
    local isOpenTips = false
    local itemMaxCount
    local itemCount
    for _, v in ipairs(rewards) do
        itemMaxCount = XTRPGConfigs.GetItemMaxCount(v.TemplateId)
        itemCount = XDataCenter.ItemManager.GetCount(v.TemplateId)
        if itemCount + v.Count > itemMaxCount then
            isOpenTips = true
            break
        end
    end

    XDataCenter.TRPGManager.RequestRewardSend(self.TRPGRewardId, function ()
        self:Refresh(self.TRPGRewardId)
        if isOpenTips then
            XUiManager.TipText("TRPGGetRewardMaxTips")
        end
    end)
end

return XUiTRPGRewardGrid
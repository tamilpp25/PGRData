local XUiPanelLottoPreview = XClass(nil, "XUiPanelLottoPreview")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiPanelLottoPreview:Ctor(ui, base, data)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.Base = base
    self.LottoGroupData = data
    self.RewardCore = {}
    self.RewardFirst = {}
    self.RewardSecond = {}
    self.RewardThird = {}
end

function XUiPanelLottoPreview:UpdatePanel()
    self:UpdatePanelTips()
    self:UpdatePanelReward(self.PanelCore, self.RewardCore, XLottoConfigs.RareLevel.One)
    self:UpdatePanelReward(self.PanelFirst, self.RewardFirst, XLottoConfigs.RareLevel.Two)
    self:UpdatePanelReward(self.PanelSecond, self.RewardSecond, XLottoConfigs.RareLevel.Three)
    self:UpdatePanelReward(self.PanelThird, self.RewardThird, XLottoConfigs.RareLevel.Four)
    self:UpdateExReward()
end

function XUiPanelLottoPreview:UpdatePanelTips()
    local hintText = self.LottoGroupData:GetRuleHint()
    self.PanelTips.gameObject:SetActiveEx(hintText)
    self.PanelTips:GetObject("Text").text = hintText or ""
end

function XUiPanelLottoPreview:UpdatePanelReward(panel, rewardDic, rareLevel)
    local drawData = self.LottoGroupData:GetDrawData()
    local rewardDataList = drawData:GetRewardDataList()
    local gridObj = panel:GetObject("GridRewards")
    local Contents = panel:GetObject("GridContents")
    
    gridObj.gameObject:SetActiveEx(false)
    for _,rewardData in pairs(rewardDataList) do
        if rewardData:GetRareLevel() == rareLevel then
            local reward = rewardDic[rewardData:GetId()]
            if not reward then
                local obj = CS.UnityEngine.Object.Instantiate(gridObj, Contents)
                obj.gameObject:SetActiveEx(true)
                reward = XUiGridCommon.New(self.Base, obj)
                rewardDic[rewardData:GetId()] = reward
            end
            if reward then
                local tmpData = {TemplateId = rewardData:GetTemplateId(), Count = rewardData:GetCount()}
                reward:Refresh(tmpData, nil, nil, nil, rewardData:GetIsGeted() and 0 or 1)
            end
        end
    end
end

function XUiPanelLottoPreview:UpdateExReward()
    local drawData = self.LottoGroupData:GetDrawData()
    local ExtraRewardId = drawData:GetExtraRewardId()
    self.ExReward.gameObject:SetActiveEx(ExtraRewardId)
    if ExtraRewardId then
        local processText = CS.XTextManager.GetText("LottoExtraRewardProcessText")
        local curCount = math.min(drawData:GetCurRewardCount(),drawData:GetExtraRewardCount())
        local extraCount = drawData:GetExtraRewardCount()
        local textCount = self.ExReward:GetObject("TxtCount")
        local obj = self.ExReward:GetObject("GridRewards")
        
        local grid = XUiGridCommon.New(self.Base, obj)
        local IsGeted = drawData:GetExtraRewardState() == XLottoConfigs.ExtraRewardState.Geted
        local rewardList = XRewardManager.GetRewardList(ExtraRewardId)
        grid:Refresh(rewardList[1], nil, nil, nil, IsGeted and 0 or 1)
        
        textCount.text = string.format("%s%d/%d", processText, curCount, extraCount)
    end
    
end

return XUiPanelLottoPreview
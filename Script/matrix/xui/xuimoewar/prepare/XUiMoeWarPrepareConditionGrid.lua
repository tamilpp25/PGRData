local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiMoeWarPrepareConditionGrid = XClass(nil, "XUiMoeWarPrepareConditionGrid")

function XUiMoeWarPrepareConditionGrid:Ctor(ui, index)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.Index = index
end

function XUiMoeWarPrepareConditionGrid:Refresh(stageId, stageLabelId, helperId)
    local tagLabel = XMoeWarConfig.GetPreparationStageTagLabelById(stageLabelId)
    self.TxtSelectConditions.text = CSXTextManagerGetText("MoeWarConditionDesc", self.Index, tagLabel)
    self.TxtNormalConditions.text = CSXTextManagerGetText("MoeWarConditionDesc", self.Index, tagLabel)

    local rewardName = XMoeWarConfig.GetPreparationStageShowExtraRewardName(stageId, self.Index)
    self.TxtNormalPrepare.text = rewardName
    self.TxtSelectPrepare.text = rewardName

    local num = XMoeWarConfig.GetPreparationStageExtraRewardCount(stageId, self.Index)
    self.TxtSelectNumber.text = "+" .. num
    self.TxtNormalNumber.text = "+" .. num

    local rewardId = XMoeWarConfig.GetPreparationStageShowExtraRewardId(stageId, self.Index)
    local rewardList = XTool.IsNumberValid(rewardId) and XRewardManager.GetRewardList(rewardId) or {}
    local itemId = rewardList[1] and rewardList[1].TemplateId
    local goodsShowParams = itemId and XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId)
    local icon = goodsShowParams and goodsShowParams.Icon
    if self.NormalIcon and icon then
        self.NormalIcon:SetRawImage(icon)
    end
    if self.SelectIcon and icon then
        self.SelectIcon:SetRawImage(icon)
    end

    if XMoeWarConfig.IsFillPreparationStageLabel(stageLabelId, helperId) then
        self.Normal.gameObject:SetActiveEx(false)
        self.Select.gameObject:SetActiveEx(true)
        return
    end
    self.Normal.gameObject:SetActiveEx(true)
    self.Select.gameObject:SetActiveEx(false)
end

function XUiMoeWarPrepareConditionGrid:SetActive(isActive)
    self.GameObject:SetActiveEx(isActive)
end

return XUiMoeWarPrepareConditionGrid
local XUiReplaceGrid = XClass(nil, "XUiReplaceGrid")

function XUiReplaceGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.DataDb = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
end

function XUiReplaceGrid:Refresh(characterId)
    self.CharacterId = characterId
    self.TxtName.text = XGoldenMinerConfigs.GetCharacterName(characterId)
    self.TxtDes.text = XGoldenMinerConfigs.GetCharacterInfo(characterId)

    local headPath = XGoldenMinerConfigs.GetCharacterHeadPath(characterId)
    self.ImgIcon:SetRawImage(headPath)

    local conditionId = XGoldenMinerConfigs.GetCharacterCondition(characterId)
    local redEnvelopeNpcId, needCount = XConditionManager.GetConditionParams(conditionId)
    self.TextLockDesc.text = XConditionManager.GetConditionDescById(conditionId)
    self.TxtNeedCount.text = "/" .. (needCount or 0)
    self.TxtCurCount.text = self.DataDb:GetRedEnvelopeProgress(redEnvelopeNpcId)

    local isActive = XDataCenter.GoldenMinerManager.IsCharacterUnLock(characterId)
    self.ImgLock.gameObject:SetActiveEx(not isActive)
    self.TxtDes.gameObject:SetActiveEx(isActive)
end

function XUiReplaceGrid:SetSelectActive(isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end

function XUiReplaceGrid:GetCharacterId()
    return self.CharacterId
end

return XUiReplaceGrid
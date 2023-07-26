---@class XUiReplaceGrid
local XUiReplaceGrid = XClass(nil, "XUiReplaceGrid")

function XUiReplaceGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.DataDb = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
end

function XUiReplaceGrid:Refresh(characterId)
    self.CharacterId = characterId
    --Name
    self.TxtName.text = XGoldenMinerConfigs.GetCharacterName(characterId)
    self.TxtDes.text = XGoldenMinerConfigs.GetCharacterInfo(characterId)
    --Icon
    local headPath = XGoldenMinerConfigs.GetCharacterHeadPath(characterId)
    self.ImgIcon:SetRawImage(headPath)
    --Lock
    local isLock = XDataCenter.GoldenMinerManager.IsCharacterUnLock(characterId)
    self.ImgLock.gameObject:SetActiveEx(not isLock)
    self.TxtDes.gameObject:SetActiveEx(isLock)
    if isLock then
        local conditionId = XGoldenMinerConfigs.GetCharacterCondition(characterId)
        local redEnvelopeNpcId, needCount = XConditionManager.GetConditionParams(conditionId)
        self.TextLockDesc.text = XConditionManager.GetConditionDescById(conditionId)
        if XTool.IsNumberValid(needCount) then  -- 一期红包解锁文本
            self:SetConditionCountActive(true)
            self.TxtNeedCount.text = "/" .. (needCount or 0)
            self.TxtCurCount.text = self.DataDb:GetRedEnvelopeProgress(redEnvelopeNpcId)
        elseif XTool.IsNumberValid(redEnvelopeNpcId) then   -- 二期游玩次数解锁文本
            self:SetConditionCountActive(true)
            self.TxtNeedCount.text = "/" .. (redEnvelopeNpcId or 0)
            self.TxtCurCount.text = self.DataDb:GeTotalPlayCount()
        else
            self:SetConditionCountActive(false)
        end
    end
    --IsUsed
    local isUsed = XDataCenter.GoldenMinerManager.IsCharacterUsed(characterId)
    self.ImgUsedTag.gameObject:SetActiveEx(not isUsed)
end

function XUiReplaceGrid:SetConditionCountActive(active)
    self.TxtNeedCount.gameObject:SetActiveEx(active)
    self.TxtCurCount.gameObject:SetActiveEx(active)
end

function XUiReplaceGrid:SetSelectActive(isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end

function XUiReplaceGrid:GetCharacterId()
    return self.CharacterId
end

return XUiReplaceGrid
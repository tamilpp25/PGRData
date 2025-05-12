---@class XUiReplaceGrid : XUiNode
---@field _Control XGoldenMinerControl
local XUiReplaceGrid = XClass(XUiNode, "XUiReplaceGrid")

function XUiReplaceGrid:OnStart()
    self._DataDb = self._Control:GetMainDb()
end

function XUiReplaceGrid:Refresh(characterId)
    self.CharacterId = characterId
    --Name
    self.TxtName.text = self._Control:GetCfgCharacterName(characterId)
    self.TxtDes.text = self._Control:GetCfgCharacterInfo(characterId)
    --Icon
    local headPath = self._Control:GetCfgCharacterHeadIcon(characterId)
    self.ImgIcon:SetRawImage(headPath)
    --Lock
    local isLock = self._Control:IsCharacterUnLock(characterId)
    self.ImgLock.gameObject:SetActiveEx(not isLock)
    self.TxtDes.gameObject:SetActiveEx(isLock)
    if isLock then
        local conditionId = self._Control:GetCfgCharacterCondition(characterId)
        local redEnvelopeNpcId, needCount = XConditionManager.GetConditionParams(conditionId)
        self.TextLockDesc.text = XConditionManager.GetConditionDescById(conditionId)
        if XTool.IsNumberValid(needCount) then  -- 一期红包解锁文本
            self:SetConditionCountActive(true)
            self.TxtNeedCount.text = "/" .. (needCount or 0)
            self.TxtCurCount.text = self._DataDb:GetRedEnvelopeProgress(redEnvelopeNpcId)
        elseif XTool.IsNumberValid(redEnvelopeNpcId) then   -- 二期游玩次数解锁文本
            self:SetConditionCountActive(true)
            self.TxtNeedCount.text = "/" .. (redEnvelopeNpcId or 0)
            self.TxtCurCount.text = self._DataDb:GeTotalPlayCount()
        else
            self:SetConditionCountActive(false)
        end
    end
    --IsUsed 需求:没进入过关卡的角色要显示猫猫标签
    local isUsed = self._Control:IsCharacterUsed(characterId)
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
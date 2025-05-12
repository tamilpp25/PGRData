---@class XUiGridMaverick3Slay : XUiNode 必杀
---@field _Control XMaverick3Control
local XUiGridMaverick3Slay = XClass(XUiNode, "XUiGridMaverick3Slay")

function XUiGridMaverick3Slay:OnStart()
    self.ImgLock.gameObject:SetActiveEx(false)
    self.ImgNotOwned.gameObject:SetActiveEx(false)
    self.PanelChange.gameObject:SetActiveEx(false)
end

function XUiGridMaverick3Slay:SetData(id)
    if not XTool.IsNumberValid(id) then
        self.RImgIcon.gameObject:SetActiveEx(false)
        return
    end
    ---@type XTableMaverick3Talent
    self._Cfg = self._Control:GetTalentById(id)
    self.RImgIcon.gameObject:SetActiveEx(true)
    self.RImgIcon:SetRawImage(self._Cfg.Icon)
end

function XUiGridMaverick3Slay:Update(characterIndex, isPlayTween, playTweenId)
    local selectId = self._Control:GetSelectSlayId(characterIndex)
    self.PanelNow.gameObject:SetActiveEx(selectId == self._Cfg.Id)

    if isPlayTween and playTweenId == self._Cfg.Id then
        XUiHelper.PlayUiNodeAnimation(self.Transform, "GridUnlock", function()
            self:UpdateUnlockState(characterIndex)
        end)
    else
        self:UpdateUnlockState(characterIndex)
    end
end

function XUiGridMaverick3Slay:UpdateUnlockState()
    local isUnlock = self:IsUnlock()
    self.ImgLock.gameObject:SetActiveEx(not isUnlock)
    self.ImgNotOwned.gameObject:SetActiveEx(isUnlock and not self:IsOwned())
end

function XUiGridMaverick3Slay:IsOwned()
    return self._Control:IsTalentUnlock(self._Cfg.Id)
end

function XUiGridMaverick3Slay:IsUnlock()
    return not XTool.IsNumberValid(self._Cfg.Condition) or XConditionManager.CheckCondition(self._Cfg.Condition)
end

function XUiGridMaverick3Slay:AddClick(func)
    self.PanelChange.gameObject:SetActiveEx(true)
    self.Btn.CallBack = func
end

return XUiGridMaverick3Slay

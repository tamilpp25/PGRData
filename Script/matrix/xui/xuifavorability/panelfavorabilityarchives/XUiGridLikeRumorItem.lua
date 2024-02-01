local XUiGridLikeRumorItem = XClass(XUiNode, "XUiGridLikeRumorItem")

local ArrowUp = CS.UnityEngine.Vector3(1, -1, 1)
local ArrowDown = CS.UnityEngine.Vector3.one
local ImgContentSize = CS.UnityEngine.Vector2.zero
local ItemContentSize = CS.UnityEngine.Vector2.zero
local RumorImgSize = CS.UnityEngine.Vector2(530, 366)

function XUiGridLikeRumorItem:OnStart()
    self:InitUiAfterAuto()
end


function XUiGridLikeRumorItem:InitUiAfterAuto()
    self.ImgArrowTransform = self.ImgArrow.transform
    self.ImgArrowTransform.localScale = ArrowDown
    self.ImgContentTransform = self.ImgContent.transform
    self.TxtInfoTransform = self.TxtInfo.transform
    self.RumorImageTransform = self.BtnImage.transform

    self.TransformSizeDelta = self.Transform.sizeDelta
    self.ImgContentSizeDelta = self.ImgContentTransform.sizeDelta

    self.StartPos = self.RumorImageTransform.localPosition
    self.BtnImage.CallBack = function() self.OnBtnImageClick() end

end

function XUiGridLikeRumorItem:OnRefresh(rumorData, toggle)
    self.RumorData = rumorData
    local characterId = self.Parent:GetCurrFavorabilityCharacter()
    local isUnlock = XMVCA.XFavorability:IsRumorUnlock(characterId, rumorData.Id)
    local canUnlock = XMVCA.XFavorability:CanRumorsUnlock(characterId, rumorData.UnlockType, rumorData.UnlockPara)

    self.CurrentState = XEnumConst.Favorability.InfoState.Normal
    if not isUnlock then
        if canUnlock then
            self.CurrentState = XEnumConst.Favorability.InfoState.Available
        else
            self.CurrentState = XEnumConst.Favorability.InfoState.Lock
        end
    end

    self:UpdateNormalStatus(self.CurrentState == XEnumConst.Favorability.InfoState.Normal or self.CurrentState == XEnumConst.Favorability.InfoState.Available)
    self:UpdateAvailableStatus(self.CurrentState == XEnumConst.Favorability.InfoState.Available)
    self:UpdateLockStatus(self.CurrentState == XEnumConst.Favorability.InfoState.Lock)

    self:ToggleContent(toggle or false)
    if toggle then
        self.ImgArrowTransform.localScale = ArrowUp
    else
        self.ImgArrowTransform.localScale = ArrowDown
    end
end

function XUiGridLikeRumorItem:ToggleContent(isToggle)
    if self.RumorData == nil then return end

    self.ImgContent.gameObject:SetActive(isToggle)

    if isToggle then
        self.TxtInfo.text = string.gsub(self.RumorData.Content, "\\n", "\n")
        local txtHeight = self.TxtInfo.preferredHeight
        if self.RumorData.Picture then
            self.Parent:SetUiSprite(self.RumorImage, self.RumorData.Picture)
            self.RumorImageTransform.sizeDelta = RumorImgSize
        else
            self.RumorImageTransform.sizeDelta = CS.UnityEngine.Vector2.zero
        end
        --改变容器大小
        local offsetY = self.RumorImageTransform.sizeDelta.y
        -- ImgContentSize = CS.UnityEngine.Vector2(self.ImgContentSizeDelta.x, offsetY + txtHeight + 30)
        -- ItemContentSize = CS.UnityEngine.Vector2(self.TransformSizeDelta.x, ImgContentSize.y + self.TransformSizeDelta.y)
    else
        self.TxtInfo.text = ""
        self.RumorImageTransform.sizeDelta = CS.UnityEngine.Vector2.zero
        -- ItemContentSize = self.TransformSizeDelta
        -- ImgContentSize = CS.UnityEngine.Vector2(self.ImgContentSizeDelta.x, 0)
    end

    -- local rumorImgY = self.RumorImageTransform.sizeDelta.y
    -- local txtInfoPos = CS.UnityEngine.Vector3(self.StartPos.x, self.StartPos.y - rumorImgY - 10, self.StartPos.z)
    -- self.TxtInfoTransform.localPosition = txtInfoPos
    self.ImgContentLayout:SetDirty()
    self.LayoutNode:SetDirty()
    -- self:OnResize()
end

function XUiGridLikeRumorItem:OnResize()
    self.Transform.sizeDelta = ItemContentSize
    self.ImgContentTransform.sizeDelta = ImgContentSize
end

function XUiGridLikeRumorItem:OnBtnImageClick()
    if self.RumorData.Picture then
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FAVORABILITY_RUMORS_PREVIEW, self.RumorData.PreviewPicture)
    end
end

function XUiGridLikeRumorItem:UpdateNormalStatus(isNormal)
    self.RumorNor.gameObject:SetActive(isNormal)
    if isNormal and self.RumorData then
        self.TxtTitle.text = self.RumorData.Title
        local currentCharacterId = self.Parent:GetCurrFavorabilityCharacter()
        --2.7
        --self.ImgIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(currentCharacterId))
    end
end

function XUiGridLikeRumorItem:UpdateAvailableStatus(isAvailable)
    self.ImgRedDot.gameObject:SetActive(isAvailable)
end


function XUiGridLikeRumorItem:HideRedDot()
    self.ImgRedDot.gameObject:SetActive(false)
end


function XUiGridLikeRumorItem:UpdateLockStatus(isLock)
    self.RumorLock.gameObject:SetActive(isLock)
    if isLock and self.RumorData then
        self.TxtLockTitle.text = self.RumorData.Title
        self.TxtLock.text = self.RumorData.ConditionDescript
    end
end

return XUiGridLikeRumorItem
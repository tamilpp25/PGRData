local XUiGridLikeInfoItem = XClass(XUiNode, "XUiGridLikeInfoItem")

local ArrowDown = CS.UnityEngine.Vector3.one
local ArrowUp = CS.UnityEngine.Vector3(1, -1, 1)
local ImgContentSize = CS.UnityEngine.Vector2.zero
local ItemContentSize = CS.UnityEngine.Vector2.zero

function XUiGridLikeInfoItem:OnStart()
    self:InitUiAfterAuto()
end

function XUiGridLikeInfoItem:OnDisable()
    self:ToggleContent( false)
end

function XUiGridLikeInfoItem:InitUiAfterAuto()
    self.ImgArrowTransform = self.ImgArrow.transform
    self.ImgArrowTransform.localScale = ArrowDown
    self.ImgContentTransform = self.ImgContent.transform
    self.TransformSizeDelta = self.Transform.sizeDelta
    self.ImgContentSizeDelta = self.ImgContentTransform.sizeDelta
end

function XUiGridLikeInfoItem:OnRefresh(datas, toggle)
    self.CharacterDatas = datas
    local characterId = self.Parent:GetCurrFavorabilityCharacter()
    local isUnlock = self._Control:IsInformationUnlock(characterId, self.CharacterDatas.config.Id)
    local canUnlock = self._Control:CanInformationUnlock(characterId, self.CharacterDatas.config.Id)
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

function XUiGridLikeInfoItem:OnToggle()
    if not self.CharacterDatas then return end
    self.CharacterDatas.IsToggle = not self.CharacterDatas.IsToggle
end

function XUiGridLikeInfoItem:ToggleContent(isToggle)
    if self.CharacterDatas == nil then return end

    self.ImgContent.gameObject:SetActive(isToggle)
    if isToggle then
        self.TxtInfo.text = string.gsub(self.CharacterDatas.config.Content, "\\n", "\n")
        local txtHeight = self.TxtInfo.preferredHeight
        --ImgContentSize = CS.UnityEngine.Vector2(self.ImgContentSizeDelta.x, 0)
        --ItemContentSize = CS.UnityEngine.Vector2(self.TransformSizeDelta.x, ImgContentSize.y + self.TransformSizeDelta.y)
    else
        self.TxtInfo.text = ""
        --ItemContentSize = self.TransformSizeDelta
        --ImgContentSize = CS.UnityEngine.Vector2(self.ImgContentSizeDelta.x, 0)
    end
    self.ImgContentLayout:SetDirty()
    self.LayoutNode:SetDirty()
    --self:OnResize()
end

function XUiGridLikeInfoItem:OnResize()
    self.Transform.sizeDelta = CS.UnityEngine.Vector2(self.TransformSizeDelta.x, self.ImgContentTransform.sizeDelta.y + self.TransformSizeDelta.y)
    self.ImgContentTransform.sizeDelta = ImgContentSize
end


function XUiGridLikeInfoItem:UpdateNormalStatus(isNormal)
    self.InfoNor.gameObject:SetActive(isNormal)
    if isNormal and self.CharacterDatas then
        local title = self.CharacterDatas.config.Title
        self.TxtTitle.text = title
        self.TxtNum.text = string.sub(title, #title - 1, #title)
    end
end

function XUiGridLikeInfoItem:UpdateAvailableStatus(isAvailable)
    --self.InfoUnlock.gameObject:SetActive(isAvailable)
    self.ImgRedDot.gameObject:SetActive(isAvailable)
end


function XUiGridLikeInfoItem:HideRedDot()
    --self.InfoUnlock.gameObject:SetActive(isAvailable)
    self.ImgRedDot.gameObject:SetActive(false)
end

function XUiGridLikeInfoItem:UpdateLockStatus(isLock)
    self.InfoLock.gameObject:SetActive(isLock)
    if isLock and self.CharacterDatas then
        self.TxtLock.text = self.CharacterDatas.config.ConditionDescript
        self.TxtLockTitle.text = self.CharacterDatas.config.Title
    end
end

return XUiGridLikeInfoItem
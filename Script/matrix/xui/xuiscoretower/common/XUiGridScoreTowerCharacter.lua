---@class XUiGridScoreTowerCharacter : XUiNode
---@field private _Control XScoreTowerControl
local XUiGridScoreTowerCharacter = XClass(XUiNode, "XUiGridScoreTowerCharacter")

---@param clickCallback function 点击回调
function XUiGridScoreTowerCharacter:OnStart(clickCallback)
    XUiHelper.RegisterClickEvent(self, self.BtnCharacter, self.OnBtnCharacterClick, nil, true)
    self.PanelEmpty.gameObject:SetActiveEx(false)
    self.PanelCharacter.gameObject:SetActiveEx(false)
    self.TagRecommend.gameObject:SetActiveEx(false)
    self.PanelSelect.gameObject:SetActiveEx(false)
    self.PanelUse.gameObject:SetActiveEx(false)
    if self.PanelNow then
        self.PanelNow.gameObject:SetActiveEx(false)
    end
    self.TagTry.gameObject:SetActiveEx(false)
    self.ClickCallback = clickCallback

    -- 标签索引 1 元素 2 效应 3 职业
    ---@type table<number, {Parent: UnityEngine.RectTransform, RawImage: UnityEngine.UI.RawImage}>
    self.CharacterTagUi = {
        [1] = {
            Parent = self.PanelElement,
            RawImage = self.RImgElement,
        },
        [2] = {
            Parent = self.PanelGeneral,
            RawImage = self.RImgGeneral,
        },
        [3] = {
            RawImage = self.RImgCareer,
        }
    }
end

-- 是否隐藏试用
function XUiGridScoreTowerCharacter:SetHideTry(isHide)
    self.HideTry = isHide
end

-- 是否显示红点
function XUiGridScoreTowerCharacter:SetShowRedDot(isShow)
    self.ShowRedDot = isShow
end

-- 是否隐藏角色信息
function XUiGridScoreTowerCharacter:SetHideCharacterInfo(isHide)
    self.HideCharacterInfo = isHide
end

---@param entityId number 实体Id
---@param index number 索引
function XUiGridScoreTowerCharacter:Refresh(entityId, index)
    self.EntityId = entityId
    self.Index = index
    self.IsEmpty = not XTool.IsNumberValid(entityId)
    self:RefreshState()
    self:RefreshCharacterInfo()
    self:RefreshTry()
    self:RefreshRedDot()
end

-- 刷新状态
function XUiGridScoreTowerCharacter:RefreshState()
    self.PanelEmpty.gameObject:SetActiveEx(self.IsEmpty)
    self.PanelCharacter.gameObject:SetActiveEx(not self.IsEmpty)
end

-- 刷新角色信息
function XUiGridScoreTowerCharacter:RefreshCharacterInfo()
    if self.IsEmpty then
        return
    end
    local characterId = XEntityHelper.GetCharacterIdByEntityId(self.EntityId)
    if not XTool.IsNumberValid(characterId) then
        XLog.Error(string.format("error: characterId is invalid, entityId:%s", self.EntityId))
        return
    end
    -- 头像
    self.RImgHead:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId))

    self.PanelElement.gameObject:SetActiveEx(not self.HideCharacterInfo)
    self.PanelGeneral.gameObject:SetActiveEx(not self.HideCharacterInfo)
    self.PanelStatciLv.gameObject:SetActiveEx(not self.HideCharacterInfo)
    if self.HideCharacterInfo then
        return
    end
    -- 元素
    self:RefreshTag(characterId, 1)
    -- 效应
    self:RefreshTag(characterId, 2)
    -- 职业
    self:RefreshTag(characterId, 3)
    -- 刷新战力
    self:RefreshAbility()
end

-- 刷新标签
function XUiGridScoreTowerCharacter:RefreshTag(characterId, index)
    if not XTool.IsNumberValid(characterId) then
        XLog.Error("RefreshTag error: characterId is invalid")
        return
    end
    local tagUi = self.CharacterTagUi[index]
    if not tagUi then
        return
    end

    local tagIcon = self._Control:GetCharacterTagIcon(characterId, index)
    local hasTagIcon = not string.IsNilOrEmpty(tagIcon)
    if tagUi.Parent then
        tagUi.Parent.gameObject:SetActiveEx(hasTagIcon)
    else
        tagUi.RawImage.gameObject:SetActiveEx(hasTagIcon)
    end
    if hasTagIcon then
        tagUi.RawImage:SetRawImage(tagIcon)
    end
end

-- 刷新战力
function XUiGridScoreTowerCharacter:RefreshAbility()
    self.TxtStatciLv.text = XMVCA.XScoreTower:GetCharacterPower(self.EntityId)
end

-- 刷新试用
function XUiGridScoreTowerCharacter:RefreshTry()
    local isTry = not self.HideTry and not self.IsEmpty and XRobotManager.CheckIsRobotId(self.EntityId)
    self.TagTry.gameObject:SetActiveEx(isTry)
end

-- 刷新红点
function XUiGridScoreTowerCharacter:RefreshRedDot()
    local isShow = self.ShowRedDot and self.IsEmpty
    self.BtnCharacter:ShowReddot(isShow)
end

-- 设置是否是推荐
function XUiGridScoreTowerCharacter:SetIsRecommend(isRecommend)
    local isShow = isRecommend and not self.IsEmpty
    self.TagRecommend.gameObject:SetActiveEx(isShow)
end

-- 设置是否在队伍中
function XUiGridScoreTowerCharacter:SetIsInTeam(isTeam, index)
    local isShow = isTeam and not self.IsEmpty
    self.PanelSelect.gameObject:SetActiveEx(isShow)
    --if isShow then
    --    self.PanelNum.gameObject:SetActiveEx(index > 0)
    --    self.TxtNum.text = index
    --end
end

-- 设置使用状态
function XUiGridScoreTowerCharacter:SetUse(isUse)
    self.PanelUse.gameObject:SetActiveEx(isUse and not self.IsEmpty)
end

-- 设置当前状态
function XUiGridScoreTowerCharacter:SetNow(isNow)
    if self.PanelNow then
        self.PanelNow.gameObject:SetActiveEx(isNow and not self.IsEmpty)
    end
end

-- 点击角色
function XUiGridScoreTowerCharacter:OnBtnCharacterClick()
    if self.ClickCallback then
        self.ClickCallback(self.EntityId, self.Index)
    end
end

return XUiGridScoreTowerCharacter

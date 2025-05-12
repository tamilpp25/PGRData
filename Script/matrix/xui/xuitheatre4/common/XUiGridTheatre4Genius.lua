---@class XUiGridTheatre4Genius : XUiNode
---@field private _Control XTheatre4Control
local XUiGridTheatre4Genius = XClass(XUiNode, "XUiGridTheatre4Genius")

function XUiGridTheatre4Genius:OnStart(callback)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
    self.Select.gameObject:SetActiveEx(false)
    self.Lock.gameObject:SetActiveEx(false)
    self.ImgLock.gameObject:SetActiveEx(false)
    self.Red.gameObject:SetActiveEx(false)
    self.Callback = callback

    self.RImgIcon2 = self.RImgIcon2 or XUiHelper.TryGetComponent(self.Transform, "RImgIcon2", "RectTransform")
end

-- 获取天赋Id
---@return number 天赋Id
function XUiGridTheatre4Genius:GetTalentId()
    return self.TalentId
end

---@param id number 天赋Id
function XUiGridTheatre4Genius:Refresh(id)
    if not XTool.IsNumberValid(id) then
        return
    end
    self.TalentId = id
    self:RefreshGenius()
end

function XUiGridTheatre4Genius:RefreshGenius()
    -- 图标
    local icon = self._Control:GetColorTalentIcon(self.TalentId)
    if icon then
        self.RImgIcon:SetRawImage(icon)
    end
end

function XUiGridTheatre4Genius:SetQuestionMarkState(value)
    if value then
        self.RImgIcon2.gameObject:SetActiveEx(value)
        self.RImgIcon.gameObject:SetActiveEx(false)
        self:SetMask(value)
        self:SetLock(value)
    else
        self.RImgIcon2.gameObject:SetActiveEx(false)
        self.RImgIcon.gameObject:SetActiveEx(true)
    end
end

-- 其他数据
function XUiGridTheatre4Genius:SetOther(value)
    self.OtherValue = value
end

function XUiGridTheatre4Genius:GetOtherValue()
    return self.OtherValue
end

-- 选择
function XUiGridTheatre4Genius:SetSelect(isSelect)
    self.Select.gameObject:SetActiveEx(isSelect)
end

-- 遮罩
function XUiGridTheatre4Genius:SetMask(isMask)
    self.Lock.gameObject:SetActiveEx(isMask)
end

-- 锁定
function XUiGridTheatre4Genius:SetLock(isLock)
    self.ImgLock.gameObject:SetActiveEx(isLock)
end

function XUiGridTheatre4Genius:SetLvIcon(icon)
    if self.ImgGeniusIconLv then
        self.ImgGeniusIconLv.gameObject:SetActiveEx(true)
        self.ImgGeniusIconLv:SetSprite(icon)
    end
end

function XUiGridTheatre4Genius:SetLvActive(isActive)
    if self.ImgGeniusIconLv then
        self.ImgGeniusIconLv.gameObject:SetActiveEx(isActive)
    end
end

-- 红点
function XUiGridTheatre4Genius:ShowRedDot(isShow)
    self.Red.gameObject:SetActiveEx(isShow)
end

function XUiGridTheatre4Genius:OnBtnClick()
    if self.Callback then
        self.Callback(self)
    end
end

return XUiGridTheatre4Genius

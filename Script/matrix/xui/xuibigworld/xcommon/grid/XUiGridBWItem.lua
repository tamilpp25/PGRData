---@class XUiGridBWItem : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field TxtName UnityEngine.UI.Text
---@field PanelCount UnityEngine.RectTransform
---@field TxtCount UnityEngine.UI.Text
---@field RImgIcon UnityEngine.UI.RawImage
---@field ImgQuality UnityEngine.UI.Image
---@field Lock UnityEngine.RectTransform
---@field Red UnityEngine.RectTransform
---@field BtnClick UnityEngine.UI.Button
local XUiGridBWItem = XClass(XUiNode, "XUiGridBWItem")

local stringFormat = string.format

function XUiGridBWItem:OnStart(clickProxy)
    self._ClickProxy = clickProxy
    self:InitUi()
    self:InitCb()
end

function XUiGridBWItem:InitUi()
end

function XUiGridBWItem:InitCb()
    self:_RefreshClickHandler(self.BtnClick, self.OnClick)
end

function XUiGridBWItem:OnClick()

    if self._ClickProxy then
        self._ClickProxy(self._ItemsParams, self._GoodsParams)
        return
    end

    -- 目前dlc没有通用的物品详情界面
    -- 临时这样处理
    self._GoodsParams.IsTempItemData = true
    XLuaUiManager.Open("UiTip", self._GoodsParams, not self:IsAllowSkip())
end

--- 兼容某写动态创建接口
--------------------------
function XUiGridBWItem:Update(data)
    self:Refresh(data)
end

function XUiGridBWItem:Refresh(data)
    self._ItemsParams = XMVCA.XBigWorldService:GetItemsShowParams(data)

    if not self._ItemsParams then
        self:Close()
        return
    end

    self._GoodsParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self:GetTemplateId())

    if not self._GoodsParams then
        self:Close()
        return
    end

    self:_RefreshActive(self.PanelProgress, false)
    self:_RefreshActive(self.PanelSite, false)
    self:RefreshName(self._GoodsParams.Name)
    self:RefreshCount(self._ItemsParams.Count)
    self:RefreshIcon(self._ItemsParams.IsUseBigIcon and self._GoodsParams.BigIcon or self._GoodsParams.Icon)

    if self._GoodsParams.QualityIcon then
        self:_RefreshImage(self.ImgQuality, false, self._GoodsParams.QualityIcon)
    else
        self:RefreshQuality(self._GoodsParams.Quality)
    end
end

function XUiGridBWItem:RefreshName(name)
    self:_RefreshText(self.TxtName, name)
end

function XUiGridBWItem:RefreshCount(count)
    if not count then
        self:_RefreshActive(self.PanelCount, false)
        self:_RefreshActive(self.TxtCount, false)
        return
    end

    self:_RefreshActive(self.PanelCount, true)
    self:_RefreshText(self.TxtCount, tostring(count))
end

function XUiGridBWItem:RefreshProgressNum(ownCount, targetCount, ownColor, targetColor)
    if XTool.UObjIsNil(self.PanelProgress) then
        return
    end
    self:_RefreshActive(self.PanelProgress, true)
    self.PanelProgress.gameObject:SetActiveEx(true)
    local strOwn, strTarget
    if ownColor then
        strOwn = stringFormat("<color=%s>%d</color>", ownColor, ownCount)
    else
        strOwn = ownCount
    end

    if targetColor then
        strTarget = stringFormat("<color=%s>/%d</color>", targetColor, targetCount)
    else
        strTarget = "/" .. targetCount
    end

    self:_RefreshText(self.TxtNumber, stringFormat("%s%s", strOwn, strTarget))
end

function XUiGridBWItem:RefreshIcon(icon)
    self:_RefreshImage(self.RImgIcon, true, icon)
end

function XUiGridBWItem:RefreshQuality(quality)
    self:_RefreshImage(self.ImgQuality, false, XArrangeConfigs.GeQualityPath(quality))
end

function XUiGridBWItem:GetTemplateId()
    if self._ItemsParams then
        return self._ItemsParams.TemplateId or 0
    end

    return 0
end

function XUiGridBWItem:IsAllowSkip()
    if self._ItemsParams then
        return self._ItemsParams.IsAllowSkip
    end

    return false
end

function XUiGridBWItem:_RefreshActive(component, isActive)
    if XTool.UObjIsNil(component) then
        return
    end

    component.gameObject:SetActiveEx(isActive)
end

function XUiGridBWItem:_RefreshText(component, value)
    if XTool.UObjIsNil(component) then
        return
    end
    local invalid = string.IsNilOrEmpty(value)

    self:_RefreshActive(component, not invalid)
    if invalid then
        return
    end
    component.text = value
end

function XUiGridBWItem:_RefreshImage(component, isRawImage, value)
    if XTool.UObjIsNil(component) then
        return
    end
    local invalid = string.IsNilOrEmpty(value)
    component.gameObject:SetActiveEx(not invalid)
    if invalid then
        return
    end
    if isRawImage then
        component:SetRawImage(value)
    else
        component:SetSprite(value)
    end
end

function XUiGridBWItem:_RefreshClickHandler(component, clickHandler)
    if XTool.UObjIsNil(component) then
        return
    end

    XUiHelper.RegisterCommonClickEvent(self, component, clickHandler)
end

return XUiGridBWItem

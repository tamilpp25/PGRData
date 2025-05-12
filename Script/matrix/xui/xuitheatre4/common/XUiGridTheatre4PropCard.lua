local XUiGridTheatre4Prop = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Prop")
---@class XUiGridTheatre4PropCard : XUiNode
---@field private _Control XTheatre4Control
---@field TxtDetail XUiComponent.XUiRichTextCustomRender
local XUiGridTheatre4PropCard = XClass(XUiNode, "XUiGridTheatre4PropCard")

function XUiGridTheatre4PropCard:OnStart(selectCb, yesCb)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
    self._Control:RegisterClickEvent(self, self.BtnYes, self.OnBtnYesClick)
    self._Control:RegisterClickEvent(self, self.BtnSell, self.OnBtnSellClick)
    self._Control:RegisterClickEvent(self, self.BtnContrast, self.OnBtnContrastClick)
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.TxtNone.gameObject:SetActiveEx(false)
    self.TxtStory.gameObject:SetActiveEx(false)
    self.TxtCondition.gameObject:SetActiveEx(false)
    self.TxtNum.gameObject:SetActiveEx(false)
    self.ImgNow.gameObject:SetActiveEx(false)
    self.BtnYes.gameObject:SetActiveEx(false)
    self.BtnSell.gameObject:SetActiveEx(false)
    self.BtnContrast.gameObject:SetActiveEx(false)
    self.SelectCallback = selectCb
    self.YesCallback = yesCb
end

-- 获取下标索引
function XUiGridTheatre4PropCard:GetIndex()
    return self.Index
end

---@param itemData { UId:number, Id:number, Type:number, Count:number, Index:number }
function XUiGridTheatre4PropCard:Refresh(itemData)
    if not itemData then
        return
    end
    self.UId = itemData.UId
    self.ItemId = itemData.Id
    self.ItemType = itemData.Type
    self.ItemCount = itemData.Count or 0
    self.Index = itemData.Index or 0
    self:RefreshItem()
    self:RefreshItemInfo()
end

function XUiGridTheatre4PropCard:SetAlpha(alpha)
    self:_InitCanvasGroup()
    if not XTool.UObjIsNil(self._CanvasGroup) then
        self._CanvasGroup.alpha = alpha
    end
end

-- 刷新藏品
function XUiGridTheatre4PropCard:RefreshItem()
    if not self.PanelGridProp then
        ---@type XUiGridTheatre4Prop
        self.PanelGridProp = XUiGridTheatre4Prop.New(self.GridProp, self)
    end
    self.PanelGridProp:Open()
    self.PanelGridProp:Refresh({ UId = self.UId, Id = self.ItemId, Type = self.ItemType, Count = self.ItemCount })
end

-- 刷新藏品信息
function XUiGridTheatre4PropCard:RefreshItemInfo()
    -- 名称
    self.TxtName.text = self._Control.AssetSubControl:GetAssetName(self.ItemType, self.ItemId)
    -- 描述
    self.TxtDetail.requestImage = function(key, img)
        if key == "Img1" then
            local descIcon = self._Control:GetItemDescIcon(self.ItemId)
            if descIcon then
                img:SetSprite(descIcon)
            end
        end
    end
    self.TxtDetail.text = self._Control.AssetSubControl:GetAssetDesc(self.ItemType, self.ItemId)
    -- 累计加成
    local effectDesc = XTool.IsNumberValid(self.UId) and self._Control.EffectSubControl:GetItemEffectDesc(self.UId, self.ItemId) or nil
    self.TxtNum.gameObject:SetActiveEx(effectDesc ~= nil)
    self.TxtNum.text = effectDesc or ""
end

-- 设置选择状态
function XUiGridTheatre4PropCard:SetIsSelect(isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end

-- 设置确认按钮显示
function XUiGridTheatre4PropCard:SetBtnYes(isShow)
    self.BtnYes.gameObject:SetActiveEx(isShow)
end

-- 设置出售按钮显示
function XUiGridTheatre4PropCard:SetBtnSell(isShow)
    self.BtnSell.gameObject:SetActiveEx(isShow)
    if isShow then
        self.BtnSell:SetNameByGroup(0, "+" .. self._Control:GetItemBackPrice(self.ItemId))
        self.BtnSell:SetRawImage(self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Gold))
    end
end

-- 设置对比按钮显示
function XUiGridTheatre4PropCard:SetBtnContrast(isShow)
    self.BtnContrast.gameObject:SetActiveEx(isShow)
end

-- 显示未获得
function XUiGridTheatre4PropCard:SetTxtNone(isShow)
    self.TxtNone.gameObject:SetActiveEx(isShow)
end

-- 显示条件
function XUiGridTheatre4PropCard:SetTxtCondition(isShow)
    self.TxtCondition.text = isShow and self._Control:GetItemConditionDesc(self.ItemId) or ""
    self.TxtCondition.gameObject:SetActiveEx(isShow)
end

-- 显示当前选择
function XUiGridTheatre4PropCard:SetImgNow(isShow)
    self.ImgNow.gameObject:SetActiveEx(isShow)
end

function XUiGridTheatre4PropCard:SetReplaceCallback(callback)
    self.ReplaceCallback = function(uid)
        callback(self.Index, uid)
    end
end

function XUiGridTheatre4PropCard:SetSellCallback(callback)
    self.SellCallback = callback
end

function XUiGridTheatre4PropCard:SetSellTag(isShow)
    if self.ImgSell then
        self.ImgSell.gameObject:SetActiveEx(isShow)
    end
    if self.TxtSell and isShow then
        self.TxtSell.text = "+" .. self._Control:GetItemBackPrice(self.ItemId)
    end
    if self.RImgSell and isShow then
        self.RImgSell:SetRawImage(self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Gold))
    end
end

function XUiGridTheatre4PropCard:OnBtnClick()
    if self.SelectCallback then
        self.SelectCallback(self)
    end
end

function XUiGridTheatre4PropCard:OnBtnYesClick()
    if self.YesCallback then
        self.YesCallback(self.Index)
    end
end

function XUiGridTheatre4PropCard:OnBtnSellClick()
    if self.SellCallback then
        self.SellCallback(self.Index)
    end
end

function XUiGridTheatre4PropCard:OnBtnContrastClick()
    self:OpenReplacePopup()
end

function XUiGridTheatre4PropCard:OpenReplacePopup()
    XLuaUiManager.Open("UiTheatre4PopupReplace", self.ItemId, self.ReplaceCallback)
end

function XUiGridTheatre4PropCard:_InitCanvasGroup()
    if XTool.UObjIsNil(self._CanvasGroup) then
        self._CanvasGroup = self.Transform:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    end
end

function XUiGridTheatre4PropCard:PlayPropCardAnimation()
    self:PlayAnimation("GridPropCardEnable", function()
        self:SetAlpha(1)
    end)
end

return XUiGridTheatre4PropCard

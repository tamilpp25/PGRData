---@class XUiGridTheatre4Prop : XUiNode
---@field private _Control XTheatre4Control
local XUiGridTheatre4Prop = XClass(XUiNode, "XUiGridTheatre4Prop")

function XUiGridTheatre4Prop:OnStart(callback)
    self._Control:RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
    self.Select.gameObject:SetActiveEx(false)
    self.Lock.gameObject:SetActiveEx(false)
    self.Red.gameObject:SetActiveEx(false)
    self.ImgQuality = {
        [XEnumConst.Theatre4.ItemQuality.White] = self.ImgQualityWhite,
        [XEnumConst.Theatre4.ItemQuality.Green] = self.ImgQualityGreen,
        [XEnumConst.Theatre4.ItemQuality.Blue] = self.ImgQualityBlue,
        [XEnumConst.Theatre4.ItemQuality.Purple] = self.ImgQualityPurple,
        [XEnumConst.Theatre4.ItemQuality.Yellow] = self.ImgQualityYellow,
        [XEnumConst.Theatre4.ItemQuality.Gold] = self.ImgQualityGold,
        [XEnumConst.Theatre4.ItemQuality.Red] = self.ImgQualityRed,
    }
    self.Callback = callback
end

-- 获取藏品唯一Id
function XUiGridTheatre4Prop:GetUId()
    return self.UId or 0
end

-- 获取道具数据
---@return { UId:number, Id:number, Type:number, Count:number }
function XUiGridTheatre4Prop:GetItemData()
    return { UId = self.UId, Id = self.ItemId, Type = self.ItemType, Count = self.ItemCount }
end

---@param itemData { UId:number, Id:number, Type:number, Count:number }
function XUiGridTheatre4Prop:Refresh(itemData)
    if not itemData then
        return
    end
    self.UId = itemData.UId
    self.ItemId = itemData.Id
    self.ItemType = itemData.Type
    self.ItemCount = itemData.Count or 0
    self:RefreshItem()
end

function XUiGridTheatre4Prop:RefreshItem()
    -- 图标
    local icon = self._Control.AssetSubControl:GetAssetIcon(self.ItemType, self.ItemId)
    if icon then
        self.RImgIcon:SetRawImage(icon)
    end
    -- 名称
    self.TxtName.text = self._Control.AssetSubControl:GetAssetName(self.ItemType, self.ItemId)
    -- 品质
    local qualityColor = self._Control.AssetSubControl:GetAssetQuality(self.ItemType, self.ItemId)
    for k, v in pairs(self.ImgQuality) do
        v.gameObject:SetActiveEx(k == qualityColor)
    end
    -- 数量
    self.PanelNum.gameObject:SetActiveEx(self.ItemCount ~= 0)
    self.TxtNum.text = self.ItemCount
    -- 时间
    self.PanelTime.gameObject:SetActiveEx(XTool.IsNumberValid(self.UId))
    if XTool.IsNumberValid(self.UId) then
        local itemTime = self._Control:GetItemLeftDays(self.UId)
        if itemTime < 0 then
            self.PanelTime.gameObject:SetActiveEx(false)
        else
            self.TxtTime.text = XUiHelper.GetText("Theatre4ItemTimeLeft", itemTime)
        end
    end
end

-- 选择
function XUiGridTheatre4Prop:SetSelect(isSelect)
    self.Select.gameObject:SetActiveEx(isSelect)
end

-- 锁定
function XUiGridTheatre4Prop:SetLock(isLock)
    self.Lock.gameObject:SetActiveEx(isLock)
end

-- 遮罩
function XUiGridTheatre4Prop:SetMask(isMask)
    if not self.Mask then
        self.Mask = self.Lock.transform:FindTransform("Image")
    end
    if isMask then
        self:SetLock(isMask)
    end
    if self.Mask then
        self.Mask.gameObject:SetActiveEx(not isMask)
    end
end

-- 红点
function XUiGridTheatre4Prop:ShowRedDot(isShow)
    self.Red.gameObject:SetActiveEx(isShow)
end

-- 隐藏品质
function XUiGridTheatre4Prop:HideQuality()
    for _, v in pairs(self.ImgQuality) do
        v.gameObject:SetActiveEx(false)
    end
end

-- 播放动画
function XUiGridTheatre4Prop:PlayAnim(callback)
    self:PlayAnimation("GridPropEnable", callback)
end

function XUiGridTheatre4Prop:OnBtnClick()
    if self.Callback then
        self.Callback(self)
        return
    end
    XLuaUiManager.Open("UiTheatre4PopupItemDetail", self.ItemId, self.ItemType)
end

return XUiGridTheatre4Prop

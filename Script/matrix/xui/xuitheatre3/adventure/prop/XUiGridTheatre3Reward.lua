---@class XUiGridTheatre3Reward : XUiNode 套装展示子UI
---@field _Control XTheatre3Control
local XUiGridTheatre3Reward = XClass(XUiNode, "XUiGridTheatre3Reward")

function XUiGridTheatre3Reward:OnStart()
    self:InitUiObj()
    
    ---@type UnityEngine.RectTransform[]
    self._QualityObjDir = {
        [3] = self.ImgQualityBlue,
        [4] = self.ImgQualityPurple,
        [5] = self.ImgQualityOrange,
    }
    self._Control:RegisterClickEvent(self, self.BtnProp, self.OnClick)
end

--region Data - Getter
function XUiGridTheatre3Reward:GetId()
    return self._Id
end

function XUiGridTheatre3Reward:GetItemData()
    return self._ItemData
end
--endregion

--region Data - Setter
function XUiGridTheatre3Reward:_SetItemBgType(value)
    self._BgType = value
end

---@param eventStepItemType number XEnumConst.THEATRE3.EventStepItemType
---@param clickCb function
function XUiGridTheatre3Reward:SetData(id, eventStepItemType, clickCb)
    self._Id = id
    self._EventStepItemType = eventStepItemType
    self._ClickCb = clickCb
    local icon = self._Control:GetEventStepItemIcon(self._Id, self._EventStepItemType)
    local quality = self._Control:GetEventStepItemQuality(self._Id, self._EventStepItemType)
    if self._EventStepItemType == XEnumConst.THEATRE3.EventStepItemType.InnerItem then
        self:_SetItemBgType(self._Control:GetItemBgTypeById(self._Id))
    end
    self:Refresh(icon, quality, true)
end

---@param clickCb function
function XUiGridTheatre3Reward:SetNodeSlotData(icon, quality, clickCb, isALine)
    self._ClickCb = clickCb
    self:Refresh(icon, quality, isALine)
end

---@param itemData XTheatre3Item
function XUiGridTheatre3Reward:SetItemData(itemData)
    ---@type XTheatre3Item
    self._ItemData = itemData
end

function XUiGridTheatre3Reward:SetLockClick(value)
    self._LockClick = value
end
--endregion

--region Ui - Init
function XUiGridTheatre3Reward:InitUiObj()
    if not self.Select then
        ---@type UnityEngine.RectTransform
        self.Select = XUiHelper.TryGetComponent(self.Transform, "Select")
    end
    if not self.RImgIcon then
        ---@type UnityEngine.UI.RawImage
        self.RImgIcon = XUiHelper.TryGetComponent(self.Transform, "RImgIcon", "RawImage")
    end
    if not self.Lock then
        ---@type UnityEngine.RectTransform
        self.Lock = XUiHelper.TryGetComponent(self.Transform, "Lock")
    end
    if not self.Red then
        ---@type UnityEngine.RectTransform
        self.Red = XUiHelper.TryGetComponent(self.Transform, "Red")
    end
    if not self.ImgQualityOrange then
        ---@type UnityEngine.RectTransform
        self.ImgQualityOrange = XUiHelper.TryGetComponent(self.Transform, "ImgQualityOrange")
    end
    if not self.ImgQualityBlue then
        ---@type UnityEngine.RectTransform
        self.ImgQualityBlue = XUiHelper.TryGetComponent(self.Transform, "ImgQualityBlue")
    end
    if not self.ImgQualityPurple then
        ---@type UnityEngine.RectTransform
        self.ImgQualityPurple = XUiHelper.TryGetComponent(self.Transform, "ImgQualityPurple")
    end
    if not self.ImgQualityRed then
        ---@type UnityEngine.RectTransform
        self.ImgQualityRed = XUiHelper.TryGetComponent(self.Transform, "ImgQualityRed")
    end
    if not self.RawImage then
        self.RawImage = XUiHelper.TryGetComponent(self.Transform, "RawImage", "RawImage")
    end
    if not self.RawImageRed then
        ---@type UnityEngine.RectTransform
        self.RawImageRed = XUiHelper.TryGetComponent(self.Transform, "RawImageRed")
    end
end
--endregion

--region Ui - Refresh
function XUiGridTheatre3Reward:Refresh(icon, quality, isALine)
    if self._EventStepItemType == XEnumConst.THEATRE3.EventStepItemType.InnerItem and self._BgType then
        self:_Refresh(icon, quality, self._BgType < XEnumConst.THEATRE3.QuantumType.QuantumB)
    else
        self:_Refresh(icon, quality, isALine)
    end
end

function XUiGridTheatre3Reward:_Refresh(icon, quality, isALine)
    if self.RImgIcon then
        self.RImgIcon:SetRawImage(icon)
    end
    if XTool.IsNumberValid(self._Id) then
        -- 有Id 则直接读取图片路径 然后设置图片
        if self.RawImage then
            self.RawImage:SetRawImage(self._Control:GetItemBgUrlById(self._Id))
            self.RawImage.gameObject:SetActiveEx(true)
        end
        if self.RawImageRed then
            self.RawImageRed.gameObject:SetActiveEx(false)
        end
    else
        -- 没有Id 则按照A线B线设置图片
        if self.RawImage then
            self.RawImage:SetRawImage(self._Control:GetItemBgUrlByBgType(XEnumConst.THEATRE3.QuantumType.QuantumA))
            self.RawImage.gameObject:SetActiveEx(isALine)
        end
        if self.RawImageRed then
            self.RawImageRed:SetRawImage(self._Control:GetItemBgUrlByBgType(XEnumConst.THEATRE3.QuantumType.QuantumB))
            self.RawImageRed.gameObject:SetActiveEx(not isALine)
        end
    end
    if self.ImgQualityRed then
        self.ImgQualityRed.gameObject:SetActiveEx(false)
    end
    if not XTool.IsTableEmpty(self._QualityObjDir) then
        for i, obj in pairs(self._QualityObjDir) do
            obj.gameObject:SetActiveEx(i == quality)
        end
    end
end

function XUiGridTheatre3Reward:ShowRed(isShow)
    if self.Red then
        self.Red.gameObject:SetActiveEx(isShow)
    end
end

function XUiGridTheatre3Reward:ShowSelect(isShow)
    if self.Select then
        self.Select.gameObject:SetActiveEx(isShow)
    end
end
--endregion

--region Ui - BtnListener
function XUiGridTheatre3Reward:OnClick()
    if self._LockClick then
        return
    end
    if self._ClickCb then
        self._ClickCb(self)
        return
    end
    self._Control:OpenAdventureTips(self._Id, self._EventStepItemType)
end
--endregion

return XUiGridTheatre3Reward
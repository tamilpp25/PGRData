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
    XUiHelper.RegisterClickEvent(self, self.BtnProp, self.OnClick)
end

--region Data - Getter
function XUiGridTheatre3Reward:GetId()
    return self._Id
end
--endregion

--region Data - Setter
---@param eventStepItemType number XEnumConst.THEATRE3.EventStepItemType
---@param clickCb function
function XUiGridTheatre3Reward:SetData(id, eventStepItemType, clickCb)
    self._Id = id
    self._EventStepItemType = eventStepItemType
    self._ClickCb = clickCb
    self:Refresh()
end

---@param clickCb function
function XUiGridTheatre3Reward:SetNodeSlotData(icon, quality, clickCb)
    self._ClickCb = clickCb
    if self.RImgIcon and not string.IsNilOrEmpty(icon) then
        self.RImgIcon:SetRawImage(icon)
    else
        self.RImgIcon.gameObject:SetActiveEx(false)
    end
    if not XTool.IsTableEmpty(self._QualityObjDir) then
        for i, obj in pairs(self._QualityObjDir) do
            obj.gameObject:SetActiveEx(quality and i == quality)
        end
    end
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
end
--endregion

--region Ui - Refresh
function XUiGridTheatre3Reward:Refresh()
    local icon = self._Control:GetEventStepItemIcon(self._Id, self._EventStepItemType)
    local quality = self._Control:GetEventStepItemQuality(self._Id, self._EventStepItemType)
    if self.RImgIcon then
        self.RImgIcon:SetRawImage(icon)
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
    if self._ClickCb then
        self._ClickCb(self)
        return
    end
    XLuaUiManager.Open("UiTheatre3Tips", self._Id, self._EventStepItemType)
end
--endregion

return XUiGridTheatre3Reward
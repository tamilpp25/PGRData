---@class XUiGridTheatre3Prop : XUiNode
---@field _Control XTheatre3Control
---@field Parent XUiTheatre3Handbook
local XUiGridTheatre3Prop = XClass(XUiNode, "XUiGridTheatre3Prop")

function XUiGridTheatre3Prop:OnStart(callBack)
    self.CallBack = callBack
    XUiHelper.RegisterClickEvent(self, self.BtnProp, self.OnBtnPropClick)

    self.QualityObjDir = {
        [3] = self.ImgQualityBlue,
        [4] = self.ImgQualityPurple,
        [5] = self.ImgQualityOrange,
    }
end

---@param id number 套装id|物品id
function XUiGridTheatre3Prop:Refresh(id)
    if not XTool.IsNumberValid(id) then
        return
    end
    self.Id = id
    -- 图标
    local icon
    if self.Parent:CheckCurTypeIsProp() then
        icon = self._Control:GetEventStepItemIcon(id, XEnumConst.THEATRE3.EventStepItemType.InnerItem)
    end
    if self.Parent:CheckCurTypeIsSet() then
        local equipCfgList = self._Control:GetAllSuitEquip(id)
        if equipCfgList[1] and not string.IsNilOrEmpty(equipCfgList[1].Icon) then
            icon = equipCfgList[1].Icon
        end
    end
    if self.RImgIcon and icon then
        self.RImgIcon:SetRawImage(icon)
    end
    if self.Parent:CheckCurTypeIsProp() then
        --道具品质
        local quality = self._Control:GetEventStepItemQuality(id, XEnumConst.THEATRE3.EventStepItemType.InnerItem)
        if not XTool.IsTableEmpty(self.QualityObjDir) then
            for i, obj in pairs(self.QualityObjDir) do
                obj.gameObject:SetActiveEx(i == quality)
            end
        end
        --道具背景
        if not self.RawImage then
            ---@type UnityEngine.RectTransform
            self.RawImage = XUiHelper.TryGetComponent(self.Transform, "RawImage", "RawImage")
        end
        self.RawImage.gameObject:SetActiveEx(true)
        self.RawImage:SetRawImage(self._Control:GetItemBgUrlById(id))
        self.RawImageRed.gameObject:SetActiveEx(false)
        self.ImgQualityRed.gameObject:SetActiveEx(false)
    end
    self:RefreshStatus()
    self:RefreshRedPoint()
end

function XUiGridTheatre3Prop:RefreshStatus()
    local isProp = self.Parent:CheckCurTypeIsProp()
    local isSet = self.Parent:CheckCurTypeIsSet()
    local isUnlock = false
    if isProp then
        isUnlock = self._Control:CheckUnlockItemId(self.Id)
    elseif isSet then
        isUnlock = self._Control:CheckAnyEquipIdUnlock(self.Id)
    end
    self:SetIsLock(not isUnlock)
end

function XUiGridTheatre3Prop:RefreshRedPoint()
    local isProp = self.Parent:CheckCurTypeIsProp()
    local isSet = self.Parent:CheckCurTypeIsSet()
    local isRedPoint = false
    if isProp then
        isRedPoint = self._Control:CheckItemRedPoint(self.Id)
    elseif isSet then
        isRedPoint = self._Control:CheckEquipSuitRedPoint(self.Id)
    end
    self.Red.gameObject:SetActiveEx(isRedPoint)
end

function XUiGridTheatre3Prop:SetPropSelect(isSelect)
    if self.Select then
        self.Select.gameObject:SetActiveEx(isSelect)
    end
end

--设置是否显示锁
function XUiGridTheatre3Prop:SetIsLock(lock)
    if self.Lock then
        self.Lock.gameObject:SetActiveEx(lock)
    end
end

-- 点击藏品按钮时刷新红点
function XUiGridTheatre3Prop:ClickPropRefreshRedPoint()
    if self.Parent:CheckCurTypeIsProp() then
        local isRedPoint = self._Control:CheckItemRedPoint(self.Id)
        if isRedPoint then
            -- 保存点击缓存
            self._Control:SaveItemClickRedPoint(self.Id)
            self:RefreshRedPoint()
            self.Parent:RefreshPropRedPoint()
        end
    end
end

function XUiGridTheatre3Prop:OnBtnPropClick()
    self:ClickPropRefreshRedPoint()
    if self.CallBack then
        self.CallBack(self)
    end
end

return XUiGridTheatre3Prop
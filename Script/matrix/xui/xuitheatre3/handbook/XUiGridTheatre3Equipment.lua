---@class XUiGridTheatre3Equipment : XUiNode
---@field _Control XTheatre3Control
---@field Parent XUiPanelTheatre3PropDetail
local XUiGridTheatre3Equipment = XClass(XUiNode, "XUiGridTheatre3Equipment")

function XUiGridTheatre3Equipment:OnStart()
    XUiHelper.RegisterClickEvent(self, self.EquipmentGrid, self.OnEquipmentGridClick)
end

function XUiGridTheatre3Equipment:Refresh(id)
    self.Id = id
    local equipConfig = self._Control:GetEquipById(id)
    if self.TxtNum then
        self.TxtNum.text = XTool.ConvertRomanNumberString(equipConfig.PosType)
    end
    if self.ImgEquipmentBg then
        self.ImgEquipmentBg.gameObject:SetActiveEx(equipConfig.UseType ~= XEnumConst.THEATRE3.SuitUseType.Backend)
    end
    if self.ImgEquipmentBg2 then
        self.ImgEquipmentBg2.gameObject:SetActiveEx(equipConfig.UseType == XEnumConst.THEATRE3.SuitUseType.Backend)
    end
    if self.ImgEquipmentBg3 then
        self.ImgEquipmentBg3.gameObject:SetActiveEx(equipConfig.UseType ~= XEnumConst.THEATRE3.SuitUseType.Backend)
    end
    if self.ImgEquipmentBg4 then
        self.ImgEquipmentBg4.gameObject:SetActiveEx(equipConfig.UseType == XEnumConst.THEATRE3.SuitUseType.Backend)
    end
    if equipConfig.UseType ~= XEnumConst.THEATRE3.SuitUseType.Backend then
        if self.ImgEquipment1 then
            self.ImgEquipment1:SetRawImage(equipConfig.Icon)
        end
        if self.ImgEquipment3 then
            self.ImgEquipment3:SetRawImage(equipConfig.Icon)
        end
    else
        if self.ImgEquipment2 then
            self.ImgEquipment2:SetRawImage(equipConfig.Icon)
        end
        if self.ImgEquipment4 then
            self.ImgEquipment4:SetRawImage(equipConfig.Icon)
        end
    end
    self:RefreshStatus()
    self:RefreshRedPoint()
end

function XUiGridTheatre3Equipment:RefreshStatus()
    local isDisable = not self._Control:CheckEquipIdUnlock(self.Id)
    self.EquipmentGrid:SetDisable(isDisable)
end

function XUiGridTheatre3Equipment:RefreshRedPoint()
    local isRedPoint = self._Control:CheckEquipRedPoint(self.Id)
    self.EquipmentGrid:ShowReddot(isRedPoint)
end

function XUiGridTheatre3Equipment:OnEquipmentGridClick()
    self.Parent:OnHideSuitEffectDetail()
    -- 未解锁提示
    if not self._Control:CheckEquipIdUnlock(self.Id) then
        local desc = self._Control:GetClientConfig("Theatre3EquipNotLockTips", 1)
        local equipName = self._Control:GetEquipById(self.Id).EquipName
        XUiManager.TipMsg(string.format(desc, equipName))
        return
    end
    -- 刷新红点
    local isRedPoint = self._Control:CheckEquipRedPoint(self.Id)
    if isRedPoint then
        -- 保存点击缓存
        self._Control:SaveEquipClickRedPoint(self.Id)
        self.Parent.Parent:RefreshSuitGridRedPoint()
        self:RefreshRedPoint()
    end
    self:OnShowEquipTip()
end

function XUiGridTheatre3Equipment:OnShowEquipTip()
    self.EquipmentGrid:SetButtonState(CS.UiButtonState.Select)
    self._Control:OpenEquipmentTipByAlign(self.Id, nil, nil, function()
        self.EquipmentGrid:SetButtonState(CS.UiButtonState.Normal)
    end, self.Parent.Transform, XEnumConst.THEATRE3.TipAlign.Left)
end

return XUiGridTheatre3Equipment
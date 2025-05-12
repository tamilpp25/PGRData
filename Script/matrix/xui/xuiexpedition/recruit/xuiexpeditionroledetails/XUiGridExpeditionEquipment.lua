local XUiGridExpeditionEquipment = XClass(nil, "XUiGridExpeditionEquipment")

function XUiGridExpeditionEquipment:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

end

function XUiGridExpeditionEquipment:Refresh(templateId, breakNum, level, resonanceCount)
    if self.RImgIcon then
        self.RImgIcon:SetRawImage(XMVCA.XEquip:GetEquipIconPath(templateId, breakNum), nil, true)
    end

    --通用的横条品质色
    if self.ImgQuality then
        self.ImgQuality:SetSprite(XMVCA.XEquip:GetEquipQualityPath(templateId))
    end

    if self.TxtName then
        self.TxtName.text = XMVCA.XEquip:GetEquipName(templateId)
    end

    if self.TxtLevel then
        self.TxtLevel.text = level
    end

    for i = 1, XEnumConst.EQUIP.MAX_RESONANCE_SKILL_COUNT do
        local obj = self["ImgResonance" .. i]
        if obj then
            if XTool.IsNumberValid(resonanceCount) and resonanceCount >= i then
                local icon = XMVCA.XEquip:GetResoanceIconPath(true)
                self.RootUi:SetUiSprite(obj, icon)
                obj.gameObject:SetActiveEx(true)
            else
                obj.gameObject:SetActiveEx(false)
            end
        end
    end
    
    self:UpdateBreakthrough(breakNum)
end

function XUiGridExpeditionEquipment:UpdateBreakthrough(breakthroughNum)
    if XTool.UObjIsNil(self.ImgBreakthrough) then
        return
    end
    if breakthroughNum > 0 then
        local icon = XMVCA.XEquip:GetEquipBreakThroughSmallIcon(breakthroughNum)
        if icon then
            self.ImgBreakthrough:SetSprite(icon)
            self.ImgBreakthrough.gameObject:SetActiveEx(true)
        end
    else
        self.ImgBreakthrough.gameObject:SetActiveEx(false)
    end
end

return XUiGridExpeditionEquipment
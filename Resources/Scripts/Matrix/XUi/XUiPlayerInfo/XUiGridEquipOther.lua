local XUiGridEquipOther = XClass(nil, "XUiGridEquipOther")

function XUiGridEquipOther:Ctor(ui, rootUi, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ClickCb = clickCb
    self:InitAutoScript()
end

function XUiGridEquipOther:Refresh(equip)
    local templateId = equip.TemplateId

    if self.RImgIcon and self.RImgIcon:Exist() then
        self.RImgIcon:SetRawImage(XDataCenter.EquipManager.GetEquipIconBagPath(templateId, equip.Breakthrough), nil, true)
    end

    --通用的横条品质色
    if self.ImgQuality then
        self.RootUi.Parent:SetUiSprite(self.ImgQuality, XDataCenter.EquipManager.GetEquipQualityPath(templateId))
    end

    --装备专用的竖条品质色
    if self.ImgEquipQuality then
        self.RootUi.Parent:SetUiSprite(self.ImgEquipQuality, XDataCenter.EquipManager.GetEquipBgPath(templateId))
    end

    if self.TxtName then
        self.TxtName.text = XDataCenter.EquipManager.GetEquipName(templateId)
    end

    if self.TxtLevel then
        self.TxtLevel.text = equip.Level
    end

    if self.PanelSite and self.TxtSite then
        local equipSite = XDataCenter.EquipManager.GetEquipSiteByEquipData(equip)
        if equipSite and equipSite ~= XEquipConfig.EquipSite.Weapon then
            self.TxtSite.text = "0" .. equipSite
            self.PanelSite.gameObject:SetActiveEx(true)
        else
            self.PanelSite.gameObject:SetActiveEx(false)
        end
    end

    for i = 1, XEquipConfig.MAX_STAR_COUNT do
        if self["ImgGirdStar" .. i] then
            if i <= XDataCenter.EquipManager.GetEquipStar(templateId) then
                self["ImgGirdStar" .. i].transform.parent.gameObject:SetActiveEx(true)
            else
                self["ImgGirdStar" .. i].transform.parent.gameObject:SetActiveEx(false)
            end
        end
    end

    for i = 1, XEquipConfig.MAX_RESONANCE_SKILL_COUNT do
        local obj = self["ImgResonance" .. i]
        if obj then
            if equip.ResonanceInfo and equip.ResonanceInfo[i] then
                local icon = XEquipConfig.GetEquipResoanceIconPath(equip:IsEquipPosAwaken(i))
                self.RootUi.Parent:SetUiSprite(obj, icon)
                obj.gameObject:SetActiveEx(true)
            else
                obj.gameObject:SetActiveEx(false)
            end
        end
    end

    self:UpdateBreakthrough(equip)

end

function XUiGridEquipOther:UpdateBreakthrough(equip)
    if XTool.UObjIsNil(self.ImgBreakthrough) then
        return
    end

    local icon
    if equip.Breakthrough ~= 0 then
        icon = XEquipConfig.GetEquipBreakThroughSmallIcon(equip.Breakthrough)
    end

    if icon then
        self.RootUi.Parent:SetUiSprite(self.ImgBreakthrough, icon)
        self.ImgBreakthrough.gameObject:SetActiveEx(true)
    else
        self.ImgBreakthrough.gameObject:SetActiveEx(false)
    end
end

function XUiGridEquipOther:InitAutoScript()
    XTool.InitUiObject(self)
    CsXUiHelper.RegisterClickEvent(self.BtnClick,function() self:OnBtnClickClick() end)
end

function XUiGridEquipOther:OnBtnClickClick()
    if self.ClickCb then
        self.ClickCb()
    end
end

return XUiGridEquipOther
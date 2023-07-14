--==================
--装备显示控件
--==================
local XUiSBBCEquipGrid = XClass(nil, "XUiSBBCEquipGrid")

function XUiSBBCEquipGrid:Ctor(uiPrefab, clickCb)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.ClickCb = clickCb
    XUiHelper.RegisterClickEvent(self, self.RImgIcon, function() self:OnClick() end)
end

function XUiSBBCEquipGrid:Refresh(equip, breakNum, equipSite, isWeapon, level, resonanceCount)
    local templateId = equip.TemplateId
    if self.RImgIcon and self.RImgIcon:Exist() then
        self.RImgIcon:SetRawImage(XDataCenter.EquipManager.GetEquipIconBagPath(templateId, breakNum), nil, true)
    end

    --通用的横条品质色
    if self.ImgQuality then
        self.ImgQuality:SetSprite(XDataCenter.EquipManager.GetEquipQualityPath(templateId))
    end

    if self.TxtName then
        self.TxtName.text = XDataCenter.EquipManager.GetEquipName(templateId)
    end

    if self.TxtLevel then
        self.TxtLevel.text = level
    end

    if self.PanelSite and self.TxtSite then
        if equipSite and not isWeapon then
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
            if XTool.IsNumberValid(resonanceCount) and resonanceCount >= i or (equip.Id > 0 and XDataCenter.EquipManager.CheckEquipPosResonanced(equip.Id, i)) then
                local icon = XEquipConfig.GetEquipResoanceIconPath(XDataCenter.EquipManager.IsEquipPosAwaken(equip.Id, i))
                obj:SetSprite(icon)
                obj.gameObject:SetActiveEx(true)
            else
                obj.gameObject:SetActiveEx(false)
            end
        end
    end
    self:UpdateBreakthrough(breakNum)
end

function XUiSBBCEquipGrid:UpdateBreakthrough(breakthroughNum)
    if XTool.UObjIsNil(self.ImgBreakthrough) then
        return
    end
    if breakthroughNum > 0 then
        local icon = XEquipConfig.GetEquipBreakThroughSmallIcon(breakthroughNum)
        if icon then
            self.ImgBreakthrough:SetSprite(icon)
            self.ImgBreakthrough.gameObject:SetActiveEx(true)
        end
    else
        self.ImgBreakthrough.gameObject:SetActiveEx(false)
    end
end

function XUiSBBCEquipGrid:OnClick()
    if self.ClickCb then
        self.ClickCb(self.EquipId, self)
    end
end

return XUiSBBCEquipGrid
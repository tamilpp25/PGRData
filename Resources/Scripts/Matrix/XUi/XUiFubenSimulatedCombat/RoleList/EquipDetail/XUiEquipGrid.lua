--成员列表装备展示控件
local XUiSimulatedCombatEquipGrid = XClass(nil, "XUiSimulatedCombatEquipGrid")

function XUiSimulatedCombatEquipGrid:Ctor(ui, clickCb, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ClickCb = clickCb
    self:InitAutoScript()
    self:SetSelected(false)
end

function XUiSimulatedCombatEquipGrid:Refresh(templateId, breakNum, equipSite, isWeapon, level)
    if self.RImgIcon and self.RImgIcon:Exist() then
        self.RImgIcon:SetRawImage(XDataCenter.EquipManager.GetEquipIconBagPath(templateId, breakNum), nil, true)
    end

    --通用的横条品质色
    if self.ImgQuality then
        self.RootUi:SetUiSprite(self.ImgQuality, XDataCenter.EquipManager.GetEquipQualityPath(templateId))
    end

    --装备专用的竖条品质色
    if self.ImgEquipQuality then
        self.RootUi:SetUiSprite(self.ImgEquipQuality, XDataCenter.EquipManager.GetEquipBgPath(templateId))
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
            obj.gameObject:SetActiveEx(false)
        end
    end
    self:UpdateBreakthrough(breakNum)
end

function XUiSimulatedCombatEquipGrid:SetSelected(status)
    if XTool.UObjIsNil(self.ImgSelect) then
        return
    end
    self.ImgSelect.gameObject:SetActiveEx(status)
end

function XUiSimulatedCombatEquipGrid:IsSelected()
    return not XTool.UObjIsNil(self.ImgSelect) and self.ImgSelect.gameObject.activeSelf
end


function XUiSimulatedCombatEquipGrid:UpdateBreakthrough(breakthroughNum)
    if XTool.UObjIsNil(self.ImgBreakthrough) then
        return
    end
    if breakthroughNum > 0 then
        local icon = XEquipConfig.GetEquipBreakThroughSmallIcon(breakthroughNum)
        if icon then
            self.RootUi:SetUiSprite(self.ImgBreakthrough, icon)
            self.ImgBreakthrough.gameObject:SetActiveEx(true)
        end
    else
        self.ImgBreakthrough.gameObject:SetActiveEx(false)
    end
end

function XUiSimulatedCombatEquipGrid:InitAutoScript()
    XTool.InitUiObject(self)
    CsXUiHelper.RegisterClickEvent(self.BtnClick, function() self:OnBtnClickClick() end)
end

function XUiSimulatedCombatEquipGrid:OnBtnClickClick()
    if self.ClickCb then
        self.ClickCb(self.EquipId, self)
    end
end

return XUiSimulatedCombatEquipGrid
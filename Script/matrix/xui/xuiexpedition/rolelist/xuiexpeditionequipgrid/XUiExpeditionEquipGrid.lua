--虚像地平线成员列表装备展示控件
local XUiExpeditionEquipGrid = XClass(nil, "XUiExpeditionEquipGrid")

function XUiExpeditionEquipGrid:Ctor(ui, clickCb, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ClickCb = clickCb
    self:InitAutoScript()
    self:SetSelected(false)
end

function XUiExpeditionEquipGrid:Refresh(templateId, breakNum, equipSite, isWeapon, level, resonanceCount, awakeSlotList, awarenessSetPositions, resonanceInfo, characterId)
    if self.RImgIcon and self.RImgIcon:Exist() then
        self.RImgIcon:SetRawImage(XDataCenter.EquipManager.GetEquipIconBagPath(templateId, breakNum), nil, true)
    end

    --通用的横条品质色
    if self.ImgQuality then
        self.ImgQuality:SetSprite(XDataCenter.EquipManager.GetEquipQualityPath(templateId))
    end

    --装备专用的竖条品质色
    if self.ImgEquipQuality then
        self.ImgEquipQuality:SetSprite(XDataCenter.EquipManager.GetEquipBgPath(templateId))
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

    -- 公约驻守激活橙色边框
    local isActiveAwarenessOcuupy
    if self.ImgFrame then
        isActiveAwarenessOcuupy = awarenessSetPositions and awarenessSetPositions[equipSite]
        self.ImgFrame.gameObject:SetActiveEx(isActiveAwarenessOcuupy)
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
            if XTool.IsNumberValid(resonanceCount) and resonanceCount >= i then
                local isAwake = awakeSlotList and awakeSlotList[i] and true or false
                local icon = XEquipConfig.GetEquipResoanceIconPath(isAwake)
                -- local bindCharId = XDataCenter.EquipManager.GetResonanceBindCharacterId(templateId, i)
                -- local characterId = XDataCenter.EquipManager.GetEquipWearingCharacterId(templateId)

                local bindCharId = nil
                if resonanceInfo and resonanceInfo[i] then
                    bindCharId = resonanceInfo[i].CharacterId
                end

                if isAwake and isActiveAwarenessOcuupy and XTool.IsNumberValid(characterId) and characterId == bindCharId then
                    icon = CS.XGame.ClientConfig:GetString("AwarenessOcuupyActiveResonanced")
                end
                self.RootUi:SetUiSprite(obj, icon)
                obj.gameObject:SetActiveEx(true)
            else
                obj.gameObject:SetActiveEx(false)
            end
        end
    end
    self:UpdateBreakthrough(breakNum)
end

function XUiExpeditionEquipGrid:SetSelected(status)
    if XTool.UObjIsNil(self.ImgSelect) then
        return
    end
    self.ImgSelect.gameObject:SetActiveEx(status)
end

function XUiExpeditionEquipGrid:IsSelected()
    return not XTool.UObjIsNil(self.ImgSelect) and self.ImgSelect.gameObject.activeSelf
end


function XUiExpeditionEquipGrid:UpdateBreakthrough(breakthroughNum)
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

function XUiExpeditionEquipGrid:InitAutoScript()
    XTool.InitUiObject(self)
    CsXUiHelper.RegisterClickEvent(self.BtnClick, function() self:OnBtnClickClick() end)
end

function XUiExpeditionEquipGrid:OnBtnClickClick()
    if self.ClickCb then
        self.ClickCb(self.EquipId, self)
    end
end

return XUiExpeditionEquipGrid
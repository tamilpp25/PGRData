local CsXTextManagerGetText = CS.XTextManager.GetText

local XUiGridEquipResonanceSkillPreview = XClass(nil, "XUiGridEquipResonanceSkillPreview")

function XUiGridEquipResonanceSkillPreview:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridEquipResonanceSkillPreview:Refresh(params)
    self.Params = params
    self.RImgResonanceSkill:SetRawImage(params.skillInfo.Icon)
    self.TxtSkillName.text = params.skillInfo.Name
    self.TxtSkillDes.text = params.skillInfo.Description

    self.TxtSelect.gameObject:SetActiveEx(self.Params.skillInfo:IsSame(self.Params.selectSkillInfo))
    self:SetIsResonanceInfo()
end

function XUiGridEquipResonanceSkillPreview:SetIsResonanceInfo()
    local isResonance, slot = self:IsResonance()
    if isResonance then
        self.TxtSelectName.text = CsXTextManagerGetText("EquipResonanceIsExist", slot)
        self.BtnIsResonanc.gameObject:SetActiveEx(true)
    else
        self.BtnIsResonanc.gameObject:SetActiveEx(false)
    end
end

function XUiGridEquipResonanceSkillPreview:IsResonance()
    -- 忽略显示已共鸣信息
    if self.Params.isIgnoreResonance then
        return
    end

    local equip = XMVCA.XEquip:GetEquip(self.Params.equipId)
    if equip.ResonanceInfo then
        for i,v in pairs(equip.ResonanceInfo) do
            local bindCharacterId = v.CharacterId
            if bindCharacterId == self.Params.selectCharacterId then
                local skillInfo = XMVCA.XEquip:GetResonanceSkillInfo(self.Params.equipId, v.Slot)
                if XMVCA.XEquip:IsClassifyEqualByEquipId(self.Params.equipId, XEnumConst.EQUIP.CLASSIFY.AWARENESS) then
                    if self.Params.skillInfo:IsSame(skillInfo) and v.Slot == self.Params.pos then
                        return true, v.Slot
                    end
                else
                    if self.Params.skillInfo:IsSame(skillInfo) then
                        return true, v.Slot
                    end
                end
            end
        end
    end
end

function XUiGridEquipResonanceSkillPreview:GetSkillInfo()
    return self.Params.skillInfo
end

return XUiGridEquipResonanceSkillPreview
local XUiGridEquipResonanceSkillChangeV2P6 = XClass(nil, "XUiGridEquipResonanceSkillChangeV2P6")

function XUiGridEquipResonanceSkillChangeV2P6:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent

    XTool.InitUiObject(self)

    self.BtnClick.CallBack = function()
        self:OnBtnClick()
    end
end
function XUiGridEquipResonanceSkillChangeV2P6:Refresh(equipId, skillInfo)
    self.EquipId = equipId
    self.SkillInfo = skillInfo

    self:UpdateView()
end

function XUiGridEquipResonanceSkillChangeV2P6:UpdateView()
    self.TxtSkillName.text = self.SkillInfo.Name
    self.TxtSkillDes.text = self.SkillInfo.Description
    self.RImgResonanceSkill:SetRawImage(self.SkillInfo.Icon)
end

-- 刷新选中状态
function XUiGridEquipResonanceSkillChangeV2P6:UpdateSelectState(resonancePosSkillDic)
    for pos, skillId in pairs(resonancePosSkillDic) do
        if skillId == self.SkillInfo.Id then
            self.TextCurPos.text = "0" .. pos
            self.Select.gameObject:SetActiveEx(true)
            return
        end
    end

    self.Select.gameObject:SetActiveEx(false)
end

function XUiGridEquipResonanceSkillChangeV2P6:OnBtnClick()
    self.Parent:OnGridSkillClick(self.SkillInfo.Id)
end

return XUiGridEquipResonanceSkillChangeV2P6
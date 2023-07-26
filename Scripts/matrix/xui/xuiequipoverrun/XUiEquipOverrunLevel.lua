local XUiEquipOverrunLevel = XLuaUiManager.Register(XLuaUi, "UiEquipOverrunLevel")

function XUiEquipOverrunLevel:OnAwake()
    self:SetButtonCallBack()
end

function XUiEquipOverrunLevel:OnStart(equipId, level)
    self.EquipId = equipId
    self.Level = level
    self:Refresh()
end

function XUiEquipOverrunLevel:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

-- 刷新界面
function XUiEquipOverrunLevel:Refresh()
    local equip = XDataCenter.EquipManager.GetEquip(self.EquipId)

    -- 等级
    local overrunCfgs = XEquipConfig.GetWeaponOverrunCfgsByTemplateId(equip.TemplateId)
    for i = 1, #overrunCfgs do
        self["IconActiveLevel" .. i].gameObject:SetActiveEx(self.Level >= i)
    end

    -- 描述
    local deregulateUICfg = XEquipConfig.GetWeaponDeregulateUICfg(self.Level)
    self.TxtLevel.text = deregulateUICfg.LvUpTips
    self.TxtDetail.text = overrunCfgs[self.Level].Desc
end

return XUiEquipOverrunLevel
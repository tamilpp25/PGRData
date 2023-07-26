local XUiGridColorTableCaptain = XClass(nil, "UiGridColorTableCaptain")

function XUiGridColorTableCaptain:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.CaptainCfg = nil -- 领队配置表数据

    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridColorTableCaptain:InitUiObject()

end

function XUiGridColorTableCaptain:Refresh(base, captainCfg)
    self.Base = base
    self.CaptainCfg = captainCfg

    self.RawImage:SetRawImage(captainCfg.Icon)
    self.RImgSkillIcon:SetRawImage(captainCfg.SkillIcon)
    self.TxtSkillName.text = captainCfg.SkillName
    self.TxtSkillDesc.text = captainCfg.SkillDesc
end

function XUiGridColorTableCaptain:ShowSelected(isShow)
    self.ImgSelect.gameObject:SetActiveEx(isShow)
end

function XUiGridColorTableCaptain:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

function XUiGridColorTableCaptain:OnBtnClick()
    self.Base:OnBtnCaptainSelect(self.CaptainCfg.Id)
end

return XUiGridColorTableCaptain

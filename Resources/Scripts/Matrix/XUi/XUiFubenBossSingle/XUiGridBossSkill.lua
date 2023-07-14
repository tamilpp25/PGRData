local XUiGridBossSkill = XClass(nil, "XUiGridBossSkill")

function XUiGridBossSkill:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridBossSkill:Refresh(title, desc, isHideBoss)
    self.TxtTitle.text = title
    self.TxtDesc.text = desc
    self.ImgBg.gameObject:SetActiveEx(not isHideBoss)
    self.ImgBgHb.gameObject:SetActiveEx(isHideBoss)
end

return XUiGridBossSkill

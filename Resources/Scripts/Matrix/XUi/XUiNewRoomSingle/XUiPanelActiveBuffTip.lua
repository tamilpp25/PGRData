local XUiPanelActiveBuffTip = XClass(nil, "XUiPanelActiveBuffTip")

function XUiPanelActiveBuffTip:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiPanelActiveBuffTip:AutoAddListener()
    self.BtnClose.CallBack = function() self:Hide() end
    self.BtnTanchuangClose.CallBack = function() self:Hide() end
end

function XUiPanelActiveBuffTip:Show(activeBuffCfg)
    if self.CfgId == activeBuffCfg.Id then
        self.GameObject:SetActiveEx(true)
        return
    end

    self.CfgId = activeBuffCfg.Id
    self:Refresh(activeBuffCfg)
    self.GameObject:SetActiveEx(true)
end

function XUiPanelActiveBuffTip:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelActiveBuffTip:Refresh(activeBuffCfg)
    self.RImgOnIcon:SetRawImage(activeBuffCfg.OnIcon)
    self.RImgOffIcon:SetRawImage(activeBuffCfg.OffIcon)
    self.TxtTile.text = activeBuffCfg.Title
    local description = string.gsub(activeBuffCfg.Desc, "\\n", "\n")
    self.TxtDesc.text = description
end

return XUiPanelActiveBuffTip
local CSXTextManagerGetText = CS.XTextManager.GetText

--图标的说明
local XUiGridRpgMakerGameRecord = XClass(nil, "XUiGridRpgMakerGameRecord")

function XUiGridRpgMakerGameRecord:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
end

function XUiGridRpgMakerGameRecord:Refresh(hintIconKey)
    local icon = XRpgMakerGameConfigs.GetRpgMakerGameHintIcon(hintIconKey)
    self.ImgIconContent:SetRawImage(icon)

    local iconName = XRpgMakerGameConfigs.GetRpgMakerGameHintIconName(hintIconKey)
    self.TxtContent.text = iconName
end

return XUiGridRpgMakerGameRecord
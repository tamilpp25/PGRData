local XUiGridTipsInfo = XClass(nil, "XUiGridTipsInfo")
local CSTextManagerGetText = CS.XTextManager.GetText
local CSXGameClientConfig = CS.XGame.ClientConfig
function XUiGridTipsInfo:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridTipsInfo:UpdateData(data,IsShowCondition)
    if data then
        local infoColor = CSXGameClientConfig:GetString("WorldBossUnLockInfoColor")
        self.TitleText.text = data:GetInfoTitle()
        self.TxtBuffDescription.text = data:GetInfoText()
        self.TxtBuffDescription.color = XUiHelper.Hexcolor2Color(IsShowCondition and data:GetInfoTextColor() or infoColor)
        self.TxtBuffCondition.text = data:GetLockDesc()
        self.TxtBuffCondition.color = XUiHelper.Hexcolor2Color(data:GetLockDescColor())
        self.TxtBuffCondition.gameObject:SetActiveEx(IsShowCondition)
    end
end

return XUiGridTipsInfo
--关卡详细页面目标项控件
local XUiExpeditionTargetGrid = XClass(nil, "XUiExpeditionTargetGrid")

function XUiExpeditionTargetGrid:Ctor(uiGameObject)
    XTool.InitUiObjectByUi(self, uiGameObject)
end

function XUiExpeditionTargetGrid:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiExpeditionTargetGrid:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiExpeditionTargetGrid:SetStarActive(value)
    self.ImgStar.gameObject:SetActiveEx(value)
end

function XUiExpeditionTargetGrid:SetText(text)
    self.TxtText.text = text
end

return XUiExpeditionTargetGrid
-- 招募公示标题控件
local XUiExpeditionPublicityTitle = XClass(nil, "XUiExpeditionPublicityTitle")

function XUiExpeditionPublicityTitle:Ctor(ui)
    self.GameObject = ui
    self.Transform = ui.transform
    self.TitleLabel = self.Transform:GetComponent("Text")
end
--================
--刷新星级文本
--================
function XUiExpeditionPublicityTitle:RefreshTitle(text)
    if text and self.TitleLabel then
        self.TitleLabel.text = CS.XTextManager.GetText("ExpeditionPBTitle", text)
    else
        self.GameObject:SetActiveEx(false)
    end
end
--================
--设置标题
--================
function XUiExpeditionPublicityTitle:SetTitle(text)
    if text and self.TitleLabel then
        self.TitleLabel.text = text
    end
end

return XUiExpeditionPublicityTitle
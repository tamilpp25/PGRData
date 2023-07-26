local XUiPanelReview = XClass(nil, "XUiPanelReview")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiPanelReview:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
end

function XUiPanelReview:AddEventListener()

end

function XUiPanelReview:RemoveEventListener()

end

function XUiPanelReview:SetButtonCallBack()

end

function XUiPanelReview:ShowPanel(type)
    local hintText = ""
    if type == XGuildWarConfig.ActionShowType.Now then
        hintText = CSTextManagerGetText("GuildWarNowActionShow")
    elseif type == XGuildWarConfig.ActionShowType.History then
        hintText = CSTextManagerGetText("GuildWarHistoryActionShow")
    end
    self.TxtReview.text = hintText
    self.GameObject:SetActiveEx(true)
    self.Base:PlayAnimationWithMask("PanelReviewEnable")
end

function XUiPanelReview:HidePanel()
    self.Base:PlayAnimationWithMask("PanelReviewDisable", function ()
            self.GameObject:SetActiveEx(false)
    end)
end

return XUiPanelReview
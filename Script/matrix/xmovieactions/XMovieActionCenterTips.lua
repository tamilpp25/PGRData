local XMovieActionCenterTips = XClass(XMovieActionBase, "XMovieActionCenterTips")

function XMovieActionCenterTips:Ctor(actionData)
    local params = actionData.Params

    self.Content = params[1]
    self.IsHide = params[2] == "1"
    self.FontSize = params[3]
    self.FontColor = params[4]
    self.IsLeft = params[5] == "1"
    self.IsBgHide = params[6] == "1"
end

function XMovieActionCenterTips:OnInit()
    self.UiRoot.PanelCenterTip.gameObject:SetActiveEx(not self.IsHide)
    if self.IsHide then
        return
    end

    local content = self.Content
    if self.FontSize and self.FontColor then
        content = string.format("<size=%s><color=#%s>%s</color></size>", self.FontSize, self.FontColor, self.Content)
    elseif self.FontSize then
        content = string.format("<size=%s>%s</size>", self.FontSize, self.Content)
    elseif self.FontColor then
        content = string.format("<color=#%s>%s</color>", self.FontColor, self.Content)
    end
    self.UiRoot.TxtCenterTipDescMid.text = content
    self.UiRoot.TxtCenterTipDescMid.gameObject:SetActiveEx(not self.IsLeft)
    self.UiRoot.TxtCenterTipDescLeft.text = content
    self.UiRoot.TxtCenterTipDescLeft.gameObject:SetActiveEx(self.IsLeft)
    self.UiRoot.PanelCenterTipBg.enabled = not self.IsBgHide
end

return XMovieActionCenterTips
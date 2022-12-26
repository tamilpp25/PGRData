local XUiMessageGridAction = XClass(nil, "XUiMessageGridAction")

local alphaSinScale = 10

function XUiMessageGridAction:Ctor(uiRoot, ui)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.BtnClick.CallBack = function() self.UiRoot:OnActionClick(self.ActionData, self) end
end

function XUiMessageGridAction:Refresh(actionData)
    self.ImgCurProgress.fillAmount = 0
    if not actionData then
        self:UpdatePlayStatus(false)
        return
    end
    self.ActionData = actionData
    self.UiRoot:SetUiSprite(self.ImgHead, actionData.HeadIcon)
    if actionData.ActionType == XMoeWarConfig.ActionType.Intro then
        self.TxtTitle.text = CS.XTextManager.GetText("MoeWarMessageIntro")
    elseif actionData.ActionType == XMoeWarConfig.ActionType.Thank then
        self.TxtTitle.text = CS.XTextManager.GetText("MoeWarMessageThank")
    end
    self:UpdatePlayStatus(self.ActionData.IsPlay)
end

function XUiMessageGridAction:UpdatePlayStatus(isPlay)
    self.ActionData.IsPlay = isPlay
    self.IconPlay.gameObject:SetActiveEx(not isPlay)
    self.IconPause.gameObject:SetActiveEx(isPlay)
    self.IconAction.gameObject:SetActiveEx(isPlay)
    self.IconActionCanvasGroup.alpha = 0
end

function XUiMessageGridAction:HidePlayStatus()
    self.IconPlay.gameObject:SetActiveEx(false)
    self.IconPause.gameObject:SetActiveEx(false)
    self.IconAction.gameObject:SetActiveEx(false)
end

function XUiMessageGridAction:UpdateProgress(progress)
    progress = (progress >= 1) and 1 or progress
    self.ImgCurProgress.fillAmount = progress
end

function XUiMessageGridAction:UpdateActionAlpha(count)
    local alpha = math.sin(count / alphaSinScale)
    self.IconActionCanvasGroup.alpha = alpha
end

function XUiMessageGridAction:GetActionType()
    if not self.ActionData then return 0 end
    return self.ActionData.ActionType
end

return XUiMessageGridAction
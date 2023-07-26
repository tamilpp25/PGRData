local XUiGridTRPGMapCardMini = XClass(nil, "XUiGridTRPGMapCardMini")

function XUiGridTRPGMapCardMini:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
end

function XUiGridTRPGMapCardMini:Refresh(cardId, isCurrentStand, isNextPos, isDisposeableForeverFinished)
    local icon = XTRPGConfigs.GetMazeCardMiniIcon(cardId)
    if icon then
        self.UiRoot:SetUiSprite(self.ImgIcon, icon)
        self.ImgIcon.gameObject:SetActiveEx(not isCurrentStand)
    else
        self.ImgIcon.gameObject:SetActiveEx(false)
    end

    if self.ImgBg then
        local showBg = not XTRPGConfigs.CheckMazeCardType(cardId, XTRPGConfigs.CardType.Block)
        self.ImgBg.gameObject:SetActiveEx(showBg)
    end

    self.ImgIconMe.gameObject:SetActiveEx(isCurrentStand)
    self.ImgKuang.gameObject:SetActiveEx(isNextPos)

    if self.PaneCompleted then
        self.PaneCompleted.gameObject:SetActiveEx(isDisposeableForeverFinished)
    end
end

return XUiGridTRPGMapCardMini
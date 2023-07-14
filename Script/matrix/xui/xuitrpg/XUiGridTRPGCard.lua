local XUiGridTRPGCard = XClass(nil, "XUiGridTRPGCard")

function XUiGridTRPGCard:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self.BtnClick.CallBack = function() self:OnClickBtnClick() end
end

function XUiGridTRPGCard:Refresh(cardId, isNodeReachable, isCardReachable, clickCb, finishedCardId)
    self.IsCardReachable = isCardReachable
    self.ClickCb = clickCb
    self.CardId = cardId
    self.IsFinished = finishedCardId and true or nil
    cardId = finishedCardId or cardId

    if self.RImgBg then
        if isNodeReachable then
            local cardIconR = XTRPGConfigs.GetMazeCardIconR(cardId)
            if cardIconR then
                self.RImgBg:SetRawImage(cardIconR)
            end
            self.RImgBg.gameObject:SetActiveEx(true)
        else
            self.RImgBg.gameObject:SetActiveEx(false)
        end
    end

    if self.ImgBg then
        if not isNodeReachable then
            local cardIcon = XTRPGConfigs.GetMazeCardIcon(cardId)
            if cardIcon then
                self.UiRoot:SetUiSprite(self.ImgBg, cardIcon)
            end
            self.ImgBg.gameObject:SetActiveEx(true)
        else
            self.ImgBg.gameObject:SetActiveEx(false)
        end
    end

    if self.ImgTypeIcon then
        local cardTypeIcon = XTRPGConfigs.GetMazeCardTypeIcon(cardId)
        if cardTypeIcon then
            self.UiRoot:SetUiSprite(self.ImgTypeIcon, cardTypeIcon)
        end
    end

    if self.Tag then
        local showTag = XTRPGConfigs.IsMazeCardShowTag(cardId)
        self.Tag.gameObject:SetActiveEx(showTag)
    end

    if self.RImgBgDisable then
        self.RImgBgDisable.enabled = false--not isCardReachable
    end

    local cardOrder = XTRPGConfigs.GetMazeCardOrder(cardId)
    self.BtnClick:SetNameByGroup(0, cardOrder)

    local cardName = XTRPGConfigs.GetMazeCardName(cardId)
    self.BtnClick:SetNameByGroup(1, cardName)

    self.BtnClick:SetDisable(not isCardReachable)
end

function XUiGridTRPGCard:OnClickBtnClick()
    if not self.IsCardReachable then
        XUiManager.TipText("TRPGMazeCardUnReach")
        return
    end

    local cardId = self.CardId
    if XTRPGConfigs.CheckMazeCardType(cardId, XTRPGConfigs.CardType.Random)
    and not self.IsFinished
    then
        if self.AnimRImgBgDisable then

            local stopCb
            stopCb = function(director)
                self.ClickCb()
                self.AnimRImgBgDisable.gameObject:SetActiveEx(false)
                self.AnimRImgBgDisable:stopped('-', stopCb)

                XLuaUiManager.SetMask(false)

            end

            XLuaUiManager.SetMask(true)

            self.AnimRImgBgDisable:stopped('+', stopCb)
            self.AnimRImgBgDisable.gameObject:SetActiveEx(true)

        else
            self.ClickCb()
        end
    elseif XTRPGConfigs.CheckMazeCardType(cardId, XTRPGConfigs.CardType.Over) then
        XDataCenter.TRPGManager.TipQuitMaze(self.ClickCb)
    else
        self.ClickCb()
    end
end

return XUiGridTRPGCard
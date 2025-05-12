local XChessPursuitCtrl = require("XUi/XUiChessPursuit/XChessPursuitCtrl")
local XUiChessPursuitCardGrid = XClass(nil, "XUiChessPursuitCardGrid")

local QUALITY_COUNT = 3

function XUiChessPursuitCardGrid:Ctor(ui, uiRoot, cardIndex, mapId)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.CardIndex = cardIndex
    self.MapId = mapId
    XTool.InitUiObject(self)
end

function XUiChessPursuitCardGrid:Dispose()

end

function XUiChessPursuitCardGrid:Refresh(usedToGrid, usedToBoss, sceneType)
    local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.MapId)
    local bossIsClear = chessPursuitMapDb:IsClear()
    local cards = chessPursuitMapDb:GetBuyedCards()
    local card = cards[self.CardIndex]
    if card then
        local isUse = self:CheckIsUse(card.Id, usedToGrid, usedToBoss)
        local disable = isUse or bossIsClear or sceneType == XChessPursuitCtrl.SCENE_UI_TYPE.BOSS_ROUND
        self.CardCfg = XChessPursuitConfig.GetChessPursuitCardTemplate(card.CardCfgId)
        self:SetInfo()
        self:SetDisable(disable)
    else
        self.CardCfg = nil
    end

    self:SetActive(card and true or false)
end

function XUiChessPursuitCardGrid:CheckIsUse(myCardId, usedToGrid, usedToBoss)
    for gridIndex, list in pairs(usedToGrid) do
        for i, cardId in ipairs(list) do
            if cardId == myCardId then
                return true
            end
        end
    end

    for i, cardId in pairs(usedToBoss) do
        if cardId == myCardId then
            return true
        end
    end

    return false
end

function XUiChessPursuitCardGrid:SetInfo()
    local typeNames = {
        "Normal",
        "Press",
        "Select",
        "Disable",
    }

    for i, v in ipairs(typeNames) do
        self["RawImageIcon_" .. v]:SetRawImage(self.CardCfg.Icon)
    end

    for i, v in ipairs(typeNames) do
        self["RawImageKuang_" .. v]:SetRawImage(self.CardCfg.QualityIcon)
    end

    for i, v in ipairs(typeNames) do
        self["TxtCardNum_" .. v].text = ""
    end

    self.BtnCards:SetName(self.CardCfg.Name)
end

function XUiChessPursuitCardGrid:SetDisable(isDisable)
    self.RawImageDisable.gameObject:SetActiveEx(isDisable)
    self.BtnCards:SetDisable(isDisable)

    for i = 1, QUALITY_COUNT do
        if not isDisable and self.CardCfg then
            self["Effect" .. i].gameObject:SetActiveEx(i == self.CardCfg.Quality)
        else
            self["Effect" .. i].gameObject:SetActiveEx(false)
        end
    end
end

function XUiChessPursuitCardGrid:GetCardIndex()
    return self.CardIndex
end

function XUiChessPursuitCardGrid:SetActive(isActive)
    self.GameObject:SetActiveEx(isActive)
end

return XUiChessPursuitCardGrid
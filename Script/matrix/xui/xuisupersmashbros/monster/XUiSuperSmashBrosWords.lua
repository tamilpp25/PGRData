--================
--怪物词缀详细页面
--================
local XUiSuperSmashBrosWords = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosWords")

function XUiSuperSmashBrosWords:OnStart(fightEventIds)
    self:InitPanels()
    self.WordsList:Refresh(fightEventIds)
end

function XUiSuperSmashBrosWords:InitPanels()
    self:InitDynamicTable()
    self:InitBtns()
end

function XUiSuperSmashBrosWords:InitDynamicTable()
    local script = require("XUi/XUiSuperSmashBros/Monster/DTable/XUiSSBWordsWordsList")
    self.WordsList = script.New(self)
end

function XUiSuperSmashBrosWords:InitBtns()
    self.BtnTanchuangClose.CallBack = function() self:OnClickClose() end
    if self.BtnClose then self.BtnClose.CallBack = function() self:OnClickClose() end end
end

function XUiSuperSmashBrosWords:OnClickClose()
    self:Close()
end
local textManager = CS.XTextManager
local tableInsert = table.insert

local XUiClickClearPanelGeneralDefault = require("XUi/XUiClickClearGame/XUiClickClearPanelGeneralDefault")
local XUiClickClearPanelGeneralClearance = require("XUi/XUiClickClearGame/XUiClickClearPanelGeneralClearance")
local XUiClickClearPanelGeneralFailure = require("XUi/XUiClickClearGame/XUiClickClearPanelGeneralFailure")

local ConfirmBtnNames = {
    textManager.GetText("StartGame"),
    textManager.GetText("ConfirmText"),
    textManager.GetText("ConfirmText"),
}

local XUiClickClearPanelGeneral = XClass(nil, "XUiClickClearPanelGeneral")

function XUiClickClearPanelGeneral:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
    self:InitChildrenPanel()
end

function XUiClickClearPanelGeneral:Init()
    self.BtnTongBlack.CallBack = function () self:OnClickBtnConfirm() end
end

function XUiClickClearPanelGeneral:InitChildrenPanel()
    self.DefaultPanel = XUiClickClearPanelGeneralDefault.New(self.PanelDefault.gameObject, self)
    self.ClearancePanel = XUiClickClearPanelGeneralClearance.New(self.PanelClearance.gameObject, self)
    self.FailurePanel = XUiClickClearPanelGeneralFailure.New(self.PanelFailure.gameObject, self)
    self.PanelChildren = {}
    self.PanelChildren = {
        self.DefaultPanel,
        self.ClearancePanel,
        self.FailurePanel,
    }
end

function XUiClickClearPanelGeneral:Show(panelState)
    self.GameObject:SetActiveEx(true)
    self:ChangeState(panelState)
    
end

function XUiClickClearPanelGeneral:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiClickClearPanelGeneral:HideAllChildrenPanel()
    for _,v in ipairs(self.PanelChildren) do
        v:Hide()
    end
end

function XUiClickClearPanelGeneral:ChangeState(panelState)
    self:HideAllChildrenPanel()
    self.PanelChildren[panelState]:Show()
    self.BtnTongBlack:SetName(ConfirmBtnNames[panelState])
    self.CurPanelState = panelState
end

function XUiClickClearPanelGeneral:OnClickBtnConfirm()
    if self.CurPanelState == XDataCenter.XClickClearGameManager.GeneralPanelStates.Default then
        XDataCenter.XClickClearGameManager.StartGame()
    elseif self.CurPanelState == XDataCenter.XClickClearGameManager.GeneralPanelStates.Clearance then
        XDataCenter.XClickClearGameManager.ResetGame()
    elseif self.CurPanelState == XDataCenter.XClickClearGameManager.GeneralPanelStates.Failure then
        XDataCenter.XClickClearGameManager.ResetGame()
    end
end

return XUiClickClearPanelGeneral
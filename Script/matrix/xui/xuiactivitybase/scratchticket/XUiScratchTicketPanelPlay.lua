--
local XUiScratchTicketPanelPlay = XClass(nil, "XUiScratchTicketPanelPlay")

local PANEL_INDEX = {
        Ready = 1,
        Preview = 2,
        Grids = 3,
        Chose = 4,
        SelectBlue = 5,
        SelectRed = 6,
        WrongAnswer = 7,
        CorrectAnswer = 8,
        BtnExchange = 9,
        BtnDetermine = 10
    }

function XUiScratchTicketPanelPlay:Ctor(uiGameObject, controller, rootUi)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self.Controller = controller
    self.RootUi = rootUi
    self:InitPanels()
end

function XUiScratchTicketPanelPlay:InitPanels()
    self.Ticket = self.Controller:GetTicket()
    self.ChildPanels = {}
    self:InitPanelReady()
    self:InitPanelPreview()
    self:InitPanelGrids()
    self:InitPanelChose()
    self:InitPanelSelectChose()
    self.ChildPanels[PANEL_INDEX.WrongAnswer] = self.PanelWrongAnswer
    self.ChildPanels[PANEL_INDEX.CorrectAnswer] = self.PanelCorrectAnswer
    self:InitButtons()
end

function XUiScratchTicketPanelPlay:InitPanelReady()
    local panelScript = require("XUi/XUiActivityBase/ScratchTicket/XUiScratchTicketPanelReady")
    self.ReadyPanel = panelScript.New(self.PanelReady, self.Controller, self)
    self.ChildPanels[PANEL_INDEX.Ready] = self.ReadyPanel
end

function XUiScratchTicketPanelPlay:InitPanelPreview()
    local panelScript = require("XUi/XUiActivityBase/ScratchTicket/XUiScratchTicketPanelPreview")
    self.PreviewPanel = panelScript.New(self.PanelPreview, self.Controller, self)
    self.ChildPanels[PANEL_INDEX.Preview] = self.PreviewPanel
end

function XUiScratchTicketPanelPlay:InitPanelGrids()
    local panelScript = require("XUi/XUiActivityBase/ScratchTicket/XUiScratchTicketPanelGrids")
    self.GridsPanel = panelScript.New(self.PanelGrids, self.Controller, self)
    self.ChildPanels[PANEL_INDEX.Grids] = self.GridsPanel
end

function XUiScratchTicketPanelPlay:InitPanelChose()
    local panelScript = require("XUi/XUiActivityBase/ScratchTicket/XUiScratchTicketPanelChose")
    self.ChosePanel = panelScript.New(self.PanelChose, self.Controller, self)
    self.ChildPanels[PANEL_INDEX.Chose] = self.ChosePanel
end

function XUiScratchTicketPanelPlay:InitPanelSelectChose()
    local panelScript = require("XUi/XUiActivityBase/ScratchTicket/XUiScratchTicketPanelSelectChose")
    self.SelectBluePanel = panelScript.New(self.PanelSelectBlueGrids, self.Controller, self)
    self.SelectRedPanel = panelScript.New(self.PanelSelectRedGrids, self.Controller, self)
    self.ChildPanels[PANEL_INDEX.SelectBlue] = self.SelectBluePanel
    self.ChildPanels[PANEL_INDEX.SelectRed] = self.SelectRedPanel
end

function XUiScratchTicketPanelPlay:SelectChose(index)
    self.ChoseSelect = index
    self.SelectBluePanel:SelectChose(index)
end

function XUiScratchTicketPanelPlay:InitButtons()
    self.BtnExchange.CallBack = function() self:OnClickBtnExchange() end
    self.BtnDetermine.CallBack = function() self:OnClickBtnDetermine() end
    self.BtnExchange.gameObject:SetActiveEx(false)
    self.BtnDetermine.gameObject:SetActiveEx(false)
    self.ChildPanels[PANEL_INDEX.BtnExchange] = self.BtnExchange
    self.ChildPanels[PANEL_INDEX.BtnDetermine] = self.BtnDetermine
end

function XUiScratchTicketPanelPlay:GetTicket()
    if not self.Ticket then
        self.Ticket = self.Controller:GetTicket()
    end
    return self.Ticket
end

function XUiScratchTicketPanelPlay:OnOpenGrid()
    self:GetTicket()
    self.GridsPanel:Refresh()
    self.PreviewPanel:Refresh()
    if self.Controller:CheckPreviewFinish() then
        self:ShowChooseChose()
    end
end

function XUiScratchTicketPanelPlay:ShowChildPanel(panelIndexGroup)
    for index, panel in pairs(self.ChildPanels) do
        if panelIndexGroup[index] then
            if panel["ShowPanel"] then
                panel["ShowPanel"](panel)
            else
                panel.gameObject:SetActiveEx(true)
            end
        else
            if panel["HidePanel"] then
                panel["HidePanel"](panel)
            else
                panel.gameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiScratchTicketPanelPlay:ShowReady()
    local panelIndexGroup = {}
    panelIndexGroup[PANEL_INDEX.Ready] = true
    self:ShowChildPanel(panelIndexGroup)
    self.ReadyPanel:Refresh()
    self.PreviewPanel:Refresh()
    self.RootUi:PlayAnimation("PanelReadyEnable")
end

function XUiScratchTicketPanelPlay:ShowGaming()
    self:GetTicket()
    self:ShowChildPanel(
        { [PANEL_INDEX.Grids] = true,
            [PANEL_INDEX.Preview] = true,
        }
    )
    self.GridsPanel:Refresh()
    self.PreviewPanel:Refresh()
    self.RootUi:PlayAnimation("AnimBgQieHuan")
end

function XUiScratchTicketPanelPlay:ShowChooseChose()
    self:GetTicket()
    self:ShowChildPanel( 
        { [PANEL_INDEX.Chose] = true,
          [PANEL_INDEX.Grids] = true,
          [PANEL_INDEX.BtnExchange] = true,
          [PANEL_INDEX.SelectBlue] = true
            })
    self.SelectBluePanel:Reset()
    self.RootUi:PlayAnimation("AnimBtnContenrEnable")
end

function XUiScratchTicketPanelPlay:ShowResult()
    local ticket = self:GetTicket()
    local isCorrect = ticket:CheckIsSelectCorrent()
    local animName = isCorrect and "AnimPanelCorrectAnswerEnable" or "AnimPanelWrongAnswerEnable"   
    self:ShowChildPanel(
        {
          [PANEL_INDEX.WrongAnswer] = not isCorrect,
          [PANEL_INDEX.CorrectAnswer] = isCorrect,
          [PANEL_INDEX.BtnDetermine] = true,
          [PANEL_INDEX.Grids] = true,
        })
    if not isCorrect then
        self.SelectRedPanel:SelectChose(ticket:GetSelectChoseId())
        self.SelectBluePanel:SelectChose(ticket:GetCorrectChose()[1])
    else
        self.SelectBluePanel:SelectChose(ticket:GetSelectChoseId())
    end
    self.GridsPanel:Refresh()
    self.ChoseSelect = nil
    self.RootUi:PlayAnimation(animName)
end

function XUiScratchTicketPanelPlay:SelectChose(index)
    self:GetTicket()
    self.ChoseSelect = index
    self.SelectBluePanel:SelectChose(index)
    self.GridsPanel:SetMaskOnChoseSelect(index)
end

function XUiScratchTicketPanelPlay:OnClickBtnExchange()
    if not self.ChoseSelect then
        XUiManager.TipMsg(CS.XTextManager.GetText("ScratchTicketSelectChoseTips"))
        return
    end
    XDataCenter.ScratchTicketManager.ExChange(self.Controller:GetId(), self.ChoseSelect)
end

function XUiScratchTicketPanelPlay:OnClickBtnDetermine()
    self.RootUi:OnReady()
end

function XUiScratchTicketPanelPlay:OnDisable()
    self:ShowChildPanel({})
end

function XUiScratchTicketPanelPlay:OnDestroy()

end

return XUiScratchTicketPanelPlay
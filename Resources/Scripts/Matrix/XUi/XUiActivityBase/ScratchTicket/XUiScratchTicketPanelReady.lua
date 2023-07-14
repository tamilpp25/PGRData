---@class XUiScratchTicketPanelReady
local XUiScratchTicketPanelReady = XClass(nil, "XUiScratchTicketPanelReady")

function XUiScratchTicketPanelReady:Ctor(uiGameObject, gameController, rootUi)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self.RootUi = rootUi
    self.Controller = gameController
    self:InitPanel()
end
--==================
--初始化面板
--==================
function XUiScratchTicketPanelReady:InitPanel()
    self.ImgTicket:SetSprite(self.Controller:GetSpendItemIcon())
    self.TxtTicketNum.text = self.Controller:GetSpendItemNum()
    self.BtnStart.CallBack = function() self:OnClickBtnStart() end
    if self.BtnRestart then
        --只有黄金刮有这个按钮
        self.BtnRestart.CallBack = function() self:OnClickBtnRestart() end
    end
    self.Ticket = self.Controller:GetTicket()
    if (not self.Ticket) or self.Ticket:GetPlayStatus() == XDataCenter.ScratchTicketManager.PlayStatus.NotStart then
        self:ShowPanel()
    else
        self:HidePanel()
    end
end

function XUiScratchTicketPanelReady:Refresh()
    self.Ticket = self.Controller:GetTicket()
    if self.Controller:GetIsCanReset() then
        --黄金刮刮
        self.BtnRestart.gameObject:SetActiveEx(self.Controller:GetResetStatus())
        if self.TxtRestart then self.TxtRestart.gameObject:SetActiveEx(self.Controller:GetResetStatus()) end
        if self.ObjTicketNum then self.ObjTicketNum.gameObject:SetActiveEx(not self.Controller:GetResetStatus()) end
        self.BtnStart.gameObject:SetActiveEx(not self.Controller:GetResetStatus())
    end
end
--==================
--显示面板
--==================
function XUiScratchTicketPanelReady:ShowPanel()
    self.GameObject:SetActiveEx(true)
    self.ObjBgReady.gameObject:SetActiveEx(true)
    if self.ObjBg then self.ObjBg.gameObject:SetActiveEx(false) end
end
--==================
--隐藏面板
--==================
function XUiScratchTicketPanelReady:HidePanel()
    self.GameObject:SetActiveEx(false)
    self.ObjBgReady.gameObject:SetActiveEx(false)
    if self.ObjBg then self.ObjBg.gameObject:SetActiveEx(true) end
end
--==================
--点击开始游戏
--==================
function XUiScratchTicketPanelReady:OnClickBtnStart()
    if self.Controller:CheckIsLastTicket() then
        XUiManager.TipMsg(CS.XTextManager.GetText("ScratchTicketAllFinishTips"))
        return
    end
    XDataCenter.ScratchTicketManager.StartGame(self.Controller:GetId())
end
--==================
--点击重置黄金刮刮
--==================
function XUiScratchTicketPanelReady:OnClickBtnRestart()
    XDataCenter.ScratchTicketManager.ResetGame(self.Controller:GetId())
end
return XUiScratchTicketPanelReady
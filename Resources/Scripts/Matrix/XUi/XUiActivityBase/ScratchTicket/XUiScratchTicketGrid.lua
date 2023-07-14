---@class XUiScratchTicketGrid
local XUiScratchTicketGrid = XClass(nil, "XUiScratchTicketGrid")
local GridStatus = {
        Front = 1,
        Back = 2
    }
function XUiScratchTicketGrid:Ctor(uiGameObject, gridIndex, panel)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self.Index = gridIndex
    self.Panel = panel
    self:InitGrid()
end

function XUiScratchTicketGrid:InitGrid()
    self:Refresh()
    XUiHelper.RegisterClickEvent(self, self.Transform, function() self:OnClick() end)
end

function XUiScratchTicketGrid:Refresh()
    local ticket = self.Panel:GetTicket()
    if ticket then
        if ticket:CheckGridIsOpenByGridIndex(self.Index) then          
            self:SetFrontStatus()
            self.GridStatus = GridStatus.Front
        else
            self:SetBackStatus()
            self.GridStatus = GridStatus.Back
        end
        self.TxtNum.text = ticket:GetGridNumByGridIndex(self.Index)
    else
        self:SetBackStatus()
        self.GridStatus = GridStatus.Back
    end
end

function XUiScratchTicketGrid:SetMask()
    if self.GridStatus == GridStatus.Front then
        self:SetFrontWithMask()
    elseif self.GridStatus == GridStatus.Back then
        self:SetBackWithMask()
    end
end

function XUiScratchTicketGrid:HideMask()
    if self.GridStatus == GridStatus.Front then
        self:SetFrontStatus()
    elseif self.GridStatus == GridStatus.Back then
        self:SetBackStatus()
    end
end

function XUiScratchTicketGrid:SetBackStatus()
    self.BackStatus.gameObject:SetActiveEx(true)
    self.FrontStatus.gameObject:SetActiveEx(false)
    self.FrontMask.gameObject:SetActiveEx(false)
    self.BackMask.gameObject:SetActiveEx(false)
end

function XUiScratchTicketGrid:SetFrontStatus()
    if self.GridStatus == GridStatus.Back then
        if self.AnimCardFlip then
            self.AnimCardFlip:Play()
        end
    end
    --self.BackStatus.gameObject:SetActiveEx(false)
    self.FrontStatus.gameObject:SetActiveEx(true)
    self.FrontMask.gameObject:SetActiveEx(false)
    self.BackMask.gameObject:SetActiveEx(false)
end

function XUiScratchTicketGrid:SetFrontWithMask()
    if self.GridStatus == GridStatus.Back then
        if self.AnimCardFlip then
            self.AnimCardFlip:Play()
        end
    end
    --self.BackStatus.gameObject:SetActiveEx(false)
    self.FrontStatus.gameObject:SetActiveEx(true)
    self.FrontMask.gameObject:SetActiveEx(true)
    self.BackMask.gameObject:SetActiveEx(false)
end

function XUiScratchTicketGrid:SetBackWithMask()
    self.BackStatus.gameObject:SetActiveEx(false)
    self.FrontStatus.gameObject:SetActiveEx(false)
    self.FrontMask.gameObject:SetActiveEx(false)
    self.BackMask.gameObject:SetActiveEx(true)
end

function XUiScratchTicketGrid:OnClick()
    if self.GridStatus == GridStatus.Front then
        XUiManager.TipMsg(CS.XTextManager.GetText("ScratchTicketGridAlreadyOpenTips"))
        return
    end
    if self.Panel.Controller:CheckPreviewFinish() then
        XUiManager.TipMsg(CS.XTextManager.GetText("ScratchTicketMaxOpenTips"))
        return
    end
    XDataCenter.ScratchTicketManager.OpenGrid(self.Panel.Controller:GetId(), self.Index)
end

return XUiScratchTicketGrid
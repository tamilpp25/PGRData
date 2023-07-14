-- 刮刮乐PanelTop面板控件
local XUiScratchTicketPanelLeft = XClass(nil, "XUiScratchTicketPanelLeft")
local STR_UNKNOWN = "?"
function XUiScratchTicketPanelLeft:Ctor(uiGameObject, controller, rootUi)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self.Controller = controller
    self.RootUi = rootUi
    self.ObjLuckyRewardSelect.gameObject:SetActiveEx(false)
    if self.ObjNormalRewardSelect then self.ObjNormalRewardSelect.gameObject:SetActiveEx(false) end
    self:InitBtns()
    self:RefreshPanel()
end

function XUiScratchTicketPanelLeft:InitBtns()
    if self.BtnLuckyReward then self.BtnLuckyReward.CallBack = function() self:OnLuckyRewardClick() end end
    if self.BtnLuckyRewardSelect then self.BtnLuckyRewardSelect.CallBack = function() self:OnLuckyRewardClick() end end
    if self.BtnNormalReward then self.BtnNormalReward.CallBack = function() self:OnNormalRewardClick() end end
    if self.BtnNormalRewardSelect then self.BtnNormalRewardSelect.CallBack = function() self:OnNormalRewardClick() end end
end

function XUiScratchTicketPanelLeft:RefreshPanel()
    self.Ticket = self.Controller:GetTicket()
    self:RefreshLuckyReward()
    self:RefreshNormalReward()
end

function XUiScratchTicketPanelLeft:RefreshLuckyReward()
    local isStart = false
    if self.Ticket then
        local playStatus = self.Ticket:GetPlayStatus()
        isStart = playStatus ~= XDataCenter.ScratchTicketManager.PlayStatus.NotStart
    end
    self.ObjLuckyRewardNormal.gameObject:SetActiveEx(true)
    self.TxtLuckyNum.text = isStart and self.Ticket:GetLuckyNum() or STR_UNKNOWN   
    if self.Controller:GetIsCanReset() then
        self.RImgLuckyReward.gameObject:SetActiveEx(true)
        if self.RImgLuckyRewardBg then self.RImgLuckyRewardBg.gameObject:SetActiveEx(true) end
        self.RImgLuckyReward:SetRawImage(self.Controller:GetGoldRewardItemIcon())
        self.TxtLuckyRewardNum.text = "x" .. self.Controller:GetGoldRewardItemNum() or STR_UNKNOWN
    else
        self.RImgLuckyReward.gameObject:SetActiveEx(isStart)
        if self.RImgLuckyRewardBg then self.RImgLuckyRewardBg.gameObject:SetActiveEx(isStart) end
        if isStart then self.RImgLuckyReward:SetRawImage(self.Ticket:GetWinRewardItemIcon()) end
        self.TxtLuckyRewardNum.text = isStart and "x" .. self.Ticket:GetWinRewardItemNum() or STR_UNKNOWN
    end
end

function XUiScratchTicketPanelLeft:RefreshNormalReward()
    --黄金刮刮没有普通奖励
    if self.Controller:GetIsCanReset() then return end
    local isStart = false
    if self.Ticket then
        local playStatus = self.Ticket:GetPlayStatus()
        isStart = playStatus ~= XDataCenter.ScratchTicketManager.PlayStatus.NotStart
    end
    self.ObjNormalRewardNormal.gameObject:SetActiveEx(true)
    self.RImgNormalReward.gameObject:SetActiveEx(isStart)
    if self.RImgNormalRewardBg then self.RImgNormalRewardBg.gameObject:SetActiveEx(isStart) end
    if isStart then self.RImgNormalReward:SetRawImage(self.Ticket:GetLoseRewardItemIcon()) end
    self.TxtNormalRewardNum.text = isStart and "x" .. self.Ticket:GetLoseRewardItemNum() or STR_UNKNOWN
end

function XUiScratchTicketPanelLeft:RefreshSelect()
    if not self.Ticket then self.Ticket = self.Controller:GetTicket() end
    if not self.Ticket then return end
    local isCorrent = self.Ticket:CheckIsSelectCorrent()
    self.ObjLuckyRewardSelect.gameObject:SetActiveEx(isCorrent)
    if not self.Controller:GetIsCanReset() then
        self.ObjNormalRewardSelect.gameObject:SetActiveEx(not self.Ticket:CheckIsSelectCorrent())
    end
    if isCorrent then
        self.ObjLuckyRewardNormal.gameObject:SetActiveEx(false)
        self.RImgLuckyRewardSelect:SetRawImage(self.Ticket:GetWinRewardItemIcon())
        self.TxtLuckyRewardNumSelect.text = "x" .. self.Ticket:GetWinRewardItemNum()
    else
        if not self.Controller:GetIsCanReset() then
            self.ObjNormalRewardNormal.gameObject:SetActiveEx(false)
            self.RImgNormalRewardSelect:SetRawImage(self.Ticket:GetLoseRewardItemIcon())
            self.TxtNormalRewardNumSelect.text = "x" .. self.Ticket:GetLoseRewardItemNum()
        end
    end
end

function XUiScratchTicketPanelLeft:OnReset()
    local isGold = self.Controller:GetIsCanReset()
    self.TxtLuckyNum.text = STR_UNKNOWN
    self.RImgLuckyReward.gameObject:SetActiveEx(isGold)
    if self.RImgLuckyRewardBg then self.RImgLuckyRewardBg.gameObject:SetActiveEx(isGold) end
    if not isGold then
        self.TxtLuckyRewardNum.text = STR_UNKNOWN
    end
    self.ObjLuckyRewardNormal.gameObject:SetActiveEx(true)
    self.ObjLuckyRewardSelect.gameObject:SetActiveEx(false)
    if isGold then return end
    self.ObjNormalRewardNormal.gameObject:SetActiveEx(true)
    self.RImgNormalReward.gameObject:SetActiveEx(false)
    if self.RImgNormalRewardBg then self.RImgNormalRewardBg.gameObject:SetActiveEx(false) end
    self.TxtNormalRewardNum.text = STR_UNKNOWN
    if not self.Controller:GetIsCanReset() then
        self.ObjNormalRewardSelect.gameObject:SetActiveEx(false)
    end
end

function XUiScratchTicketPanelLeft:OnLuckyRewardClick()
    local isGold = self.Controller:GetIsCanReset()
    if not isGold and not self.Ticket then return end
    local itemId
    if not self.Ticket and isGold then
        itemId = self.Controller:GetGoldRewardItemId()
    else
        itemId = self.Ticket:GetWinRewardItemId()
    end
    if itemId and itemId > 0 then
        XLuaUiManager.Open("UiTip", itemId, true, nil)
    end
end

function XUiScratchTicketPanelLeft:OnNormalRewardClick()
    local isGold = self.Controller:GetIsCanReset()
    if isGold then return end
    local itemId = self.Ticket:GetLoseRewardItemId()
    if itemId and itemId > 0 then
        XLuaUiManager.Open("UiTip", itemId, true, nil)
    end
end

function XUiScratchTicketPanelLeft:OnDestroy()

end

return XUiScratchTicketPanelLeft
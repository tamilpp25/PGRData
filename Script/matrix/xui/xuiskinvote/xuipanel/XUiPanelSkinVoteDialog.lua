
---@class XUiPanelSkinVoteDialog 弹窗类
local XUiPanelSkinVoteDialog = XClass(nil, "XUiPanelSkinVoteDialog")

function XUiPanelSkinVoteDialog:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    
    self:InitCb()
end

function XUiPanelSkinVoteDialog:Show(title, content, cancelBtnName, cancelCb, confirmBtnName, confirmCb)
    self.Title = title
    self.Content = content
    self.CancelBtnName = cancelBtnName
    self.CancelCb = cancelCb
    self.ConfirmBtnName = confirmBtnName
    self.ConfirmCb = confirmCb

    if not self.CancelCb then
        self.BtnCancel.gameObject:SetActiveEx(false)
    else
        self.BtnCancel.gameObject:SetActiveEx(true)
        if not string.IsNilOrEmpty(cancelBtnName) then
            self.BtnCancel:SetNameByGroup(0, cancelBtnName)
        end
    end

    if not self.ConfirmCb then
        self.BtnConfirm.gameObject:SetActiveEx(false)
    else
        self.BtnConfirm.gameObject:SetActiveEx(true)
        if not string.IsNilOrEmpty(confirmBtnName) then
            self.BtnConfirm:SetNameByGroup(0, confirmBtnName)
        end
    end
    
    self.TxtTitle.text = title
    self.TxtContent.text = XUiHelper.ReplaceTextNewLine(content or "")
    
    self.GameObject:SetActiveEx(true)
end

function XUiPanelSkinVoteDialog:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelSkinVoteDialog:InitCb()
    self.BtnTanchuangClose.CallBack = function() 
        self:Hide()
    end

    self.BtnTreasureBg.CallBack = function()
        self:Hide()
    end

    self.BtnConfirm.CallBack = function()
        if self.ConfirmCb then self.ConfirmCb() end
        self:Hide()
    end

    self.BtnCancel.CallBack = function()
        if self.CancelCb then self.CancelCb() end
        self:Hide()
    end
end

return XUiPanelSkinVoteDialog
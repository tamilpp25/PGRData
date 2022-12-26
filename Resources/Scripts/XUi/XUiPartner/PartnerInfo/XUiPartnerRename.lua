local XUiPartnerRename = XLuaUiManager.Register(XLuaUi, "UiPartnerRename")

local CSXTextManagerGetText = CS.XTextManager.GetText
local MaxNameLength = CS.XGame.Config:GetInt("PartnerNameMaxLength")

function XUiPartnerRename:OnStart(base, partnerId)
    self.Base = base
    self.PartnerId = partnerId
    self:SetButtonCallBack()
end

function XUiPartnerRename:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:Close()
    end
    self.BtnTanchuangClose.CallBack = function()
        self:Close()
    end
    self.BtnNameCancel.CallBack = function()
        self:Close()
    end
    self.BtnNameSure.CallBack = function()
        self:OnBtnNameSure()
    end
end

function XUiPartnerRename:OnBtnNameSure()
    local editName = string.gsub(self.InFSigm.text, "^%s*(.-)%s*$", "%1")

    if string.len(editName) > 0 then
        local utf8Count = self.InFSigm.textComponent.cachedTextGenerator.characterCount - 1
        if utf8Count > MaxNameLength then
            XUiManager.TipError(CSXTextManagerGetText("MaxNameLengthTips", MaxNameLength))
            return
        end
        
        XDataCenter.PartnerManager.PartnerChangeNameRequest(self.PartnerId, editName, function ()
                XUiManager.TipText("PartnerRenameSuc")
                self.Base:ShowPanel()
                self:Close()
        end)
    else
        XUiManager.TipError(CSXTextManagerGetText("PartnerNameIsEmpty"))
    end
end
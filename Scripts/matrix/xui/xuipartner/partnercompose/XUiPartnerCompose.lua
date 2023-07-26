local XUiPartnerCompose = XLuaUiManager.Register(XLuaUi, "UiPartnerCompose")

local CSTextManagerGetText = CS.XTextManager.GetText
local DOFillTime = 0.5
local DefaultIndex = 1

function XUiPartnerCompose:OnStart(base)
    self.Base = base
    self:SetButtonCallBack()
end

function XUiPartnerCompose:OnDestroy()
    
end

function XUiPartnerCompose:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_PARTNER_OBTAIN, self.OnComposeSuccess, self)
end

function XUiPartnerCompose:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PARTNER_OBTAIN, self.OnComposeSuccess, self)
end

function XUiPartnerCompose:SetButtonCallBack()
    self.BtnCompose.CallBack = function()
        self:OnBtnComposeClick()
    end
    self.BtnGet.CallBack = function()
        self:OnBtnGetClick()
    end
end

function XUiPartnerCompose:OnBtnComposeClick()
    if not self.Data:GetIsCanCompose() then
        XUiManager.TipText("PartnerComposeClipEmpty")
        return
    end
    XDataCenter.PartnerManager.PartnerComposeRequest({self.Data:GetTemplateId()}, false)
end

function XUiPartnerCompose:OnBtnGetClick()
    local unionFightData = XDataCenter.FubenUnionKillRoomManager.GetUnionRoomData()
    if unionFightData and unionFightData.Id then
        return
    end

    local useItemId = self.Data:GetChipItemId()
    XLuaUiManager.Open("UiTip", XDataCenter.ItemManager.GetItem(useItemId))
end

function XUiPartnerCompose:UpdatePanel(data)
    self.Data = data
    if data then
        local IsShowRed = XDataCenter.PartnerManager.CheckComposeRedByTemplateId(self.Data:GetTemplateId())
        self.BtnCompose:ShowReddot(IsShowRed)
    end
end

function XUiPartnerCompose:OnComposeSuccess(partnerList)
    if self.Base.isComposePanelOpenByStar then
        self.Base:BackFromComposePanel()
    else
        self:GoPartnerMain(partnerList)
    end
end

function XUiPartnerCompose:GoPartnerMain(partnerList)
    local selectPartner = partnerList and partnerList[DefaultIndex] or nil
    for _,partner in pairs(partnerList or {}) do
        if partner:GetPriority() > selectPartner:GetPriority() then
            selectPartner = partner
        end
    end
    XLuaUiManager.PopThenOpen("UiPartnerMain", nil, selectPartner)
end
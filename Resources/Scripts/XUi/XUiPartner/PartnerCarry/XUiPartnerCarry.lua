local XUiPartnerCarry = XLuaUiManager.Register(XLuaUi, "UiPartnerCarry")
local XUiGridSkill = require("XUi/XUiPartner/PartnerCommon/XUiGridSkill")
local XUiGridPartnerCarry = require("XUi/XUiPartner/PartnerCarry/XUiGridPartnerCarry")
local CSTextManagerGetText = CS.XTextManager.GetText
local DefaultIndex = 1
local Select = CS.UiButtonState.Select
local Normal = CS.UiButtonState.Normal

local ATTR_COLOR = {
    BELOW = XUiHelper.Hexcolor2Color("d11e38ff"),
    EQUAL = XUiHelper.Hexcolor2Color("000000ff"),
    OVER = XUiHelper.Hexcolor2Color("188649ff"),
}

local TakeState = {
    On = 1,
    Off = 2,
    Change = 3,
}

function XUiPartnerCarry:OnStart(characterId,IsCanSkipProperty)
    self.CurCarrierId = characterId
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:SetButtonCallBack()
    self:InitDynamicTable()
    self.GridSkill.gameObject:SetActiveEx(false)
    self.MainSkillGrid = {}
    self.PassiveSkillGrid = {}
    self.IsCanSkipProperty = IsCanSkipProperty
end

function XUiPartnerCarry:OnDestroy()

end

function XUiPartnerCarry:OnEnable()
    self:UpdatePanel()
    XEventManager.AddEventListener(XEventId.EVENT_PARTNER_CARRY, self.ShowHint, self)
    XEventManager.AddEventListener(XEventId.EVENT_PARTNER_SKILLCHANGE, self.UpdatePanel, self)
end

function XUiPartnerCarry:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PARTNER_CARRY, self.ShowHint, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PARTNER_SKILLCHANGE, self.UpdatePanel, self)
end

function XUiPartnerCarry:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnPartnerLock.CallBack = function()
        self:OnBtnPartnerLockClick()
    end
    self.BtnStrengthen.CallBack = function()
        self:OnBtnStrengthenClick()
    end
    self.BtnTakeOn.CallBack = function()
        self.TakeState = TakeState.On
        self:OnBtnTakeOnClick()
    end
    self.BtnTakeOff.CallBack = function()
        self.TakeState = TakeState.Off
        self:OnBtnTakeOffClick()
    end
    self.BtnTakeChange.CallBack = function()
        self.TakeState = TakeState.Change
        self:OnBtnTakeOnClick()
    end
end

function XUiPartnerCarry:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelPartnerScroll)
    self.DynamicTable:SetProxy(XUiGridPartnerCarry)
    self.DynamicTable:SetDelegate(self)
    self.GridPartner.gameObject:SetActiveEx(false)
end

function XUiPartnerCarry:SetupDynamicTable()
    local curPartnerType = XCharacterConfigs.GetCharacterType(self.CurCarrierId)

    self.PageDatas = XDataCenter.PartnerManager.GetPartnerOverviewDataList(nil, curPartnerType, false)
    XPartnerSort.CarrySortFunction(self.PageDatas, self.CurCarrierId)

    self.CurPartner = self.CurPartner or self.PageDatas[DefaultIndex]
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiPartnerCarry:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self)
    end
end

function XUiPartnerCarry:UpdatePanel()
    self:SetupDynamicTable()
    self:PlayAnimation("LeftQieHuan")
    
    local charName = XCharacterConfigs.GetCharacterLogName(self.CurCarrierId)
    local charElement = XCharacterConfigs.GetCharacterElement(self.CurCarrierId)
    local elementConfig = XCharacterConfigs.GetCharElement(charElement)

    self.CountText.text = #self.PageDatas
    self.TxtCarrierName.text = charName
end

function XUiPartnerCarry:SelectPartner(partner)
    self.CurPartner = partner
    self:UpdatePanelPartnerCarryInfo(partner)
    self:PlayAnimation("RightQieHuan")
end

function XUiPartnerCarry:UpdatePanelPartnerCarryInfo(data)
    self.Data = data
    if data then

        local carryPartnerId = XDataCenter.PartnerManager.GetCarryPartnerIdByCarrierId(self.CurCarrierId)
        local carryPartner = carryPartnerId and XDataCenter.PartnerManager.GetPartnerEntityById(carryPartnerId)
        carryPartnerId = carryPartner and carryPartnerId or nil

        self.TxtPartnerName.text = data:GetName()
        self.TxtPartnerLevel.text = data:GetLevel()

        local IsShowSelect = true
        if not carryPartnerId or carryPartnerId == data:GetId() then
            self.TxtCurAbil.text = data:GetAbility()
            IsShowSelect = false
        else
            self.TxtSelectAbil.text = data:GetAbility()
            self.TxtCurAbil.text = carryPartner:GetAbility()

            if carryPartner:GetAbility() == data:GetAbility() then
                self.TxtSelectAbil.color = ATTR_COLOR.EQUAL
            elseif carryPartner:GetAbility() < data:GetAbility() then
                self.TxtSelectAbil.color = ATTR_COLOR.OVER
            elseif carryPartner:GetAbility() > data:GetAbility() then
                self.TxtSelectAbil.color = ATTR_COLOR.BELOW
            end

            IsShowSelect = true
        end

        self.ImgCompare.gameObject:SetActiveEx(IsShowSelect)
        self.TxtSelectAbil.gameObject:SetActiveEx(IsShowSelect)

        local IsTakeOn = not carryPartnerId or carryPartnerId ~= data:GetId()
        self.BtnTakeOn.gameObject:SetActiveEx(IsTakeOn and not carryPartnerId)
        self.BtnTakeOff.gameObject:SetActiveEx(not IsTakeOn)
        self.BtnTakeChange.gameObject:SetActiveEx(IsTakeOn and carryPartnerId)
        self.BtnStrengthen.gameObject:SetActiveEx(self.IsCanSkipProperty)

        local qualityIcon = XCharacterConfigs.GetCharacterQualityIcon(data:GetQuality())
        self.RImgPartnerIcon:SetRawImage(data:GetIcon())
        self.RawImageQuality:SetRawImage(qualityIcon)

        self:ShowLock()
        self:ShowPanelSkill()
    end
end

function XUiPartnerCarry:ShowPanelSkill()
    local mainSkillList = self.Data:GetCarryMainSkillGroupList()
    local passiveSkillList = self.Data:GetCarryPassiveSkillGroupList()
    local skillCount = self.Data:GetQualitySkillColumnCount()
    local initQuality = self.Data:GetInitQuality()

    for index = 1, XPartnerConfigs.MainSkillCount do
        local grid = self.MainSkillGrid[index]
        if not grid then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridSkill,self.PanelSkills)
            obj.gameObject:SetActiveEx(true)
            grid = XUiGridSkill.New(obj)
            grid.GameObject.name = string.format("MainSkill%d", index)
            self.MainSkillGrid[index] = grid
        end
        grid:UpdateGrid(mainSkillList[index], self.Data, false, XPartnerConfigs.SkillType.MainSkill, index + 1)
    end

    for index = 1, XPartnerConfigs.PassiveSkillCount do
        local grid = self.PassiveSkillGrid[index]
        if not grid then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridSkill,self.PanelSkills)
            obj.gameObject:SetActiveEx(true)
            grid = XUiGridSkill.New(obj)
            grid.GameObject.name = string.format("PassiveSkill%d", index)
            self.PassiveSkillGrid[index] = grid
        end
        grid:UpdateGrid(passiveSkillList[index], self.Data, skillCount < index, XPartnerConfigs.SkillType.PassiveSkill, index + 1)
    end
end

function XUiPartnerCarry:ShowLock()
    self.BtnPartnerLock:SetButtonState(self.Data:GetIsLock() and Select or Normal)
    self.BtnPartnerLock.TempState = self.Data:GetIsLock() and Select or Normal
end

function XUiPartnerCarry:OnBtnPartnerLockClick()
    XDataCenter.PartnerManager.PartnerUpdateLockRequest(self.Data:GetId(), not self.Data:GetIsLock(), function ()
            self:UpdatePanel()
        end)
end

function XUiPartnerCarry:OnBtnBackClick()
    self:Close()
end

function XUiPartnerCarry:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiPartnerCarry:OnBtnStrengthenClick()
    XLuaUiManager.Open("UiPartnerMain", XPartnerConfigs.MainUiState.Property, self.CurPartner, true, true)
end

function XUiPartnerCarry:OnBtnTakeOnClick()
    local IsCarring = self.Data:GetIsCarry() and self.Data:GetCharacterId() ~= self.CurCarrierId
    if IsCarring then
        local CarrierName = XCharacterConfigs.GetCharacterLogName(self.Data:GetCharacterId())
        XDataCenter.PartnerManager.TipDialog(nil,function ()
                self:DoTakeOn()
            end, "PartnerIsCarringHint", CarrierName)
    else
        self:DoTakeOn()
    end
end

function XUiPartnerCarry:DoTakeOn()
    self:OpenMask()
    XDataCenter.PartnerManager.PartnerCarryRequest(self.CurCarrierId, self.CurPartner:GetId(), function ()
            self:CloseMask()
        end)
end

function XUiPartnerCarry:OnBtnTakeOffClick()
    self:OpenMask()
    XDataCenter.PartnerManager.PartnerBreakAwayRequest(self.CurPartner:GetId(), function ()
            self:CloseMask()
        end)
end

function XUiPartnerCarry:OpenMask()
    if not self.IsSendMeg then
        XLuaUiManager.SetMask(true)
        self.IsSendMeg = true
    end
end

function XUiPartnerCarry:CloseMask()
    if self.IsSendMeg then
        XLuaUiManager.SetMask(false)
        self.IsSendMeg = false
    end
end

function XUiPartnerCarry:ShowHint()
    local hintText = ""
    if self.TakeState == TakeState.On then
        hintText = CSTextManagerGetText("PartnerCarrySuccess")
    elseif self.TakeState == TakeState.Off then
        hintText = CSTextManagerGetText("PartnerPutdownSuccess")
    elseif self.TakeState == TakeState.Change then
        hintText = CSTextManagerGetText("PartnerChangeSuccess")
    end
    
    XLuaUiManager.Open("UiPartnerPopupTip", hintText)
    self:UpdatePanel()
    self:CloseMask()
end
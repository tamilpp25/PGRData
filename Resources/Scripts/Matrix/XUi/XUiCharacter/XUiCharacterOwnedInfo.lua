local XUiGridEquip = require("XUi/XUiEquipAwarenessReplace/XUiGridEquip")

local XUiCharacterOwnedInfo = XLuaUiManager.Register(XLuaUi, "UiCharacterOwnedInfo")

function XUiCharacterOwnedInfo:OnAwake()
    self:AddListener()
end

function XUiCharacterOwnedInfo:OnStart(forbidGotoEquip, clickCb, isSupport, supportData)
    self.ForbidGotoEquip = forbidGotoEquip
    self.IsSupport = isSupport
    self.ClickCb = clickCb
    self.SupportData = supportData

    self.BtnLevelUp.gameObject:SetActiveEx(not forbidGotoEquip and not self.IsSupport)
    self.BtnJoin.gameObject:SetActiveEx(forbidGotoEquip)
    self.BtnSupport.gameObject:SetActiveEx(self.IsSupport)
    self.BtnSupportCancel.gameObject:SetActiveEx(false)

    self:RegisterRedPointEvent()
end

function XUiCharacterOwnedInfo:OnEnable()
    self:UpdateView(self.CharacterId)
end

function XUiCharacterOwnedInfo:PreSetCharacterId(characterId)
    self.CharacterId = characterId
end

function XUiCharacterOwnedInfo:RegisterRedPointEvent()
    local characterId = self.CharacterId
    self.RedPointId = XRedPointManager.AddRedPointEvent(self.ImgRedPoint, self.OnCheckCharacterRedPoint, self, { XRedPointConditions.Types.CONDITION_CHARACTER }, characterId)
end

function XUiCharacterOwnedInfo:OnCheckCharacterRedPoint(count)
    self.ImgRedPoint.gameObject:SetActiveEx(count >= 0)
end

function XUiCharacterOwnedInfo:UpdateView(characterId)
    self.CharacterId = characterId

    local charConfig = XCharacterConfigs.GetCharacterTemplate(characterId)
    self.TxtName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName

    local character = XDataCenter.CharacterManager.GetCharacter(characterId)
    self.RImgTypeIcon:SetRawImage(XCharacterConfigs.GetNpcTypeIcon(character.Type))
    self.TxtLv.text = math.floor(character.Ability)

    self.WeaponGrid = self.WeaponGrid or XUiGridEquip.New(self.GridWeapon, nil, self)
    local usingWeaponId = XDataCenter.EquipManager.GetCharacterWearingWeaponId(characterId)
    self.WeaponGrid:Refresh(usingWeaponId)

    local partner = XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(characterId)
    if partner then
        self.PartnerIcon:SetRawImage(partner:GetIcon())
    end
    self.PartnerIcon.gameObject:SetActiveEx(partner)

    self.WearingAwarenessGrids = self.WearingAwarenessGrids or {}
    for _, equipSite in pairs(XEquipConfig.EquipSite.Awareness) do
        self.WearingAwarenessGrids[equipSite] = self.WearingAwarenessGrids[equipSite] or XUiGridEquip.New(CS.UnityEngine.Object.Instantiate(self.GridAwareness), nil, self)
        self.WearingAwarenessGrids[equipSite].Transform:SetParent(self["PanelAwareness" .. equipSite], false)

        local equipId = XDataCenter.EquipManager.GetWearingEquipIdBySite(characterId, equipSite)
        if not equipId then
            self.WearingAwarenessGrids[equipSite].GameObject:SetActiveEx(false)
            self["PanelNoAwareness" .. equipSite].gameObject:SetActiveEx(true)
        else
            self.WearingAwarenessGrids[equipSite].GameObject:SetActiveEx(true)
            self["BtnAwarenessReplace" .. equipSite].transform:SetAsLastSibling()
            self["PanelNoAwareness" .. equipSite].gameObject:SetActiveEx(false)
            self.WearingAwarenessGrids[equipSite]:Refresh(equipId)
        end
    end

    local detailConfig = XCharacterConfigs.GetCharDetailTemplate(characterId)
    local elementList = detailConfig.ObtainElementList
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if elementList[i] then
            rImg.gameObject:SetActiveEx(true)
            local elementConfig = XCharacterConfigs.GetCharElement(elementList[i])
            rImg:SetRawImage(elementConfig.Icon)
        else
            rImg.gameObject:SetActiveEx(false)
        end
    end

    XRedPointManager.Check(self.RedPointId, characterId)

    self:UpdateSupport(characterId)
end

--------支援相关 begin---------
function XUiCharacterOwnedInfo:UpdateSupport(characterId)
    local supportData = self.SupportData
    if XTool.IsTableEmpty(supportData) then return end

    self.BtnLevelUp.gameObject:SetActiveEx(false)

    local showSupport = not supportData.CheckInSupportCb(characterId)
    self.BtnSupport.gameObject:SetActiveEx(showSupport)

    local showSupportCancel = supportData.CanSupportCancel and supportData.CheckInSupportCb(characterId)
    self.BtnSupportCancel.gameObject:SetActiveEx(showSupportCancel)
end
--------支援相关 end---------
function XUiCharacterOwnedInfo:AddListener()
    self:RegisterClickEvent(self.BtnLevelUp, self.OnBtnLevelUpClick)
    self:RegisterClickEvent(self.BtnAwarenessReplace6, self.OnBtnAwarenessReplace6Click)
    self:RegisterClickEvent(self.BtnAwarenessReplace5, self.OnBtnAwarenessReplace5Click)
    self:RegisterClickEvent(self.BtnAwarenessReplace4, self.OnBtnAwarenessReplace4Click)
    self:RegisterClickEvent(self.BtnAwarenessReplace3, self.OnBtnAwarenessReplace3Click)
    self:RegisterClickEvent(self.BtnAwarenessReplace2, self.OnBtnAwarenessReplace2Click)
    self:RegisterClickEvent(self.BtnAwarenessReplace1, self.OnBtnAwarenessReplace1Click)
    self:RegisterClickEvent(self.BtnWeaponReplace, self.OnBtnWeaponReplaceClick)
    self:RegisterClickEvent(self.BtnJoin, self.OnBtnJoinClick)
    self:RegisterClickEvent(self.BtnCareerTips, self.OnBtnCareerTipsClick)
    self.BtnElementDetail.CallBack = function() self:OnBtnElementDetailClick() end
    self.BtnSupport.CallBack = function() self:OnBtnSupportClick() end
    self.BtnSupportCancel.CallBack = function() self:OnBtnSupportCancelClick() end
    self.BtnCarryPartner.CallBack = function() self:OnCarryPartnerClick() end
end

function XUiCharacterOwnedInfo:OnBtnAwarenessReplace5Click()
    self:OnAwarenessClick(5)
end

function XUiCharacterOwnedInfo:OnBtnAwarenessReplace4Click()
    self:OnAwarenessClick(4)
end

function XUiCharacterOwnedInfo:OnBtnAwarenessReplace3Click()
    self:OnAwarenessClick(3)
end

function XUiCharacterOwnedInfo:OnBtnAwarenessReplace2Click()
    self:OnAwarenessClick(2)
end

function XUiCharacterOwnedInfo:OnBtnAwarenessReplace1Click()
    self:OnAwarenessClick(1)
end

function XUiCharacterOwnedInfo:OnBtnAwarenessReplace6Click()
    self:OnAwarenessClick(6)
end

function XUiCharacterOwnedInfo:OnAwarenessClick(site)
    if self.ForbidGotoEquip or self.IsSupport then return end
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Equip) then
        return
    end
    XLuaUiManager.Open("UiEquipAwarenessReplace", self.CharacterId, site)
end

function XUiCharacterOwnedInfo:OnBtnCareerTipsClick()
    XLuaUiManager.Open("UiCharacterCarerrTips")
end

function XUiCharacterOwnedInfo:OnBtnWeaponReplaceClick()
    if self.ForbidGotoEquip or self.IsSupport then return end
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Equip) then
        return
    end
    XLuaUiManager.Open("UiEquipReplaceNew", self.CharacterId)
end

function XUiCharacterOwnedInfo:OnBtnLevelUpClick()
    if self.ClickCb then self.ClickCb() end
end

function XUiCharacterOwnedInfo:OnBtnJoinClick()
    XDataCenter.AssistManager.ChangeAssistCharacterId(self.CharacterId, function(code)
        if (code == XCode.Success) then
            XLuaUiManager.Close("UiCharacter")
        end
    end)
end

function XUiCharacterOwnedInfo:OnBtnElementDetailClick()
    XLuaUiManager.Open("UiCharacterElementDetail", self.CharacterId)
end

function XUiCharacterOwnedInfo:OnBtnSupportClick()
    local characterId = self.CharacterId
    XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_SUPPORT, characterId)

    if self.SupportData then
        if self.SupportData.SetCharacterCb then
            local cb = function() XLuaUiManager.Close("UiCharacter") end
            if not self.SupportData.SetCharacterCb(characterId, cb, self.SupportData.OldCharacterId) then return end
        end
    else
        XLuaUiManager.Close("UiCharacter")
    end
end

function XUiCharacterOwnedInfo:OnCarryPartnerClick()
    XDataCenter.PartnerManager.GoPartnerCarry(self.CharacterId, true)
end

function XUiCharacterOwnedInfo:OnBtnSupportCancelClick()
    local characterId = self.CharacterId
    if self.SupportData then
        if self.SupportData.CancelCharacterCb then
            self.SupportData.CancelCharacterCb(characterId)
        end
    end
end
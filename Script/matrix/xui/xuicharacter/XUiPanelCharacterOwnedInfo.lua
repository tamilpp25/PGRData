local XUiPanelCharacterOwnedInfo = XClass(nil, "XUiPanelCharacterOwnedInfo")
local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")

function XUiPanelCharacterOwnedInfo:Ctor(rootUi, parentNode)
    self.UiRoot = rootUi
    local uiName = CS.XGame.ClientConfig:GetString("PanelCharacterOwnedInfo")
    local ui = parentNode:LoadPrefab(uiName)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self:AddListener()
end

function XUiPanelCharacterOwnedInfo:Init(forbidGotoEquip, clickCb, isSupport, supportData)
    self.ForbidGotoEquip = forbidGotoEquip
    self.IsSupport = isSupport
    self.ClickCb = clickCb
    self.SupportData = supportData

    self.BtnLevelUp.gameObject:SetActiveEx(false)
    self.BtnJoin.gameObject:SetActiveEx(false)
    self.BtnSupport.gameObject:SetActiveEx(false)
    self.BtnSupportCancel.gameObject:SetActiveEx(false)
    self.BtnRecommend.gameObject:SetActiveEx(false)

    if self.Partner then
        self.Partner.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
    end

    self:RegisterRedPointEvent()
end

function XUiPanelCharacterOwnedInfo:OnEnable()
    self:UpdateView(self.CharacterId)
end

function XUiPanelCharacterOwnedInfo:PreSetCharacterId(characterId)
    self.CharacterId = characterId
end

function XUiPanelCharacterOwnedInfo:RegisterRedPointEvent()
    local characterId = self.CharacterId
    self.RedPointId = XRedPointManager.AddRedPointEvent(self.ImgRedPoint, self.OnCheckCharacterRedPoint, self, { XRedPointConditions.Types.CONDITION_CHARACTER }, characterId)
end

function XUiPanelCharacterOwnedInfo:OnCheckCharacterRedPoint(count)
    self.ImgRedPoint.gameObject:SetActiveEx(count >= 0)
end

function XUiPanelCharacterOwnedInfo:UpdateView(characterId)
    self.CharacterId = characterId

    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(characterId)
    self.TxtName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName

    local character = XMVCA.XCharacter:GetCharacter(characterId)
    self.RImgTypeIcon:SetRawImage(XMVCA.XCharacter:GetNpcTypeIcon(character.Type))
    self.TxtLv.text = math.floor(character.Ability)

    self.WeaponGrid = self.WeaponGrid or XUiGridEquip.New(self.GridWeapon, self.UiRoot)
    local usingWeaponId = XMVCA.XEquip:GetCharacterWeaponId(characterId)
    self.WeaponGrid:Refresh(usingWeaponId)

    local partner = XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(characterId)
    if partner then
        self.PartnerIcon:SetRawImage(partner:GetIcon())
    end
    self.PartnerIcon.gameObject:SetActiveEx(partner ~= nil)

    self.WearingAwarenessGrids = self.WearingAwarenessGrids or {}
    for _, equipSite in pairs(XEnumConst.EQUIP.EQUIP_SITE.AWARENESS) do
        self.WearingAwarenessGrids[equipSite] = self.WearingAwarenessGrids[equipSite] or XUiGridEquip.New(CS.UnityEngine.Object.Instantiate(self.GridAwareness), self.UiRoot)
        self.WearingAwarenessGrids[equipSite].Transform:SetParent(self["PanelAwareness" .. equipSite], false)

        local equipId = XMVCA.XEquip:GetCharacterEquipId(characterId, equipSite)
        if not equipId then
            self.WearingAwarenessGrids[equipSite]:Close()
            self["PanelNoAwareness" .. equipSite].gameObject:SetActiveEx(true)
        else
            self.WearingAwarenessGrids[equipSite]:Open()
            self["BtnAwarenessReplace" .. equipSite].transform:SetAsLastSibling()
            self["PanelNoAwareness" .. equipSite].gameObject:SetActiveEx(false)
            self.WearingAwarenessGrids[equipSite]:Refresh(equipId)
        end
    end

    local elementList = XMVCA.XCharacter:GetCharacterAllElement(characterId, true)
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if elementList[i] then
            rImg.gameObject:SetActiveEx(true)
            local elementConfig = XMVCA.XCharacter:GetCharElement(elementList[i])
            rImg:SetRawImage(elementConfig.Icon)
        else
            rImg.gameObject:SetActiveEx(false)
        end
    end

    XRedPointManager.Check(self.RedPointId, characterId)

    -- self:UpdateSupport(characterId)
end

--------支援相关 begin---------
function XUiPanelCharacterOwnedInfo:UpdateSupport(characterId)
    local supportData = self.SupportData
    local openRecommend = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipGuideRecommend)
    self.BtnRecommend.gameObject:SetActiveEx(not XUiManager.IsHideFunc and openRecommend)
    if XTool.IsTableEmpty(supportData) then return end

    self.BtnLevelUp.gameObject:SetActiveEx(false)

    local showSupport = not supportData.CheckInSupportCb(characterId)
    self.BtnSupport.gameObject:SetActiveEx(showSupport)

    local showSupportCancel = supportData.CanSupportCancel and supportData.CheckInSupportCb(characterId)
    self.BtnSupportCancel.gameObject:SetActiveEx(showSupportCancel)

    self.BtnRecommend.gameObject:SetActiveEx(not supportData.HideBtnRecommend and not XUiManager.IsHideFunc and openRecommend)
end
--------支援相关 end---------
function XUiPanelCharacterOwnedInfo:AddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace6, self.OnBtnAwarenessReplace6Click)
    XUiHelper.RegisterClickEvent(self, self.BtnLevelUp, self.OnBtnLevelUpClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace5, self.OnBtnAwarenessReplace5Click)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace4, self.OnBtnAwarenessReplace4Click)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace3, self.OnBtnAwarenessReplace3Click)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace2, self.OnBtnAwarenessReplace2Click)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace1, self.OnBtnAwarenessReplace1Click)
    XUiHelper.RegisterClickEvent(self, self.BtnWeaponReplace, self.OnBtnWeaponReplaceClick)
    XUiHelper.RegisterClickEvent(self, self.BtnJoin, self.OnBtnJoinClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCareerTips, self.OnBtnCareerTipsClick)
    self.BtnElementDetail.CallBack = function() self:OnBtnElementDetailClick() end
    self.BtnSupport.CallBack = function() self:OnBtnSupportClick() end
    self.BtnSupportCancel.CallBack = function() self:OnBtnSupportCancelClick() end
    self.BtnCarryPartner.CallBack = function() self:OnCarryPartnerClick() end
    self.BtnRecommend.CallBack = function() XDataCenter.EquipGuideManager.OpenEquipGuideView(self.CharacterId) end
end

function XUiPanelCharacterOwnedInfo:OnBtnAwarenessReplace5Click()
    self:OnAwarenessClick(5)
end

function XUiPanelCharacterOwnedInfo:OnBtnAwarenessReplace4Click()
    self:OnAwarenessClick(4)
end

function XUiPanelCharacterOwnedInfo:OnBtnAwarenessReplace3Click()
    self:OnAwarenessClick(3)
end

function XUiPanelCharacterOwnedInfo:OnBtnAwarenessReplace2Click()
    self:OnAwarenessClick(2)
end

function XUiPanelCharacterOwnedInfo:OnBtnAwarenessReplace1Click()
    self:OnAwarenessClick(1)
end

function XUiPanelCharacterOwnedInfo:OnBtnAwarenessReplace6Click()
    self:OnAwarenessClick(6)
end

function XUiPanelCharacterOwnedInfo:OnAwarenessClick(site)
    if self.ForbidGotoEquip or self.IsSupport then return end
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Equip) then
        return
    end
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipAwarenessReplace(self.CharacterId, site)
end

function XUiPanelCharacterOwnedInfo:OnBtnCareerTipsClick()
    XLuaUiManager.Open("UiCharacterCarerrTips",self.CharacterId)
end

function XUiPanelCharacterOwnedInfo:OnBtnWeaponReplaceClick()
    if self.ForbidGotoEquip or self.IsSupport then return end
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Equip) then
        return
    end
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipReplace(self.CharacterId)
end

function XUiPanelCharacterOwnedInfo:OnBtnLevelUpClick()
    if self.ClickCb then self.ClickCb() end
end

function XUiPanelCharacterOwnedInfo:OnBtnJoinClick()
    XDataCenter.AssistManager.ChangeAssistCharacterId(self.CharacterId, function(code)
        if (code == XCode.Success) then
            XLuaUiManager.Close("UiCharacter")
        end
    end)
end

function XUiPanelCharacterOwnedInfo:OnBtnElementDetailClick()
    XLuaUiManager.Open("UiCharacterAttributeDetail", self.CharacterId, XEnumConst.UiCharacterAttributeDetail.BtnTab.Element)
end

function XUiPanelCharacterOwnedInfo:OnBtnSupportClick()
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

function XUiPanelCharacterOwnedInfo:OnCarryPartnerClick()
    XDataCenter.PartnerManager.GoPartnerCarry(self.CharacterId, true)
end

function XUiPanelCharacterOwnedInfo:OnBtnSupportCancelClick()
    local characterId = self.CharacterId
    if self.SupportData then
        if self.SupportData.CancelCharacterCb then
            self.SupportData.CancelCharacterCb(characterId)
        end
    end
end

function XUiPanelCharacterOwnedInfo:Show()
    self.GameObject:SetActive(true)
    self:OnEnable()
end

function XUiPanelCharacterOwnedInfo:Hide()
    self.GameObject:SetActive(false)
end

return XUiPanelCharacterOwnedInfo
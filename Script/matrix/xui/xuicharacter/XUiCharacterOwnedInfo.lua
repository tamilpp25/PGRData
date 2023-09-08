local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")

local XUiCharacterOwnedInfo = XLuaUiManager.Register(XLuaUi, "UiCharacterOwnedInfo")

function XUiCharacterOwnedInfo:OnAwake()
    self:AddListener()
end

function XUiCharacterOwnedInfo:OnStart(forbidGotoEquip, clickCb, isSupport, supportData, ui)
    self.ForbidGotoEquip = forbidGotoEquip
    self.IsSupport = isSupport
    self.ClickCb = clickCb
    self.SupportData = supportData
    self.ParentUi = ui

    self.BtnLevelUp.gameObject:SetActiveEx(not forbidGotoEquip and not self.IsSupport)
    self.BtnJoin.gameObject:SetActiveEx(forbidGotoEquip ~= nil)
    self.BtnSupport.gameObject:SetActiveEx(self.IsSupport ~= nil)
    self.BtnSupportCancel.gameObject:SetActiveEx(false)

    if self.Partner then
        self.Partner.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
    end

    self:RegisterRedPointEvent()
end

function XUiCharacterOwnedInfo:OnEnable()
    self:UpdateView(self.CharacterId)

end

function XUiCharacterOwnedInfo:OnDisable()

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

    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(characterId)
    self.TxtName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName

    local character = XDataCenter.CharacterManager.GetCharacter(characterId)
    self.RImgTypeIcon:SetRawImage(XCharacterConfigs.GetNpcTypeIcon(character.Type))
    self.TxtLv.text = math.floor(character.Ability)

    self.WeaponGrid = self.WeaponGrid or XUiGridEquip.New(self.GridWeapon, self)
    local usingWeaponId = XDataCenter.EquipManager.GetCharacterWearingWeaponId(characterId)
    self.WeaponGrid:Refresh(usingWeaponId)
    
    -- 可以进入装备界面才检测触发引导
    if not self.ParentUi.ForbidGotoEquip then
        XDataCenter.EquipManager.CheckOverrunGuide(usingWeaponId)
    end

    local partner = XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(characterId)
    if partner then
        self.PartnerIcon:SetRawImage(partner:GetIcon())
    end
    self.PartnerIcon.gameObject:SetActiveEx(partner ~= nil)

    self.WearingAwarenessGrids = self.WearingAwarenessGrids or {}
    local curr = 0
    for _, equipSite in pairs(XEquipConfig.EquipSite.Awareness) do
        self.WearingAwarenessGrids[equipSite] = self.WearingAwarenessGrids[equipSite] or XUiGridEquip.New(CS.UnityEngine.Object.Instantiate(self.GridAwareness), self)
        self.WearingAwarenessGrids[equipSite].Transform:SetParent(self["PanelAwareness" .. equipSite], false)

        local equipId = XDataCenter.EquipManager.GetWearingEquipIdBySite(characterId, equipSite)
        if not equipId then
            self.WearingAwarenessGrids[equipSite]:Close()
            self["PanelNoAwareness" .. equipSite].gameObject:SetActiveEx(true)
        else
            self.WearingAwarenessGrids[equipSite]:Open()
            self["BtnAwarenessReplace" .. equipSite].transform:SetAsLastSibling()
            self["PanelNoAwareness" .. equipSite].gameObject:SetActiveEx(false)
            self.WearingAwarenessGrids[equipSite]:Refresh(equipId)

            -- 检查有多少个激活的公约标识
            local chapterData = XDataCenter.FubenAwarenessManager.GetChapterDataBySiteNum(equipSite)
            if chapterData and chapterData:IsOccupy() then
                for i = 1, XEquipConfig.MAX_RESONANCE_SKILL_COUNT do
                    local bindCharId = XDataCenter.EquipManager.GetResonanceBindCharacterId(equipId, i)
                    local awaken = XDataCenter.EquipManager.IsEquipPosAwaken(equipId, i)
                    if awaken and bindCharId == characterId then
                        curr = curr + 1
                    end
                end
            end
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

    -- 公约加成
    self.TxtOcuupyHarm.text =  CS.XTextManager.GetText("AwarenessTotalHarm", curr)

    XRedPointManager.Check(self.RedPointId, characterId)

    self:UpdateSupport(characterId)
end

--------支援相关 begin---------
function XUiCharacterOwnedInfo:UpdateSupport(characterId)
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
    self:RegisterClickEvent(self.BtnAwarenessOcuupy, self.OnBtnAwarenessOcuupyClick)
    self.BtnElementDetail.CallBack = function() self:OnBtnElementDetailClick() end
    self.BtnSupport.CallBack = function() self:OnBtnSupportClick() end
    self.BtnSupportCancel.CallBack = function() self:OnBtnSupportCancelClick() end
    self.BtnCarryPartner.CallBack = function() self:OnCarryPartnerClick() end
    self.BtnRecommend.CallBack = function() XDataCenter.EquipGuideManager.OpenEquipGuideView(self.CharacterId) end
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
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipAwarenessReplace(self.CharacterId, site)
end

function XUiCharacterOwnedInfo:OnBtnCareerTipsClick()
    XLuaUiManager.Open("UiCharacterCarerrTips",self.CharacterId)
end

function XUiCharacterOwnedInfo:OnBtnWeaponReplaceClick()
    if self.ForbidGotoEquip or self.IsSupport then return end
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Equip) then
        return
    end
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipReplace(self.CharacterId)
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

function XUiCharacterOwnedInfo:OnBtnAwarenessOcuupyClick()
    XLuaUiManager.Open("UiAwarenessOccupyProgress", self.CharacterId)
end
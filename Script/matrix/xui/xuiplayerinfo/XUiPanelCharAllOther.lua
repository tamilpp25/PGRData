XUiPanelCharAllOther = XClass(nil, "XUiPanelCharAllOther")

local XUiGridEquipOther = require("XUi/XUiPlayerInfo/XUiGridEquipOther")

-- partner : XPartner
function XUiPanelCharAllOther:Ctor(ui,parent,character,equipList,assignChapterRecords, partner, awarenessSetPositions)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    self.Character = character
    self.EquipList = equipList
    self.AssignChapterRecords = assignChapterRecords
    -- XPartner
    self.Partner = partner
    self.AwarenessSetPositions = awarenessSetPositions

    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag

    XTool.InitUiObject(self)
    self:AddListener()
end

function XUiPanelCharAllOther:AddListener()
    CsXUiHelper.RegisterClickEvent(self.BtnWeaponReplace, function() self:OnBtnWeaponReplaceClick() end)
    CsXUiHelper.RegisterClickEvent(self.BtnCarryPartner, function() self:OnBtnCarryPartnerClicked() end)
end

-- partner : XPartner
function XUiPanelCharAllOther:ShowPanel(character, weapon, awareness, partner, assignChapterRecords, awarenessSetPositions)
    self.Character = character
    self.CharacterId = character.Id
    self.Weapon = weapon
    self.Awareness = awareness
    self.Partner = partner
    self.AwarenessSetPositions = awarenessSetPositions

    self.GameObject:SetActive(true)
    self:UpdatePanel(character, weapon, awareness, partner)

    -- 辅助机
    self.RImgPartnerIcon.gameObject:SetActiveEx(partner ~= nil)
    self.PanelNoPartner.gameObject:SetActiveEx(not partner)
    if partner then
        self.RImgPartnerIcon:SetRawImage(partner:GetIcon())
        self.IconPartnerQuality:SetRawImage(partner:GetCharacterQualityIcon())
    end
end

function XUiPanelCharAllOther:HidePanel()
    self.GameObject:SetActive(false)
end

-- partner : XPartner
function XUiPanelCharAllOther:UpdatePanel(character, weapon, awareness, partner)
    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(self.CharacterId)
    local detailConfig = XCharacterConfigs.GetCharDetailTemplate(self.CharacterId)

    self.TxtName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName
    self.RImgTypeIcon:SetRawImage(XCharacterConfigs.GetNpcTypeIcon(character.Type))
    self.ImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(character.Quality))
    self.ImgUniframe.gameObject:SetActiveEx(self.CharacterAgency:GetIsIsomer(character.Id))

    local ability = self.CharacterAgency:GetCharacterAbilityOther(character, self.EquipList, self.AssignChapterRecords, partner)
    self.TxtLv.text = math.floor(ability)
    self.TxtCharLv.text = math.floor(character.Level)

    local elementList = detailConfig.ObtainElementList
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if elementList[i] then
            rImg.gameObject:SetActive(true)
            local elementConfig = XCharacterConfigs.GetCharElement(elementList[i])
            rImg:SetRawImage(elementConfig.Icon)
        else
            rImg.gameObject:SetActive(false)
        end
    end

    self.WeaponGrid = self.WeaponGrid or XUiGridEquipOther.New(self.GridWeapon, self)
    self.WeaponGrid:Refresh(weapon)

    self.WearingAwarenessGrids = self.WearingAwarenessGrids or {}
    for _, equipSite in pairs(XEquipConfig.EquipSite.Awareness) do

        local equip
        for _, v in pairs(awareness) do
            if  XDataCenter.EquipManager.GetEquipSiteByEquipData(v) == equipSite then
                equip = v
            end
        end

        self.WearingAwarenessGrids[equipSite] = self.WearingAwarenessGrids[equipSite]
                or XUiGridEquipOther.New(CS.UnityEngine.Object.Instantiate(self.GridAwareness), self, function()
            XLuaUiManager.Open("UiEquipDetailOther", equip, self.Character)
        end)

        self.WearingAwarenessGrids[equipSite].Transform:SetParent(self["PanelAwareness" .. equipSite], false)

        if not equip then
            self.WearingAwarenessGrids[equipSite].GameObject:SetActive(false)
            self["PanelNoAwareness" .. equipSite].gameObject:SetActive(true)
        else
            self.WearingAwarenessGrids[equipSite].GameObject:SetActive(true)
            self["PanelNoAwareness" .. equipSite].gameObject:SetActive(false)
            self.WearingAwarenessGrids[equipSite]:Refresh(equip, self.AwarenessSetPositions, character.Id)
        end
    end
end

function XUiPanelCharAllOther:OnBtnWeaponReplaceClick()
    XLuaUiManager.Open("UiEquipDetailOther", self.Weapon, self.Character)
end

function XUiPanelCharAllOther:OnBtnCarryPartnerClicked()
    if self.Partner == nil then 
        XUiManager.TipError(CS.XTextManager.GetText("PartnerUnequipped"))
        return
    end
    -- -- 检查该玩家是否满足开启伙伴系统的等级功能
    -- if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Partner) then
    --     return
    -- end
    XLuaUiManager.Open("UiPartnerPropertyOther", self.Partner)
end
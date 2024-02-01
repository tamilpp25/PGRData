-- 通用装备意识预置(查看其他玩家信息)
local XUiPanelCharInfoWithEquip = require("XUi/XUiCharacterV2P6/Grid/XUiPanelCharInfoWithEquip")
local XUiGridEquipOtherV2P7 = require("XUi/XUiPlayerInfo/XUiGridEquipOtherV2P7")
local XUiGridResonanceDoubleSkillOther = require("XUi/XUiEquip/XUiGridResonanceDoubleSkillOther")

---@class XUiPanelCharInfoWithEquipOther:XUiPanelCharInfoWithEquip
local XUiPanelCharInfoWithEquipOther = XClass(XUiPanelCharInfoWithEquip, "XUiPanelCharInfoWithEquipOther")
local CSInstantiate = CS.UnityEngine.Object.Instantiate

function XUiPanelCharInfoWithEquipOther:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnType, self.OnBtnCareerTipsClick)
    XUiHelper.RegisterClickEvent(self, self.BtnUniframeTip, self.OnBtnUniframeTipClick)
    XUiHelper.RegisterClickEvent(self, self.BtnElementDetail, self.OnBtnElementDetailClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCarryPartner, self.OnCarryPartnerClick)

    self.XGoInputHandler:AddDragUpListener(function ()
        self:OnDragUp()
    end)
    self.XGoInputHandler:AddDragDownListener(function ()
        self:OnDragDown()
    end)

    XUiHelper.RegisterClickEvent(self, self.BtnGeneralSkill1, function ()
        self:OnBtnGeneralSkillClick(1)
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnGeneralSkill2, function ()
        self:OnBtnGeneralSkillClick(2)
    end)
    
    self:SetForbidGotoEquip(true)
end

-- 包含以下字段的data
function XUiPanelCharInfoWithEquipOther:UpdateCharacter(data)
    if XTool.IsTableEmpty(data) then
        XLog.Error("传入的data为空")
        return
    end

    self.Character = data.Character
    self.EquipList = data.EquipList
    self.WeaponFashionId = data.WeaponFashionId
    self.AssignChapterRecords = data.AssignChapterRecords
    self.Partner = data.Partner
    self.AwarenessSetPositions = data.AwarenessSetPositions

    --把服务器发来的装备数据分成武器与意识
    self.Awareness = {}
    for _, v in ipairs(data.EquipList) do
        if XDataCenter.EquipManager.IsClassifyEqualByTemplateId(v.TemplateId, XEquipConfig.Classify.Weapon) then
            self.Weapon = v
        else
            table.insert(self.Awareness, v)
        end
    end
    table.sort(self.Awareness, function (a, b)
        local aSite = XDataCenter.EquipManager.GetEquipSiteByEquipData(a)
        local bSite = XDataCenter.EquipManager.GetEquipSiteByEquipData(b)
        return aSite < bSite
    end)

    self.CharacterId = data.Character.Id
    self:UpdateView()
end

function XUiPanelCharInfoWithEquipOther:UpdateRoleView()
    -- character, weapon, partner
    local character = self.Character
    local weapon = self.Weapon
    local partner = self.Partner

    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(self.CharacterId)
    local detailConfig = XMVCA.XCharacter:GetCharDetailTemplate(self.CharacterId)

    -- 机体名
    self.TxtName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName

    -- 职业
    local career = XMVCA.XCharacter:GetCharacterCareer(character.Id)
    local careerIcon = XMVCA.XCharacter:GetNpcTypeIcon(career)
    self.BtnType:SetRawImage(careerIcon)

    local showUniframe = XMVCA.XCharacter:GetIsIsomer(character.Id)
    self.BtnUniframeTip.gameObject:SetActiveEx(showUniframe)

    -- 品质
    self.ImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(character.Quality))
    self.TxtStar.text = character.Star
    self.PanelStage.gameObject:SetActiveEx(character.Quality < XMVCA.XCharacter:GetCharMaxQuality(self.CharacterId))

    -- 初始品质
    local initQuality = XMVCA.XCharacter:GetCharacterInitialQuality(character.Id)
    local initColor = XMVCA.XCharacter:GetModelCharacterQualityIcon(initQuality).InitColor
    self.QualityRail.color = XUiHelper.Hexcolor2Color(initColor)

    -- 元素
    local elementList = detailConfig.ObtainElementList
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if elementList[i] then
            rImg.gameObject:SetActive(true)
            local elementConfig = XMVCA.XCharacter:GetCharElement(elementList[i])
            rImg:SetRawImage(elementConfig.Icon)
        else
            rImg.gameObject:SetActive(false)
        end
    end

    -- 机制
    local generalSkillIds = XMVCA.XCharacter:GetCharacterGeneralSkillIds(self.CharacterId)
    for i = 1, self.ListGeneralSkillDetail.childCount, 1 do
        local id = generalSkillIds[i]
        self["BtnGeneralSkill"..i].gameObject:SetActiveEx(id)
        if id then
            local generalSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[id]
            self["BtnGeneralSkill"..i]:SetRawImage(generalSkillConfig.Icon)
        end
    end

    -- 等级
    self.TxtLevel.text = character.Level

    -- 战斗参数
    self.TxtFight.text = XMVCA.XCharacter:GetCharacterAbilityOther(character, self.EquipList, self.AssignChapterRecords, partner)

    -- 辅助机
    local imgEmptyBan = self.PanelNoPartner:FindTransform("ImgEmptyBanClick") -- 禁用点击图标
    if partner then
        self.PartnerIcon:SetRawImage(partner:GetIcon())
        self.IconPartnerQuality:SetRawImage(partner:GetCharacterQualityIcon())
    end
    imgEmptyBan.gameObject:SetActiveEx(partner == nil and self.ForbidGotoEquip)
    self.PanelNoPartner.gameObject:SetActiveEx(partner == nil)
    self.PartnerIcon.gameObject:SetActiveEx(partner ~= nil)
    self.IconQualityBg.gameObject:SetActiveEx(partner ~= nil)
    self.IconPartnerQuality.gameObject:SetActiveEx(partner ~= nil)

    self.WeaponGrid = self.WeaponGrid or XUiGridEquipOtherV2P7.New(self.GridWeapon, self, self)
    self.WeaponGrid:Open()
    self.WeaponGrid:Refresh(weapon)
end

function XUiPanelCharInfoWithEquipOther:UpdateAwarenessView()
    local character = self.Character
    local awareness = self.Awareness

    for _, equipSite in pairs(XEquipConfig.EquipSite.Awareness) do

        local equip = awareness[equipSite]
        -- for _, v in pairs(awareness) do
        --     if XDataCenter.EquipManager.GetEquipSiteByEquipData(v) == equipSite then
        --         equip = v
        --     end
        -- end

        self.WearingAwarenessGrids[equipSite] = self.WearingAwarenessGrids[equipSite] or 
        XUiGridEquipOtherV2P7.New(CSInstantiate(self.GridAwareness), self, self, function()
            XLuaUiManager.Open("UiEquipDetailOther", equip, self.Character)
        end)

        self.WearingAwarenessGrids[equipSite].Transform:SetParent(self["PanelAwareness" .. equipSite], false)

        if not equip then
            self.WearingAwarenessGrids[equipSite]:Close()
            self["PanelNoAwareness" .. equipSite].gameObject:SetActive(true)
        else
            self.WearingAwarenessGrids[equipSite]:Open()
            self["PanelNoAwareness" .. equipSite].gameObject:SetActive(false)
            self.WearingAwarenessGrids[equipSite]:Refresh(equip, self.AwarenessSetPositions, character.Id)
        end
    end

    self:UpdatePanelSuitCount()
    self:UpdatePanelResonanceSkill()
end

function XUiPanelCharInfoWithEquipOther:UpdatePanelSuitCount()
    if not self.SuitItemList then
        self.SuitItemList = {self.SuitItem}
    end

    -- 隐藏所有
    for _, suitItem in ipairs(self.SuitItemList) do
        suitItem.gameObject:SetActiveEx(false)
    end
    self.SuitOverrunItem.gameObject:SetActiveEx(false)

    -- 套装列表
    local suitInfoList = XMVCA.XEquip:GetWearingSuitInfoListByEquipListAndWeapon(self.Awareness, self.Weapon)
    local itemIndex = 1
    local haveSuit = false
    for i, suitInfo in ipairs(suitInfoList) do
        if suitInfo.Count ~= 1 then
            haveSuit = true
            local itemGo
            if suitInfo.IsOverrun then
                itemGo = self.SuitOverrunItem
            else
                itemGo = self.SuitItemList[itemIndex]
                if not itemGo then
                    itemGo = CSInstantiate(self.SuitItem, self.SuitItem.transform.parent)
                    table.insert(self.SuitItemList, itemGo)
                end
                itemIndex = itemIndex + 1
            end

            itemGo.gameObject:SetActiveEx(true)
            itemGo.transform:SetAsLastSibling()
            local uiObj = itemGo:GetComponent("UiObject")
            uiObj:GetObject("TxtSuitName").text = suitInfo.Name
            uiObj:GetObject("TxtSuitCount").text = suitInfo.Count
        end
    end
    self.PanelNoAddition.gameObject:SetActiveEx(not haveSuit)
    self.BtnAddition.gameObject:SetActiveEx(haveSuit)
end

function XUiPanelCharInfoWithEquipOther:UpdatePanelResonanceSkill()
    for index = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local grid = self.DoubleResonanceList[index]
        if not grid then
            local go = CSInstantiate(self.GridDoubleResonanceSkill, self.PanelResonanceSkill)
            grid = XUiGridResonanceDoubleSkillOther.New(go, self)
            self.DoubleResonanceList[index] = grid
            grid:Open()
        end

        grid:RefreshBySite(self.Awareness[index], self.Character.Id, index)
    end
end

function XUiPanelCharInfoWithEquipOther:OnCarryPartnerClick()
    if not self.Partner then return end
    XLuaUiManager.Open("UiPartnerPropertyOther", self.Partner)
end

return XUiPanelCharInfoWithEquipOther
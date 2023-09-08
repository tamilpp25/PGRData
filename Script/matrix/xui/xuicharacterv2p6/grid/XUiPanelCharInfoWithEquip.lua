-- 通用装备意识预置
---@class XUiPanelCharInfoWithEquip XUiPanelCharInfoWithEquip
local XUiPanelCharInfoWithEquip = XClass(XUiNode, "XUiPanelCharInfoWithEquip")
local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")
local XUiGridResonanceDoubleSkillV2P6 = require("XUi/XUiEquip/XUiGridResonanceDoubleSkillV2P6")
local CSInstantiate = CS.UnityEngine.Object.Instantiate

function XUiPanelCharInfoWithEquip:Ctor(ui, parent, rootUi)
    self.RootUi = rootUi
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    ---@type XCharacterAgency
    self.CharacterAgency = ag

    ag = XMVCA:GetAgency(ModuleId.XEquip)
    ---@type XEquipAgency
    self.EquipAgency = ag
    self:InitButton()

    self.IsShowPanelAwareness = false
end

function XUiPanelCharInfoWithEquip:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnType, self.OnBtnCareerTipsClick)
    XUiHelper.RegisterClickEvent(self, self.BtnUniframeTip, self.OnBtnUniframeTipClick)
    XUiHelper.RegisterClickEvent(self, self.BtnElementDetail, self.OnBtnElementDetailClick)
    XUiHelper.RegisterClickEvent(self, self.BtnWeaponReplace, self.OnBtnWeaponReplaceClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCarryPartner, self.OnCarryPartnerClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessOcuupy, self.OnBtnAwarenessOcuupyClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAddition, self.OnPanelAdditionClick)

    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace1, function ()
        self:OnAwarenessClick(1)
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace2, function ()
        self:OnAwarenessClick(2)
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace3, function ()
        self:OnAwarenessClick(3)
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace4, function ()
        self:OnAwarenessClick(4)
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace5, function ()
        self:OnAwarenessClick(5)
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace6, function ()
        self:OnAwarenessClick(6)
    end)
    

    self.XGoInputHandler:AddDragUpListener(function ()
        self:OnDragUp()
    end)
    self.XGoInputHandler:AddDragDownListener(function ()
        self:OnDragDown()
    end)

    XEventManager.AddEventListener(XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY, self.OnEquipTakeOff, self)
end

function XUiPanelCharInfoWithEquip:OnDisable()
end

function XUiPanelCharInfoWithEquip:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY, self.OnEquipTakeOff, self)
end

function XUiPanelCharInfoWithEquip:InitData(onFoldCb, onUnFoldCb)
    self.OnFoldCb = onFoldCb
    self.OnUnFoldCb = onUnFoldCb

    self.WearingAwarenessGrids = {}
    self.DoubleResonanceList = {}
    self.GridDoubleResonanceSkill.gameObject:SetActiveEx(false)
end

function XUiPanelCharInfoWithEquip:SetForbidGotoEquip(flag)
    self.ForbidGotoEquip = flag
end

function XUiPanelCharInfoWithEquip:UpdateCharacter(characterId)
    self.CharacterId = characterId
    self:UpdateView()
end

function XUiPanelCharInfoWithEquip:UpdateView()
    -- 只刷新当前展开的面板
    self:UpdateAwarenessView()
    self:UpdateRoleView()
end

-- 刷新角色面板
function XUiPanelCharInfoWithEquip:UpdateRoleView()
    local characterId = self.CharacterId

    --------------- 信息相关 顶部部分
    -- 机体名
    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(characterId)
    self.TxtName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName

    -- 职业
    local career = self.CharacterAgency:GetCharacterCareer(characterId)
    local careerIcon = XCharacterConfigs.GetNpcTypeIcon(career)
    self.BtnType:SetRawImage(careerIcon)

    local showUniframe = self.CharacterAgency:GetIsIsomer(characterId)
    self.BtnUniframeTip.gameObject:SetActiveEx(showUniframe)

    -- 品质
    self.ImgQuality:SetRawImage(XCharacterConfigs.GetCharacterQualityIcon(self.CharacterAgency:GetCharacterQuality(characterId)))
    -- 初始品质
    local initQuality = self.CharacterAgency:GetCharacterInitialQuality(characterId)
    local initColor = self.CharacterAgency:GetModelCharacterQualityIcon(initQuality).InitColor
    self.QualityRail.color = XUiHelper.Hexcolor2Color(initColor)

    -- 元素
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

    -- 等级
    self.TxtLevel.text = self.CharacterAgency:GetCharacterLevel(characterId)

    -- 战斗参数
    self.TxtFight.text = self.CharacterAgency:GetCharacterHaveRobotAbilityById(self.CharacterId)

    -------- 意识相关 下半部分-------------
    self.WeaponGrid = self.WeaponGrid or XUiGridEquip.New(self.GridWeapon, self.RootUi)
    self.WeaponGrid:Open()
    local usingWeaponId = XDataCenter.EquipManager.GetCharacterWearingWeaponId(characterId)
    self.WeaponGrid:Refresh(usingWeaponId)
    XDataCenter.EquipManager.CheckOverrunGuide(usingWeaponId)

    -- 辅助机
    local imgEmptyBan = self.PanelNoPartner:FindTransform("ImgEmptyBanClick") -- 禁用点击图标
    local partner = XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(characterId)
    if partner then
        self.PartnerIcon:SetRawImage(partner:GetIcon())
        self.IconPartnerQuality:SetRawImage(partner:GetCharacterQualityIcon())
    end
    imgEmptyBan.gameObject:SetActiveEx(partner == nil and self.ForbidGotoEquip)
    self.PanelNoPartner.gameObject:SetActiveEx(partner == nil)
    self.PartnerIcon.gameObject:SetActiveEx(partner ~= nil)
    self.IconQualityBg.gameObject:SetActiveEx(partner ~= nil)
    self.IconPartnerQuality.gameObject:SetActiveEx(partner ~= nil)
end

-- 刷新意识面板
function XUiPanelCharInfoWithEquip:UpdateAwarenessView()
    local characterId = self.CharacterId
    local curr = 0
    local haveAwareness = false
    for _, equipSite in pairs(XEquipConfig.EquipSite.Awareness) do
        self.WearingAwarenessGrids[equipSite] = self.WearingAwarenessGrids[equipSite] or XUiGridEquip.New(CS.UnityEngine.Object.Instantiate(self.GridAwareness), self.RootUi)
        self.WearingAwarenessGrids[equipSite].Transform:SetParent(self["PanelAwareness" .. equipSite], false)

        local imgEmptyBan = self["PanelNoAwareness" .. equipSite]:FindTransform("ImgEmptyBanClick") -- 禁用点击图标
        local equipId = XDataCenter.EquipManager.GetWearingEquipIdBySite(characterId, equipSite)
        if not equipId then
            self.WearingAwarenessGrids[equipSite]:Close()
            self["PanelNoAwareness" .. equipSite].gameObject:SetActiveEx(true)
            imgEmptyBan.gameObject:SetActiveEx(self.ForbidGotoEquip)
        else
            haveAwareness = true
            imgEmptyBan.gameObject:SetActiveEx(false)
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
    
    -- 公约加成
    self.TxtOcuupyHarm.text =  CS.XTextManager.GetText("AwarenessTotalHarm", curr)

    -- 套装数量
    self:UpdatePanelSuitCount()

    -- 共鸣技能
    self:UpdatePanelResonanceSkill()
end

-- 刷新套装数量列表
function XUiPanelCharInfoWithEquip:UpdatePanelSuitCount()
    if not self.SuitItemList then
        self.SuitItemList = {self.SuitItem}
    end

    -- 隐藏所有
    for _, suitItem in ipairs(self.SuitItemList) do
        suitItem.gameObject:SetActiveEx(false)
    end
    self.SuitOverrunItem.gameObject:SetActiveEx(false)

    -- 套装列表
    local suitInfoList = self.EquipAgency:GetWearingSuitInfoList(self.CharacterId)
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

-- 刷新共鸣技能面板
function XUiPanelCharInfoWithEquip:UpdatePanelResonanceSkill()
    for index = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local grid = self.DoubleResonanceList[index]
        if not grid then
            local go = CSInstantiate(self.GridDoubleResonanceSkill, self.PanelResonanceSkill)
            grid = XUiGridResonanceDoubleSkillV2P6.New(go)
            self.DoubleResonanceList[index] = grid
            grid.GameObject:SetActive(true)
        end

        grid:RefreshBySite(self.CharacterId, index)
        grid:SetForbidGotoEquip(self.ForbidGotoEquip)
    end
end

-- 展开意识面板
function XUiPanelCharInfoWithEquip:OnDragUp()
    local targetValue = 0
    if self.Scrollbar.value == targetValue then
        return
    end
    CS.XUiManager.Instance:SetMask(true)
    self.PanelSc:DOVerticalNormalizedPos(targetValue, 0.3):OnComplete(function ()
        CS.XUiManager.Instance:SetMask(false)
    end)
end

function XUiPanelCharInfoWithEquip:OnDragDown()
    local targetValue = 1
    if self.Scrollbar.value == targetValue then
        return
    end
    CS.XUiManager.Instance:SetMask(true)
    self.PanelSc:DOVerticalNormalizedPos(targetValue, 0.3):OnComplete(function ()
        CS.XUiManager.Instance:SetMask(false)
    end)
end

function XUiPanelCharInfoWithEquip:OnBtnCareerTipsClick()
    XLuaUiManager.Open("UiCharacterCareerTipsV2P6", self.CharacterId)
end

function XUiPanelCharInfoWithEquip:OnBtnUniframeTipClick()
    XLuaUiManager.Open("UiCharacterUniframeBubbleV2P6")
end

function XUiPanelCharInfoWithEquip:OnBtnElementDetailClick()
    XLuaUiManager.Open("UiCharacterElementDetail", self.CharacterId)
end

function XUiPanelCharInfoWithEquip:OnBtnWeaponReplaceClick()
    if self.ForbidGotoEquip then return end
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Equip) then
        return
    end
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipReplace(self.CharacterId)
end

function XUiPanelCharInfoWithEquip:OnCarryPartnerClick()
    if self.ForbidGotoEquip then return end
    XDataCenter.PartnerManager.GoPartnerCarry(self.CharacterId, true)
end

function XUiPanelCharInfoWithEquip:OnBtnAwarenessOcuupyClick()
    XLuaUiManager.Open("UiAwarenessOccupyProgress", self.CharacterId)
end

function XUiPanelCharInfoWithEquip:OnAwarenessClick(site)
    if self.ForbidGotoEquip then return end
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Equip) then
        return
    end
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipAwarenessReplace(self.CharacterId, site)
end

function XUiPanelCharInfoWithEquip:OnBtnAutoTakeOffClick()
    local wearingEquipIds = XDataCenter.EquipManager.GetCharacterWearingAwarenessIds(self.CharacterId)
    if not wearingEquipIds or not next(wearingEquipIds) then
        XUiManager.TipText("EquipAutoTakeOffNotWearingEquip")
        return
    end
    XMVCA:GetAgency(ModuleId.XEquip):TakeOff(wearingEquipIds)
end

function XUiPanelCharInfoWithEquip:OnBtnAwarenessSuitClick()
    XLuaUiManager.Open("UiEquipAwarenessSuitPrefab", self.CharacterId)
end

function XUiPanelCharInfoWithEquip:OnPanelAdditionClick()
    XLuaUiManager.Open("UiEquipSuitSkillV2P6", self.CharacterId)
end

-- 卸下/一键卸下装备事件
function XUiPanelCharInfoWithEquip:OnEquipTakeOff()
    self:UpdateView()
end

return XUiPanelCharInfoWithEquip
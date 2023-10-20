-- 通用装备意识预置
---@class XUiPanelEquipV2P6 XUiPanelEquipV2P6
local XUiPanelEquipV2P6 = XClass(XUiNode, "XUiPanelEquipV2P6")
local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")
local XUiGridResonanceDoubleSkillV2P6 = require("XUi/XUiEquip/XUiGridResonanceDoubleSkillV2P6")
local CSInstantiate = CS.UnityEngine.Object.Instantiate

function XUiPanelEquipV2P6:Ctor(ui, parent, rootUi)
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

function XUiPanelEquipV2P6:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnWeaponReplace, self.OnBtnWeaponReplaceClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCarryPartner, self.OnCarryPartnerClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessOcuupy, self.OnBtnAwarenessOcuupyClick)
    
    XUiHelper.RegisterClickEvent(self, self.BtnUnFold, self.OnBtnUnFoldClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFold, self.OnBtnFoldClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRecommend, self.OnBtnRecommendClick)

    XEventManager.AddEventListener(XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY, self.OnEquipTakeOff, self)
end

-- 展开的界面打开再注册
function XUiPanelEquipV2P6:InitUnFoldButton()
    if self.IsInitAllBtn then
        return
    end
    self.IsInitAllBtn = true
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

    XUiHelper.RegisterClickEvent(self, self.BtnAutoTakeOff, self.OnBtnAutoTakeOffClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessSuit, self.OnBtnAwarenessSuitClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAddition, self.OnPanelAdditionClick)
end

function XUiPanelEquipV2P6:OnDisable()
    if self.WeaponGrid then
        self.WeaponGrid:Close()
    end
end

function XUiPanelEquipV2P6:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY, self.OnEquipTakeOff, self)
end

function XUiPanelEquipV2P6:InitData(onFoldCb, onUnFoldCb, forbidGotoEquip)
    self.OnFoldCb = onFoldCb
    self.OnUnFoldCb = onUnFoldCb
    self.ForbidGotoEquip = forbidGotoEquip

    self.WearingAwarenessGrids = {}
    self.DoubleResonanceList = {}
    self.GridDoubleResonanceSkill.gameObject:SetActiveEx(false)
end

function XUiPanelEquipV2P6:SetForbidGotoEquip(flag)
    self.ForbidGotoEquip = flag
end

function XUiPanelEquipV2P6:UpdateCharacter(characterId)
    self.CharacterId = characterId
    self:UpdateView()
end

function XUiPanelEquipV2P6:UpdateView()
    -- 只刷新当前展开的面板
    if self.IsShowPanelAwareness then
        self:UpdateAwarenessView()
    else
        self:UpdateRoleView()
    end
end

-- 刷新角色面板
function XUiPanelEquipV2P6:UpdateRoleView()
    local characterId = self.CharacterId
    self.WeaponGrid = self.WeaponGrid or XUiGridEquip.New(self.GridWeapon, self.RootUi)
    self.WeaponGrid:Open()
    local usingWeaponId = XDataCenter.EquipManager.GetCharacterWearingWeaponId(characterId)
    self.WeaponGrid:Refresh(usingWeaponId)
    XDataCenter.EquipManager.CheckOverrunGuide(usingWeaponId)

    -- 推荐按钮
    local openRecommend = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipGuideRecommend)
    self.BtnRecommend.gameObject:SetActiveEx(openRecommend)

    -- 辅助机
    local partner = XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(characterId)
    if partner then
        self.PartnerIcon:SetRawImage(partner:GetIcon())
        self.IconPartnerQuality:SetRawImage(partner:GetCharacterQualityIcon())
        -- 暂不需要辅助机的突破图标
        -- local icon = XEquipConfig.GetEquipBreakThroughIcon(partner:GetBreakthrough())
        -- if icon then
        --     self.RootUi:SetUiSprite(self.ImgPartnerBreakthrough, icon)
        -- end
    end
    self.PanelNoPartner.gameObject:SetActiveEx(partner == nil)
    self.PartnerIcon.gameObject:SetActiveEx(partner ~= nil)
    self.IconQualityBg.gameObject:SetActiveEx(partner ~= nil)
    self.IconPartnerQuality.gameObject:SetActiveEx(partner ~= nil)

    -- BtnUnFold 上的套装简述
    self:UpdateBtnUnFoldName()
end

-- 刷新意识面板
function XUiPanelEquipV2P6:UpdateAwarenessView()
    local characterId = self.CharacterId
    local curr = 0
    local haveAwareness = false
    for _, equipSite in pairs(XEquipConfig.EquipSite.Awareness) do
        self.WearingAwarenessGrids[equipSite] = self.WearingAwarenessGrids[equipSite] or XUiGridEquip.New(CS.UnityEngine.Object.Instantiate(self.GridAwareness), self.RootUi)
        self.WearingAwarenessGrids[equipSite].Transform:SetParent(self["PanelAwareness" .. equipSite], false)

        local equipId = XDataCenter.EquipManager.GetWearingEquipIdBySite(characterId, equipSite)
        if not equipId then
            self.WearingAwarenessGrids[equipSite]:Close()
            self["PanelNoAwareness" .. equipSite].gameObject:SetActiveEx(true)
        else
            haveAwareness = true
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
    self.BtnAutoTakeOff.gameObject:SetActiveEx(haveAwareness)
    
    -- 公约加成
    self.TxtOcuupyHarm.text =  CS.XTextManager.GetText("AwarenessTotalHarm", curr)

    -- 套装数量
    self:UpdatePanelSuitCount()

    -- 共鸣技能
    self:UpdatePanelResonanceSkill()
end

function XUiPanelEquipV2P6:UpdateBtnUnFoldName()
    local suitInfoList = self.EquipAgency:GetWearingSuitInfoList(self.CharacterId)
    local maxLength = 45
    local str = ""
    if #suitInfoList > 0 then
        for _, suitInfo in pairs(suitInfoList) do
            local length = #suitInfo.Name
            if #str + length > maxLength then
                str = str .. "..."
                break
            else
                str = str .. suitInfo.Name .. "x" .. suitInfo.Count .." "
            end
        end
    else
        str = XUiHelper.GetText("UnWearAwareness")
    end
    self.BtnUnFold:SetNameByGroup(0, str)
end

-- 刷新套装数量列表
function XUiPanelEquipV2P6:UpdatePanelSuitCount()
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
function XUiPanelEquipV2P6:UpdatePanelResonanceSkill()
    for index = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local grid = self.DoubleResonanceList[index]
        if not grid then
            local go = CSInstantiate(self.GridDoubleResonanceSkill, self.PanelResonanceSkill)
            grid = XUiGridResonanceDoubleSkillV2P6.New(go, self.RootUi)
            self.DoubleResonanceList[index] = grid
            grid.GameObject:SetActive(true)
        end

        grid:RefreshBySite(self.CharacterId, index)
    end
end

function XUiPanelEquipV2P6:OnBtnWeaponReplaceClick()
    if self.ForbidGotoEquip then return end
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Equip) then
        return
    end
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipReplace(self.CharacterId)
    XMVCA.XCharacter:BuryingUiCharacterAction(self.RootUi.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnWeaponReplace, self.CharacterId)
end

function XUiPanelEquipV2P6:OnCarryPartnerClick()
    if self.ForbidGotoEquip then return end
    XDataCenter.PartnerManager.GoPartnerCarry(self.CharacterId, true)
    XMVCA.XCharacter:BuryingUiCharacterAction(self.RootUi.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnCarryPartner, self.CharacterId)
end

function XUiPanelEquipV2P6:OnBtnAwarenessOcuupyClick()
    XLuaUiManager.Open("UiAwarenessOccupyProgress", self.CharacterId)
    XMVCA.XCharacter:BuryingUiCharacterAction(self.RootUi.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnAwarenessOcuupy, self.CharacterId)
end

function XUiPanelEquipV2P6:OnAwarenessClick(site)
    if self.ForbidGotoEquip then return end
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Equip) then
        return
    end
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipAwarenessReplace(self.CharacterId, site)
    XMVCA.XCharacter:BuryingUiCharacterAction(self.RootUi.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnAwarenessReplace, self.CharacterId)
end

function XUiPanelEquipV2P6:OnBtnUnFoldClick()
    self:DoUnFold()
    XMVCA.XCharacter:BuryingUiCharacterAction(self.RootUi.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnUnFold, self.CharacterId)
end

-- 展开意识面板
function XUiPanelEquipV2P6:DoUnFold()
    if not self.GameObject.activeInHierarchy then
        return
    end

    if self.IsShowPanelAwareness then
        return
    end

    self:PlayAnimationWithMask("AnimUnFold")
    self.IsShowPanelAwareness = true
    self:InitUnFoldButton()
    self:UpdateAwarenessView()
    if self.OnUnFoldCb then
        self.OnUnFoldCb()
    end
end

function XUiPanelEquipV2P6:OnBtnFoldClick()
    self:DoFold()
    XMVCA.XCharacter:BuryingUiCharacterAction(self.RootUi.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnFold, self.CharacterId)
end

-- 展开角色面板
function XUiPanelEquipV2P6:DoFold()
    if not self.GameObject.activeInHierarchy then
        return
    end

    if not self.IsShowPanelAwareness then
        return
    end

    for _, grid in pairs(self.WearingAwarenessGrids) do
        grid:Close()
    end
    self:PlayAnimationWithMask("AnimFold")
    self.IsShowPanelAwareness = false
    self:UpdateRoleView()
    if self.OnFoldCb then
        self.OnFoldCb()
    end
end

function XUiPanelEquipV2P6:OnBtnAutoTakeOffClick()
    local wearingEquipIds = XDataCenter.EquipManager.GetCharacterWearingAwarenessIds(self.CharacterId)
    if not wearingEquipIds or not next(wearingEquipIds) then
        XUiManager.TipText("EquipAutoTakeOffNotWearingEquip")
        return
    end
    XMVCA:GetAgency(ModuleId.XEquip):TakeOff(wearingEquipIds)
    XMVCA.XCharacter:BuryingUiCharacterAction(self.RootUi.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnAutoTakeOff, self.CharacterId)
end

function XUiPanelEquipV2P6:OnBtnRecommendClick()
    XDataCenter.EquipGuideManager.OpenEquipGuideView(self.CharacterId)
    XMVCA.XCharacter:BuryingUiCharacterAction(self.RootUi.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnRecommend, self.CharacterId)
end

function XUiPanelEquipV2P6:OnBtnAwarenessSuitClick()
    XLuaUiManager.Open("UiEquipAwarenessSuitPrefab", self.CharacterId)
    XMVCA.XCharacter:BuryingUiCharacterAction(self.RootUi.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnAwarenessSuit, self.CharacterId)
end

function XUiPanelEquipV2P6:OnPanelAdditionClick()
    XLuaUiManager.Open("UiEquipSuitSkillV2P6", self.CharacterId)
    XMVCA.XCharacter:BuryingUiCharacterAction(self.RootUi.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnAddition, self.CharacterId)
end

-- 卸下/一键卸下装备事件
function XUiPanelEquipV2P6:OnEquipTakeOff()
    self:UpdateView()
end

return XUiPanelEquipV2P6
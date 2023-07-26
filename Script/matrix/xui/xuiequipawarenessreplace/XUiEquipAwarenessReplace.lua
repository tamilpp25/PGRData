local XUiPanelEquipScroll = require("XUi/XUiEquipAwarenessReplace/XUiPanelEquipScroll")
local XUiPanelSuitDetailScroll = require("XUi/XUiEquipAwarenessReplace/XUiPanelSuitDetailScroll")
local XUiPanelSuitSimpleScroll = require("XUi/XUiEquipAwarenessReplace/XUiPanelSuitSimpleScroll")
local XUiGridEquip = require("XUi/XUiEquipAwarenessReplace/XUiGridEquip")
local XUiGridDoubleResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridDoubleResonanceSkill")

local type = type
local tableInsert = table.insert
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSXTextManagerGetText = CS.XTextManager.GetText
local CSXScheduleManagerUnSchedule = XScheduleManager.UnSchedule
local CSXScheduleManagerScheduleOnce = XScheduleManager.ScheduleOnce
local MAX_SUIT_SKILL_COUNT = 4

local MAX_MERGE_ATTR_COUNT = 4
local MAX_RESONANCE_SKILL_COUNT = 6

local ViewPattern = {
    Pos = 1,
    Suit = 2,
    Resonance = 3,
    Quick = 4,
}

local GridPattern = {
    Simple = 1,
    Detail = 2,
}

local ShowPropertyIndex = {
    Attr = 1,
    SuitSkill = 2,
    ResonanceSkill = 3,
}

local ResonanceType = {
    CurCharacter = 1, --当前角色共鸣
    Others = 2, --其他角色共鸣
    None = 3, --无共鸣
}

local XUiEquipAwarenessReplace = XLuaUiManager.Register(XLuaUi, "UiEquipAwarenessReplace")

function XUiEquipAwarenessReplace:OnAwake()
    self.BtnClosePopup.gameObject:SetActive(false)
    self:AutoAddListener()
    self:InitComponentStatus()
end

function XUiEquipAwarenessReplace:OnStart(characterId, equipSite, notShowStrengthenBtn)
    equipSite = equipSite or XEquipConfig.EquipSite.Awareness.One
    self.InitSelectPos = equipSite
    self.CharacterId = characterId
    self.IsAscendOrder = false --初始降序
    self.LastViewPattern = ViewPattern.Pos
    self.GridPattern = GridPattern.Simple
    self.SelectedSuitStar = 6
    self.NotShowStrengthenBtn = notShowStrengthenBtn or false
    self.SelectShowProperty = ShowPropertyIndex.Attr
    self.SelectedResonanceType = ResonanceType.CurCharacter
    self.TempSpriteList = {}
    self.GridDoubleResonanceSkills = {}

    self.PanelTabBtns:Init({
        self.BtnPos,
        self.BtnSuit,
        self.BtnGongming,
    }, function(tabIndex) self:OnSelectViewPattern(tabIndex) end)

    self.PanelTogPos:Init({
        self.Tog1,
        self.Tog2,
        self.Tog3,
        self.Tog4,
        self.Tog5,
        self.Tog6,
    }, function(tabIndex) self:OnSelectEquipSite(tabIndex) end)

    self.PanelTogPosStar:Init({
        self.TogStar1,
        self.TogStar2,
        self.TogStar3,
        self.TogStar4,
        self.TogStar5,
        self.TogStar6,
    }, function(tabIndex) self:OnSelectSuitStar(tabIndex) end)


    local characterTradeName = XCharacterConfigs.GetCharacterTradeName(characterId)
    local btnNameStr = CSXTextManagerGetText("EquipAwarenessReplaceBtnName", characterTradeName)
    self.TogType01:SetNameByGroup(0, btnNameStr)
    self.PanelTogPosGmtype:Init({
        self.TogType01,
        self.TogType02,
        self.TogType03,
    }, function(tabIndex) self:OnSelectResonanceType(tabIndex) end)

    self.EquipBtnGroup:Init({
        self.BtnEquipProperty,
        self.BtnEquipSkill,
        self.BtnEquipResonance,
    }, function(tabIndex) self:OnSelectShowProperty(tabIndex) end)

    self:InitScrollPanel()
    self:InitCurEquipGrids()
end

function XUiEquipAwarenessReplace:OnEnable()
    self:UpdateCurEquipGrids()
    self:UpdateViewData()
    if self.LastViewPattern ~= ViewPattern.Quick then
        self.PanelTabBtns:SelectIndex(self.LastViewPattern)
    else
        self:UpdateSuitDrdOptionList()
        self:OnSelectSortType(self.DrdSort.value, true)
    end
    self.EquipBtnGroup:SelectIndex(self.SelectShowProperty)
    self:HideActiveEffect()
end

function XUiEquipAwarenessReplace:OnDestroy()
    for _, info in pairs(self.TempSpriteList) do
        CS.UnityEngine.Object.Destroy(info.Sprite)
        CS.XResourceManager.Unload(info.Resource)
    end
end

--注册监听事件
function XUiEquipAwarenessReplace:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_PUTON_NOTYFY
        , XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY
        , XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY
        , XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY
        , XEventId.EVENT_EQUIP_RECYCLE_NOTIFY
    }
end

--处理事件监听
function XUiEquipAwarenessReplace:OnNotify(evt, ...)
    local args = { ... }

    if evt == XEventId.EVENT_EQUIP_PUTON_NOTYFY then
        local equipId = args[1]
        self:UpdateViewData()
        if self.LastViewPattern == ViewPattern.Quick then
            local suitId = XDataCenter.EquipManager.GetSuitId(equipId)
            self:UpdateSuitDrdOptionList()
            self:UpdateDrdSuitValue(suitId)
        end
        self:OnSelectSortType(self.DrdSort.value)

        local equipSite = XDataCenter.EquipManager.GetEquipSite(equipId)
        self:UpdateCurEquipGrid(equipSite)
        self.EquipBtnGroup:SelectIndex(self.SelectShowProperty)
        self:PlayActiveEffect(equipId)
    elseif evt == XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY then
        local equipIds = args[1]
        self:UpdateViewData()
        for _, equipId in pairs(equipIds) do
            if self.LastViewPattern == ViewPattern.Quick then
                local suitId = XDataCenter.EquipManager.GetSuitId(equipId)
                self:UpdateSuitDrdOptionList()
                self:UpdateDrdSuitValue(suitId)
            end
            local equipSite = XDataCenter.EquipManager.GetEquipSite(equipId)
            self:UpdateCurEquipGrid(equipSite)
        end
        self:OnSelectSortType(self.DrdSort.value)
        self.EquipBtnGroup:SelectIndex(self.SelectShowProperty)
    elseif evt == XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY
    or evt == XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY then
        local equipId = args[1]
        local equipSite = XDataCenter.EquipManager.GetEquipSite(equipId)
        self:UpdateCurEquipGrid(equipSite)
        self:OnSelectSortType(self.DrdSort.value, true)
    elseif evt == XEventId.EVENT_EQUIP_RECYCLE_NOTIFY then
        self:UpdateViewData()
        self:OnSelectSortType(self.DrdSort.value, true)
    end
end

function XUiEquipAwarenessReplace:InitComponentStatus()
    self.GridSuitSimple.gameObject:SetActive(false)
    self.GridDoubleResonanceSkill.gameObject:SetActive(false)
    self.Verticallayout = self.PanelAdapter:GetComponent("VerticalLayoutGroup")
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.DrdSort.onValueChanged:AddListener(function()
        self:OnDrdSortValueChanged()
    end)
    self.DrdSuit.onValueChanged:AddListener(function()
        self:OnDrdSuitValueChanged()
    end)
end

function XUiEquipAwarenessReplace:UpdateViewData()
    local characterId = self.CharacterId
    local characterType = XCharacterConfigs.GetCharacterType(characterId)
    self.SiteToEquipIdsDic = XDataCenter.EquipManager.ConstructAwarenessSiteToEquipIdsDic(characterType)
    self.StarToSiteToSuitIdsDic = XDataCenter.EquipManager.ConstructAwarenessStarToSiteToSuitIdsDic(characterType)
    self.SuitIdToEquipIdsDic = XDataCenter.EquipManager.ConstructAwarenessSuitIdToEquipIdsDic(characterType)
    self.ResonanceTypeToEquipIdsDic = XDataCenter.EquipManager.ConstructAwarenessResonanceTypeToEquipIdsDic(characterId)
end

function XUiEquipAwarenessReplace:UpdateSuitDrdOptionList()
    self.DrdSuit:ClearOptions()
    local optionDataList = CS.UnityEngine.UI.Dropdown.OptionDataList()
    for _, suitId in pairs(self.StarToSiteToSuitIdsDic[self.SelectedSuitStar][self.SelectedEquipSite]) do
        local optionData = CS.UnityEngine.UI.Dropdown.OptionData()
        optionData.text = XDataCenter.EquipManager.GetSuitName(suitId)

        local resource = CS.XResourceManager.Load(XDataCenter.EquipManager.GetSuitIconBagPath(suitId))
        local texture = resource.Asset
        local sprite = CS.UnityEngine.Sprite.Create(texture,
        CS.UnityEngine.Rect(0, 0, texture.width, texture.height),
        CS.UnityEngine.Vector2.zero)
        optionData.image = sprite
        optionDataList.options:Add(optionData)

        local info = {
            Sprite = sprite,
            Resource = resource,
        }
        tableInsert(self.TempSpriteList, info)
    end
    self.DrdSuit:AddOptions(optionDataList.options)
end

function XUiEquipAwarenessReplace:InitScrollPanel()
    local equipTouchCb = function(equipId)
        self:OnSelectEquip(equipId)
    end

    local suitTouchCb = function(suitId)
        self:OnSelectViewPattern(ViewPattern.Quick)
        self:UpdateSuitDrdOptionList()
        self:UpdateDrdSuitValue(suitId)
    end

    local gridReloadCb = function()
        self:SetSortBtnEnabled(true)
    end

    self.EquipScroll = XUiPanelEquipScroll.New(self.PanelEquipScroll, self, equipTouchCb, gridReloadCb)
    self.SuitSimpleScroll = XUiPanelSuitSimpleScroll.New(self, self.PanelSuitSimpleScroll, suitTouchCb, gridReloadCb)
    self.SuitDetailScroll = XUiPanelSuitDetailScroll.New(self, self.PanelSuitDetailScroll, suitTouchCb, gridReloadCb)
end

function XUiEquipAwarenessReplace:InitCurEquipGrids()
    local clickCb = function(equipId)
        local equipSite = XDataCenter.EquipManager.GetEquipSite(equipId)
        self.PanelTogPos:SelectIndex(equipSite)
        self:OnSelectEquip(equipId, true)
    end

    self.CurEquipGirds = {}
    for _, equipSite in pairs(XEquipConfig.EquipSite.Awareness) do
        local item = CSUnityEngineObjectInstantiate(self.GridCurAwareness)
        self.CurEquipGirds[equipSite] = XUiGridEquip.New(item, self, clickCb, true)
        self.CurEquipGirds[equipSite]:InitRootUi(self)
        self.CurEquipGirds[equipSite].Transform:SetParent(self["PanelPos" .. equipSite], false)
    end
end

function XUiEquipAwarenessReplace:UpdateCurEquipGrids()
    for _, equipSite in pairs(XEquipConfig.EquipSite.Awareness) do
        self:UpdateCurEquipGrid(equipSite)
    end
end

function XUiEquipAwarenessReplace:UpdateCurEquipGrid(equipSite)
    local wearingEquipId = XDataCenter.EquipManager.GetWearingEquipIdBySite(self.CharacterId, equipSite)
    if not wearingEquipId then
        self.CurEquipGirds[equipSite].GameObject:SetActive(false)
        self["PanelNoEquip" .. equipSite].gameObject:SetActive(true)
    else
        self.CurEquipGirds[equipSite]:Refresh(wearingEquipId)
        self.CurEquipGirds[equipSite].GameObject:SetActive(true)
        self["PanelNoEquip" .. equipSite].gameObject:SetActive(false)
    end
end

function XUiEquipAwarenessReplace:UpdateCurEquipAttr()
    local attrMap = XDataCenter.EquipManager.GetWearingAwarenessMergeAttrMap(self.CharacterId)
    local attrCount = 0

    for _, attr in pairs(attrMap) do
        attrCount = attrCount + 1
        if attrCount > MAX_MERGE_ATTR_COUNT then
            break
        end
        self["TxtName" .. attrCount].text = attr.Name
        self["TxtAttr" .. attrCount].text = attr.Value
        self["PanelAttr" .. attrCount].gameObject:SetActive(true)
    end

    for i = attrCount + 1, MAX_MERGE_ATTR_COUNT do
        self["PanelAttr" .. i].gameObject:SetActive(false)
    end
end

function XUiEquipAwarenessReplace:UpdateCurEquipSkill()
    local skillCount = 0
    local activeSkillDesInfoList = XDataCenter.EquipManager.GetCharacterWearingSuitMergeActiveSkillDesInfoList(self.CharacterId)

    for i = 1, MAX_SUIT_SKILL_COUNT do
        if not activeSkillDesInfoList[i] then
            self["TxtSkillDes" .. i].gameObject:SetActive(false)
        else
            self["TxtPos" .. i].text = activeSkillDesInfoList[i].PosDes
            self["TxtSkillDes" .. i].text = activeSkillDesInfoList[i].SkillDes
            self["TxtSkillDes" .. i].gameObject:SetActive(true)
            skillCount = skillCount + 1
        end
    end

    if skillCount == 0 then
        self.PanelNoSkill.gameObject:SetActive(true)
    else
        self.PanelNoSkill.gameObject:SetActive(false)
    end

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self["TxtSkillDes1"].transform.parent)
end

function XUiEquipAwarenessReplace:UpdateCurEquipResonanceSkill()
    for index = 1, MAX_RESONANCE_SKILL_COUNT do
        local grid = self.GridDoubleResonanceSkills[index]
        if not grid then
            local go = CSUnityEngineObjectInstantiate(self.GridDoubleResonanceSkill, self.PanelResonanceSkill)
            local clickCb = function(grid)
                if self.LastSelectResonanceGrid then
                    self.LastSelectResonanceGrid:SetSelect(false)
                end
                self.LastSelectResonanceGrid = grid
                grid:SetSelect(true)
            end
            grid = XUiGridDoubleResonanceSkill.New(go, clickCb)
            self.GridDoubleResonanceSkills[index] = grid
            grid.GameObject:SetActive(true)
        end

        grid:Refresh(self.CharacterId, index)
    end
end

function XUiEquipAwarenessReplace:OnSelectSortType(sortType, doNotResetSelect)
    for key, list in pairs(self.SiteToEquipIdsDic) do
        XDataCenter.EquipManager.SortEquipIdListByPriorType(list, sortType)
        if self.IsAscendOrder then
            XTool.ReverseList(list)
        end
    end

    for _, lists in pairs(self.SuitIdToEquipIdsDic) do
        for key, list in pairs(lists) do
            XDataCenter.EquipManager.SortEquipIdListByPriorType(list, sortType)
            if self.IsAscendOrder then
                XTool.ReverseList(list)
            end
        end
    end

    for key, list in pairs(self.ResonanceTypeToEquipIdsDic) do
        XDataCenter.EquipManager.SortEquipIdListByPriorType(list, sortType)
        if self.IsAscendOrder then
            XTool.ReverseList(list)
        end
    end

    self.ImgAscend.gameObject:SetActive(self.IsAscendOrder)
    self.ImgDescend.gameObject:SetActive(not self.IsAscendOrder)

    self:UpdateScroll(doNotResetSelect)
end

--防手快一直点
function XUiEquipAwarenessReplace:SetSortBtnEnabled(enabled)
    self.BtnOrder.enabled = enabled
    self.BtnToDetail.enabled = enabled
    self.BtnToSimple.enabled = enabled
end

function XUiEquipAwarenessReplace:OnSelectViewPattern(viewPattern)
    self.LastViewPattern = viewPattern

    if viewPattern == ViewPattern.Pos then
        self.PanelEquipScroll.gameObject:SetActive(true)
        self:PlayAnimation("LeftEnableOne")
        self.PanelSuitSimpleScroll.gameObject:SetActive(false)
        self.PanelSuitDetailScroll.gameObject:SetActive(false)
        self.PanelSuitDropDown.gameObject:SetActive(false)
        self.PanelTabBtns.gameObject:SetActive(true)
        self.PanelTogPosStar.gameObject:SetActive(false)
        self.PanelTogPosGmtype.gameObject:SetActive(false)
        self.DrdSort.gameObject:SetActive(true)
        self.BtnOrder.gameObject:SetActive(true)
        self.BtnToSimple.gameObject:SetActive(false)
        self.BtnToDetail.gameObject:SetActive(false)
        self.PanelTogPos.CanDisSelect = false
        self.PanelTogPos.gameObject:SetActive(true)
        if type(self.SelectedEquipSite) == "number" then
            self.PanelTogPos:SelectIndex(self.SelectedEquipSite)
        else
            self.PanelTogPos:SelectIndex(self.InitSelectPos)
            self.InitSelectPos = XEquipConfig.EquipSite.Awareness.One   --初始位置修改只打开时生效一次
        end
    elseif viewPattern == ViewPattern.Suit then
        self.PanelEquipScroll.gameObject:SetActive(false)
        self.PanelSuitDropDown.gameObject:SetActive(false)
        self.PanelTabBtns.gameObject:SetActive(true)
        self.PanelTogPos.gameObject:SetActive(false)
        self.DrdSort.gameObject:SetActive(false)
        self.BtnOrder.gameObject:SetActive(false)
        self.PanelTogPosStar.gameObject:SetActive(true)
        self.PanelTogPosGmtype.gameObject:SetActive(false)
        self.PanelTogPos.CanDisSelect = true
        if type(self.SelectedEquipSite) == "number" then
            self.PanelTogPos:SelectIndex(self.SelectedEquipSite)    --重置位置选择
        end
        self:OnSelectGridPattern(self.GridPattern)
    elseif viewPattern == ViewPattern.Resonance then
        self.PanelEquipScroll.gameObject:SetActive(true)
        self:PlayAnimation("LeftEnableOne")
        self.PanelSuitSimpleScroll.gameObject:SetActive(false)
        self.PanelSuitDetailScroll.gameObject:SetActive(false)
        self.PanelSuitDropDown.gameObject:SetActive(false)
        self.PanelTabBtns.gameObject:SetActive(true)
        self.PanelTogPosStar.gameObject:SetActive(false)
        self.DrdSort.gameObject:SetActive(true)
        self.BtnOrder.gameObject:SetActive(true)
        self.BtnToSimple.gameObject:SetActive(false)
        self.BtnToDetail.gameObject:SetActive(false)
        self.PanelTogPos.CanDisSelect = false
        self.PanelTogPos.gameObject:SetActive(false)
        self.PanelTogPosGmtype.gameObject:SetActive(true)
        self.PanelTogPosGmtype:SelectIndex(self.SelectedResonanceType)
    elseif viewPattern == ViewPattern.Quick then
        self.PanelEquipScroll.gameObject:SetActive(true)
        self:PlayAnimation("LeftEnableOne")
        self.PanelSuitSimpleScroll.gameObject:SetActive(false)
        self.PanelSuitDetailScroll.gameObject:SetActive(false)
        self.PanelSuitDropDown.gameObject:SetActive(true)
        self.PanelTabBtns.gameObject:SetActive(false)
        self.PanelTogPosStar.gameObject:SetActive(false)
        self.DrdSort.gameObject:SetActive(true)
        self.BtnOrder.gameObject:SetActive(true)
        self.BtnToSimple.gameObject:SetActive(false)
        self.BtnToDetail.gameObject:SetActive(false)
        self.PanelTogPos.CanDisSelect = true
        self.PanelTogPos.gameObject:SetActive(true)
    end
end

function XUiEquipAwarenessReplace:OnSelectEquipSite(equipSite)
    equipSite = self.PanelTogPos.CanDisSelect and equipSite == self.SelectedEquipSite and "Total" or equipSite
    self.SelectedEquipSite = equipSite

    if self.LastSelectPos then
        local go = self["ImgSelect" .. self.LastSelectPos]
        if go then
            go.gameObject:SetActive(false)
        end
    end
    self.LastSelectPos = equipSite
    if self.LastSelectPos then
        local go = self["ImgSelect" .. self.LastSelectPos]
        if go then
            go.gameObject:SetActive(true)
        end
    end

    if self.LastSelectCurGrid then
        self.LastSelectCurGrid:SetSelected(false)
    end
    self.LastSelectCurGrid = self.CurEquipGirds[equipSite]
    if self.LastSelectCurGrid then
        self.LastSelectCurGrid:SetSelected(true)
    end

    if self.LastViewPattern == ViewPattern.Quick then
        self:UpdateSuitDrdOptionList()
        self:UpdateDrdSuitValue(self.QuickLastSelectSuitId)
    end

    self:OnSelectSortType(self.DrdSort.value)
    self:PlayAnimation("EquipScrollQieHuan")
end

function XUiEquipAwarenessReplace:OnSelectGridPattern(gridPattern)
    self.GridPattern = gridPattern

    if gridPattern == GridPattern.Simple then
        self.PanelSuitSimpleScroll.gameObject:SetActive(true)
        self:PlayAnimation("SuitSimpleScrollQieHuan")
        self.PanelSuitDetailScroll.gameObject:SetActive(false)
        self.BtnToSimple.gameObject:SetActive(false)
        self.BtnToDetail.gameObject:SetActive(true)
    elseif gridPattern == GridPattern.Detail then
        self.PanelSuitSimpleScroll.gameObject:SetActive(false)
        self.PanelSuitDetailScroll.gameObject:SetActive(true)
        self:PlayAnimation("SuitDetailScrollQieHuan")
        self.BtnToSimple.gameObject:SetActive(true)
        self.BtnToDetail.gameObject:SetActive(false)
    end

    self:PlayAnimation("LeftEnableTwo")
    self.PanelTogPosStar:SelectIndex(self.SelectedSuitStar)
end

function XUiEquipAwarenessReplace:OnSelectSuitStar(star)
    self.SelectedSuitStar = star
    self:OnSelectSortType(self.DrdSort.value)
    self:PlayAnimation("EquipScrollQieHuan")
end

function XUiEquipAwarenessReplace:OnSelectResonanceType(index)
    self.SelectedResonanceType = index
    self:OnSelectSortType(self.DrdSort.value)
    self:PlayAnimation("EquipScrollQieHuan")
end

function XUiEquipAwarenessReplace:OnSelectShowProperty(selectShowProperty)
    self.SelectShowProperty = selectShowProperty

    if selectShowProperty == ShowPropertyIndex.Attr then
        self:UpdateCurEquipAttr()
        self.PanelAttrParent.gameObject:SetActive(true)
        self.PanelSuitSkill.gameObject:SetActive(false)
        self.PanelResonanceSkill.gameObject:SetActive(false)
    elseif selectShowProperty == ShowPropertyIndex.SuitSkill then
        self:UpdateCurEquipSkill()
        self.PanelAttrParent.gameObject:SetActive(false)
        self.PanelSuitSkill.gameObject:SetActive(true)
        self.PanelResonanceSkill.gameObject:SetActive(false)
    elseif selectShowProperty == ShowPropertyIndex.ResonanceSkill then
        self:UpdateCurEquipResonanceSkill()
        self.PanelAttrParent.gameObject:SetActive(false)
        self.PanelSuitSkill.gameObject:SetActive(false)
        self.PanelResonanceSkill.gameObject:SetActive(true)
    end
    if XLuaUiManager.IsUiShow("UiEquipAwarenessPopup") then
        XLuaUiManager.Close("UiEquipAwarenessPopup")
    end
end

function XUiEquipAwarenessReplace:OnSelectDrdSuit(suitId)
    if not suitId then
        return
    end
    self.SelectedSuitId = suitId

    self.PanelTogPosStar:SelectIndex(XDataCenter.EquipManager.GetSuitStar(suitId))
end

function XUiEquipAwarenessReplace:UpdateDrdSuitValue(suitId)
    local findSuitInDrd = false
    for k, v in pairs(self.StarToSiteToSuitIdsDic[self.SelectedSuitStar][self.SelectedEquipSite]) do
        if v == suitId then
            self.DrdSuit.value = k - 1
            findSuitInDrd = true
            break
        end
    end

    -- 如果当前位置没有对应套装ID，那么也调用调度函数刷到下个套装显示
    if not findSuitInDrd then
        if self.DrdSuit.value == 0 then
            self:OnDrdSuitValueChanged()
        else
            self.DrdSuit.value = 0
        end
    else
        self:OnDrdSuitValueChanged()
    end
end

function XUiEquipAwarenessReplace:UpdateScroll(doNotResetSelect)
    if not self.LastViewPattern then
        return
    end

    local scroll, idList
    if self.LastViewPattern == ViewPattern.Suit then
        if not self.GridPattern then return end

        idList = self.StarToSiteToSuitIdsDic[self.SelectedSuitStar]
        and self.StarToSiteToSuitIdsDic[self.SelectedSuitStar][self.SelectedEquipSite] or {}

        if self.GridPattern == GridPattern.Simple then
            scroll = self.SuitSimpleScroll
            self.PanelNoSuitSimple.gameObject:SetActive(not next(idList))
        elseif self.GridPattern == GridPattern.Detail then
            scroll = self.SuitDetailScroll
            self.PanelNoSuitDetail.gameObject:SetActive(not next(idList))
        end
    elseif self.LastViewPattern == ViewPattern.Pos then
        scroll = self.EquipScroll
        idList = self.SiteToEquipIdsDic[self.SelectedEquipSite] or {}
        self.PanelNoEquip.gameObject:SetActive(not next(idList))
    elseif self.LastViewPattern == ViewPattern.Resonance then
        scroll = self.EquipScroll
        idList = self.ResonanceTypeToEquipIdsDic[self.SelectedResonanceType] or {}
        self.PanelNoEquip.gameObject:SetActive(not next(idList))
    elseif self.LastViewPattern == ViewPattern.Quick then
        scroll = self.EquipScroll
        idList = self.SuitIdToEquipIdsDic[self.SelectedSuitId]
        and self.SuitIdToEquipIdsDic[self.SelectedSuitId][self.SelectedEquipSite] or {}
        self.PanelNoEquip.gameObject:SetActive(not next(idList))
    end

    if scroll then
        self:SetSortBtnEnabled(false)
        if XLuaUiManager.IsUiShow("UiEquipAwarenessPopup") then
            XLuaUiManager.Close("UiEquipAwarenessPopup")
        end

        --NEVER DELETE ME!
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelAdapter)
        if self.TimerId then
            CSXScheduleManagerUnSchedule(self.TimerId)
            self.TimerId = nil
        end
        self.TimerId = CSXScheduleManagerScheduleOnce(function()
            if XTool.UObjIsNil(scroll.GameObject) then return end
            scroll:UpdateEquipGridList(idList, doNotResetSelect, self.SelectedEquipSite)
        end, 0)
    end
end

function XUiEquipAwarenessReplace:OnSelectEquip(equipId, needFixPopUpPos)
    self.SelectEquipId = equipId
    self.NeedFixPopUpPos = needFixPopUpPos
    self:OpenChildUi()
end

function XUiEquipAwarenessReplace:PlayActiveEffect(equipId)
    local suitId = XDataCenter.EquipManager.GetSuitId(equipId)
    local count, siteCheckDic = XDataCenter.EquipManager.GetActiveSuitEquipsCount(self.CharacterId, suitId)

    if count == 2 or count == 4 or count == 6 then
        for _, site in pairs(XEquipConfig.EquipSite.Awareness) do
            if siteCheckDic[site] then
                self["PanelEffect" .. site].gameObject:SetActive(false)
                self["PanelEffect" .. site].gameObject:SetActive(true)
            end
        end
    end
end

function XUiEquipAwarenessReplace:HideActiveEffect()
    for _, site in pairs(XEquipConfig.EquipSite.Awareness) do
        self["PanelEffect" .. site].gameObject:SetActive(false)
    end
end

function XUiEquipAwarenessReplace:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainClick)
    self:RegisterClickEvent(self.BtnOrder, self.OnBtnOrderClick)
    self:RegisterClickEvent(self.BtnToDetail, self.OnBtnToDetailClick)
    self:RegisterClickEvent(self.BtnToSimple, self.OnBtnToSimpleClick)
    self:RegisterClickEvent(self.BtnClosePopup, self.OnBtnClosePopupClick)
    self:RegisterClickEvent(self.BtnPos1, self.OnBtnPos1Click)
    self:RegisterClickEvent(self.BtnPos2, self.OnBtnPos2Click)
    self:RegisterClickEvent(self.BtnPos3, self.OnBtnPos3Click)
    self:RegisterClickEvent(self.BtnPos4, self.OnBtnPos4Click)
    self:RegisterClickEvent(self.BtnPos5, self.OnBtnPos5Click)
    self:RegisterClickEvent(self.BtnPos6, self.OnBtnPos6Click)
    self:RegisterClickEvent(self.BtnAutoTakeOff, self.OnBtnAutoTakeOffClick)
    self:RegisterClickEvent(self.BtnAwarenessSuitPrefab, self.OnBtnAwarenessSuitPrefabClick)
    self:RegisterClickEvent(self.PanelEquipScroll, self.OnPanelEquipScrollClick)
end

function XUiEquipAwarenessReplace:OpenChildUi()
    if XLuaUiManager.IsUiShow("UiEquipAwarenessPopup") then
        XLuaUiManager.Close("UiEquipAwarenessPopup")
    end
    XLuaUiManager.Open("UiEquipAwarenessPopup", self, self.NotShowStrengthenBtn)
end

function XUiEquipAwarenessReplace:OnPanelEquipScrollClick()
    if XLuaUiManager.IsUiShow("UiEquipAwarenessPopup") then
        XLuaUiManager.Close("UiEquipAwarenessPopup")
    end
end

function XUiEquipAwarenessReplace:OnBtnClosePopupClick()
    self.EquipScroll:ResetSelectGrid()
    if XLuaUiManager.IsUiShow("UiEquipAwarenessPopup") then
        XLuaUiManager.Close("UiEquipAwarenessPopup")
    end
end

function XUiEquipAwarenessReplace:OnBtnPos1Click()
    self.PanelTogPos:SelectIndex(XEquipConfig.EquipSite.Awareness.One)
end

function XUiEquipAwarenessReplace:OnBtnPos2Click()
    self.PanelTogPos:SelectIndex(XEquipConfig.EquipSite.Awareness.Two)
end

function XUiEquipAwarenessReplace:OnBtnPos3Click()
    self.PanelTogPos:SelectIndex(XEquipConfig.EquipSite.Awareness.Three)
end

function XUiEquipAwarenessReplace:OnBtnPos4Click()
    self.PanelTogPos:SelectIndex(XEquipConfig.EquipSite.Awareness.Four)
end

function XUiEquipAwarenessReplace:OnBtnPos5Click()
    self.PanelTogPos:SelectIndex(XEquipConfig.EquipSite.Awareness.Five)
end

function XUiEquipAwarenessReplace:OnBtnPos6Click()
    self.PanelTogPos:SelectIndex(XEquipConfig.EquipSite.Awareness.Six)
end

function XUiEquipAwarenessReplace:OnBtnBackClick()
    if XLuaUiManager.IsUiShow("UiEquipAwarenessPopup") then
        XLuaUiManager.Close("UiEquipAwarenessPopup")
    end
    if self.LastViewPattern == ViewPattern.Quick then
        self.PanelTabBtns:SelectIndex(ViewPattern.Suit)
    else
        self:Close()
    end
end

function XUiEquipAwarenessReplace:OnBtnMainClick()
    XLuaUiManager.RunMain()
end

function XUiEquipAwarenessReplace:OnDrdSortValueChanged()
    self:OnSelectSortType(self.DrdSort.value)
end

function XUiEquipAwarenessReplace:OnDrdSuitValueChanged()
    local suitId = self.StarToSiteToSuitIdsDic[self.SelectedSuitStar][self.SelectedEquipSite][self.DrdSuit.value + 1]
    self.QuickLastSelectSuitId = suitId
    self:OnSelectDrdSuit(suitId)
end

function XUiEquipAwarenessReplace:OnBtnOrderClick()
    self.IsAscendOrder = not self.IsAscendOrder
    self.ImgAscend.gameObject:SetActive(self.IsAscendOrder)
    self.ImgDescend.gameObject:SetActive(not self.IsAscendOrder)

    for key, list in pairs(self.SiteToEquipIdsDic) do
        XTool.ReverseList(list)
    end

    for _, lists in pairs(self.SuitIdToEquipIdsDic) do
        for key, list in pairs(lists) do
            XTool.ReverseList(list)
        end
    end

    for key, list in pairs(self.ResonanceTypeToEquipIdsDic) do
        XTool.ReverseList(list)
    end

    self:UpdateScroll()
end

function XUiEquipAwarenessReplace:OnBtnToDetailClick()
    self:OnSelectGridPattern(GridPattern.Detail)
end

function XUiEquipAwarenessReplace:OnBtnToSimpleClick()
    self:OnSelectGridPattern(GridPattern.Simple)
end

function XUiEquipAwarenessReplace:OnBtnAutoTakeOffClick()
    local wearingEquipIds = XDataCenter.EquipManager.GetCharacterWearingAwarenessIds(self.CharacterId)
    if not wearingEquipIds or not next(wearingEquipIds) then
        XUiManager.TipText("EquipAutoTakeOffNotWearingEquip")
        return
    end
    XMVCA:GetAgency(ModuleId.XEquip):TakeOff(wearingEquipIds)
end

function XUiEquipAwarenessReplace:OnBtnAwarenessSuitPrefabClick()
    XLuaUiManager.Open("UiEquipAwarenessSuitPrefab", self.CharacterId)
end
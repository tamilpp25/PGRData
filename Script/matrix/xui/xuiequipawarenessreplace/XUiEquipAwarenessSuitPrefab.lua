local XUiGridSuitPrefab = require("XUi/XUiEquipAwarenessReplace/XUiGridSuitPrefab")
local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")
local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")
local XUiGridDoubleResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridDoubleResonanceSkill")

local tableInsert = table.insert
local tableSort = table.sort
local CSXTextManagerGetText = CS.XTextManager.GetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local CUR_SUIT_PREFAB_INDEX = 0
local MAX_MERGE_ATTR_COUNT = 4
local MAX_RESONANCE_SKILL_COUNT = 6
local MAX_SUIT_SKILL_COUNT = 4
local ShowPropertyIndex = {
    Attr = 1,
    SuitSkill = 2,
    ResonanceSkill = 3,
}
local TAB_TYPE = {
    ALL = 1, --通用
    ONE = 2, --专属
} 

local XUiEquipAwarenessSuitPrefab = XLuaUiManager.Register(XLuaUi, "UiEquipAwarenessSuitPrefab")

function XUiEquipAwarenessSuitPrefab:OnAwake()
    self:AutoAddListener()
    self.GridSuitPrefab.gameObject:SetActiveEx(false)
end

function XUiEquipAwarenessSuitPrefab:OnStart(characterId)
    self.CharacterId = characterId
    self.CurPrefabIndex = CUR_SUIT_PREFAB_INDEX
    self.SelectShowProperty = ShowPropertyIndex.Attr
    self.GridDoubleResonanceSkills = {}
    self.GridDoubleResonanceSkill.gameObject:SetActiveEx(false)

    self:InitDynamicTable()
    self:InitCurEquipGrids()
    self:InitPropertyBtnGroup()
    self:InitTabGroup()
end

function XUiEquipAwarenessSuitPrefab:OnEnable()
    -- 获取是否有专属意识组合数据
    local oneSuitPrefabIndexs = self:GetSuitPrefabIndexList(TAB_TYPE.ONE)
    -- 如果已经有专属意识组合,直接切换专属
    if #oneSuitPrefabIndexs > 1 then
        self.TabGroup:SelectIndex(TAB_TYPE.ONE)
    -- 默认切换通用
    else
        self.TabGroup:SelectIndex(TAB_TYPE.ALL)
    end
end

function XUiEquipAwarenessSuitPrefab:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_SUIT_PREFAB_DATA_UPDATE_NOTIFY
        , XEventId.EVENT_EQUIP_DATA_LIST_UPDATE_NOTYFY
        , XEventId.EVENT_EQUIP_PUTON_NOTYFY
        , XEventId.EVENT_EQUIP_TAKEOFF_NOTYFY
        , XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY
    }
end

function XUiEquipAwarenessSuitPrefab:OnNotify(evt)
    if evt == XEventId.EVENT_EQUIP_SUIT_PREFAB_DATA_UPDATE_NOTIFY
    or evt == XEventId.EVENT_EQUIP_DATA_LIST_UPDATE_NOTYFY
    or evt == XEventId.EVENT_EQUIP_PUTON_NOTYFY
    or evt == XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY
    or evt == XEventId.EVENT_EQUIP_TAKEOFF_NOTYFY then
        self:Refresh(nil, true)
    end
end

--@region 点击事件

function XUiEquipAwarenessSuitPrefab:AutoAddListener()
    self.BtnTanchuangClose.CallBack = function() self:OnBtnTanchuangClose() end
    self.BtnClosePopup.CallBack = function() self:ClosePopup() end
    self.BtnSetName.CallBack = function() self:OnBtnSetName() end
    self.BtnSave.CallBack = function() self:OnBtnSave() end
    self.BtnEquip.CallBack = function() self:OnBtnEquip() end
    self.BtnChangeName.CallBack = function() self:OnBtnChangeName() end
    self.BtnDelete.CallBack = function() self:OnBtnDelete() end
    self:RegisterClickEvent(self.BtnPos1, function() self:OnSelectEquipSite(XEquipConfig.EquipSite.Awareness.One) end)
    self:RegisterClickEvent(self.BtnPos2, function() self:OnSelectEquipSite(XEquipConfig.EquipSite.Awareness.Two) end)
    self:RegisterClickEvent(self.BtnPos3, function() self:OnSelectEquipSite(XEquipConfig.EquipSite.Awareness.Three) end)
    self:RegisterClickEvent(self.BtnPos4, function() self:OnSelectEquipSite(XEquipConfig.EquipSite.Awareness.Four) end)
    self:RegisterClickEvent(self.BtnPos5, function() self:OnSelectEquipSite(XEquipConfig.EquipSite.Awareness.Five) end)
    self:RegisterClickEvent(self.BtnPos6, function() self:OnSelectEquipSite(XEquipConfig.EquipSite.Awareness.Six) end)
    self:RegisterClickEvent(self.PanelDynamicTable, self.OnPanelDynamicTable)
end

function XUiEquipAwarenessSuitPrefab:OnSelectType(index)
    if self.TabType ~= index then
        self.TabType = index
        self.CurPrefabIndex = CUR_SUIT_PREFAB_INDEX

        self:Refresh()
        self:PlayAnimation("QieHuan")
    end
end

function XUiEquipAwarenessSuitPrefab:OnBtnTanchuangClose()
    self:ClosePopup()
    self:Close()
end

function XUiEquipAwarenessSuitPrefab:OnPanelDynamicTable()
    self:ClosePopup()
end

function XUiEquipAwarenessSuitPrefab:OnBtnSetName()
    self:ClosePopup()
    XLuaUiManager.Open("UiEquipSuitPrefabRename", function(newName)
        self.UnSavedPrefabInfo:SetName(newName)
        self:Refresh(true)
    end)
end

function XUiEquipAwarenessSuitPrefab:OnBtnSave()
    local num = #self.SuitPrefabInfoList-1
    local maxNum

    if self.TabType == TAB_TYPE.ALL then
        maxNum = XDataCenter.EquipManager.GetSuitPrefabNumMax()
    elseif self.TabType == TAB_TYPE.ONE then
        maxNum = XDataCenter.EquipManager.GetEquipSuitCharacterPrefabMaxNum()
    end

    if num >= maxNum then
        XUiManager.TipText("EquipSuitPrefabSaveOverMaxNum")
        return
    end

    if self.TabType == TAB_TYPE.ALL then
        XDataCenter.EquipManager.EquipSuitPrefabSave(self.UnSavedPrefabInfo, 0)
    elseif self.TabType == TAB_TYPE.ONE then
        XDataCenter.EquipManager.EquipSuitPrefabSave(self.UnSavedPrefabInfo, self.CharacterId)
    end

    self:ClosePopup()
end

function XUiEquipAwarenessSuitPrefab:OnBtnEquip()
    self:ClosePopup()

    local characterType = XMVCA.XCharacter:GetCharacterType(self.CharacterId)
    local conflictInfoList = {}
    local suitPrefabInfo = self:GetShowingPrefabInfo()
    local equipIds = suitPrefabInfo:GetEquipIds()
    for _, equipId in pairs(equipIds) do
        if not XDataCenter.EquipManager.IsCharacterTypeFit(equipId, characterType) then
            XUiManager.TipText("EquipAwarenessSuitPrefabCharacterTypeWrong")
            return
        end

        local characterId = XDataCenter.EquipManager.GetEquipWearingCharacterId(equipId)
        if characterId and characterId ~= self.CharacterId then
            local conflictInfo = {
                EquipId = equipId,
                CharacterId = characterId,
            }
            tableInsert(conflictInfoList, conflictInfo)
        end
    end
    tableSort(conflictInfoList, function(a, b)
        return XDataCenter.EquipManager.GetEquipSite(a.EquipId) < XDataCenter.EquipManager.GetEquipSite(b.EquipId)
    end)

    local equipFunc = function()
        XMVCA:GetAgency(ModuleId.XEquip):EquipSuitPrefabEquip(self.CurPrefabIndex, self.CharacterId, function()
            self.CurPrefabIndex = CUR_SUIT_PREFAB_INDEX
        end)
    end

    if not next(conflictInfoList) then
        equipFunc()
    else
        XLuaUiManager.Open("UiEquipSuitPrefabConflict", conflictInfoList, equipFunc)
    end
end

function XUiEquipAwarenessSuitPrefab:OnBtnChangeName()
    self:ClosePopup()
    XLuaUiManager.Open("UiEquipSuitPrefabRename", function(newName)
        XDataCenter.EquipManager.EquipSuitPrefabRename(self.CurPrefabIndex, newName)
    end)
end

function XUiEquipAwarenessSuitPrefab:OnBtnDelete()
    self:ClosePopup()

    local suitPrefabInfo = self:GetShowingPrefabInfo()
    local content = suitPrefabInfo:GetName()
    XLuaUiManager.Open("UiEquipSuitPrefabConfirm", content, function()
        local prefabIndex = self.CurPrefabIndex
        self.CurPrefabIndex = CUR_SUIT_PREFAB_INDEX
        XDataCenter.EquipManager.EquipSuitPrefabDelete(prefabIndex)
    end)
end

--@endregion

--@region 初始化函数
function XUiEquipAwarenessSuitPrefab:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGridSuitPrefab)
    self.DynamicTable:SetDelegate(self)
end

function XUiEquipAwarenessSuitPrefab:InitCurEquipGrids()
    local clickCb = function(equipId)
        self:OnSelectEquip(equipId)
    end

    self.CurEquipGirds = {}
    self.GridCurAwareness.gameObject:SetActiveEx(false)
    for _, equipSite in pairs(XEquipConfig.EquipSite.Awareness) do
        local item = CS.UnityEngine.Object.Instantiate(self.GridCurAwareness)
        self.CurEquipGirds[equipSite] = XUiGridEquip.New(item, self, clickCb)
        self.CurEquipGirds[equipSite].Transform:SetParent(self["PanelPos" .. equipSite], false)
    end
end

function XUiEquipAwarenessSuitPrefab:InitTabGroup()
    local tabBtns = { self.BtnTabAll, self.BtnTabOne }

    self.TabGroup:Init(tabBtns, function(index) self:OnSelectType(index) end)
    self.RImgRole:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(self.CharacterId))
end

function XUiEquipAwarenessSuitPrefab:InitPropertyBtnGroup()
    self.EquipBtnGroup:Init({
        self.BtnEquipProperty,
        self.BtnEquipSkill,
        self.BtnEquipResonance,
    }, function(tabIndex) self:OnSelectShowProperty(tabIndex) end)
end

function XUiEquipAwarenessSuitPrefab:OnSelectShowProperty(selectShowProperty)
    self.SelectShowProperty = selectShowProperty

    if selectShowProperty == ShowPropertyIndex.Attr then
        self:UpdateCurEquipAttr()
        self.PanelAttrParent.gameObject:SetActiveEx(true)
        self.PanelSuitSkill.gameObject:SetActiveEx(false)
        self.PanelResonanceSkill.gameObject:SetActiveEx(false)
    elseif selectShowProperty == ShowPropertyIndex.SuitSkill then
        self:UpdateCurEquipSkill()
        self.PanelAttrParent.gameObject:SetActiveEx(false)
        self.PanelSuitSkill.gameObject:SetActiveEx(true)
        self.PanelResonanceSkill.gameObject:SetActiveEx(false)
    elseif selectShowProperty == ShowPropertyIndex.ResonanceSkill then
        self:UpdateCurEquipResonanceSkill()
        self.PanelAttrParent.gameObject:SetActiveEx(false)
        self.PanelSuitSkill.gameObject:SetActiveEx(false)
        self.PanelResonanceSkill.gameObject:SetActiveEx(true)
    end

    self:ClosePopup()
end
--@endregion

function XUiEquipAwarenessSuitPrefab:Refresh(doNotResetUnsaved, resetScroll)
    local characterId = self.CharacterId
    self.UnSavedPrefabInfo = not doNotResetUnsaved and XDataCenter.EquipManager.GetUnSavedSuitPrefabInfo(characterId) or self.UnSavedPrefabInfo
    self.SuitPrefabInfoList = self:GetSuitPrefabIndexList()

    self:UpdateDynamicTable(resetScroll)
    self:UpdateCurEquipGrids(self.CurPrefabIndex)
end

function XUiEquipAwarenessSuitPrefab:UpdateCurEquipAttr()
    local suitPrefabInfo = self:GetShowingPrefabInfo()
    local attrMap = XDataCenter.EquipManager.GetAwarenessMergeAttrMap(suitPrefabInfo:GetEquipIds())
    local attrCount = 0

    for _, attr in pairs(attrMap) do
        attrCount = attrCount + 1
        if attrCount > MAX_MERGE_ATTR_COUNT then
            break
        end
        self["TxtName" .. attrCount].text = attr.Name
        self["TxtAttr" .. attrCount].text = attr.Value
        self["PanelAttr" .. attrCount].gameObject:SetActiveEx(true)
    end

    for i = attrCount + 1, MAX_MERGE_ATTR_COUNT do
        self["PanelAttr" .. i].gameObject:SetActiveEx(false)
    end
end

function XUiEquipAwarenessSuitPrefab:UpdateCurEquipSkill()
    local suitPrefabInfo = self:GetShowingPrefabInfo()
    local activeSkillDesInfoList = XDataCenter.EquipManager.GetSuitMergeActiveSkillDesInfoList(suitPrefabInfo:GetEquipIds(), self.CharacterId)
    local skillCount = 0

    for i = 1, MAX_SUIT_SKILL_COUNT do
        if not activeSkillDesInfoList[i] then
            self["TxtSkillDes" .. i].gameObject:SetActiveEx(false)
        else
            self["TxtPos" .. i].text = activeSkillDesInfoList[i].PosDes
            self["TxtSkillDes" .. i].text = activeSkillDesInfoList[i].SkillDes
            self["TxtSkillDes" .. i].gameObject:SetActiveEx(true)
            skillCount = skillCount + 1
        end
    end

    if skillCount == 0 then
        self.PanelNoSkill.gameObject:SetActiveEx(true)
    else
        self.PanelNoSkill.gameObject:SetActiveEx(false)
    end

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self["TxtSkillDes1"].transform.parent)
end

function XUiEquipAwarenessSuitPrefab:UpdateCurEquipResonanceSkill()
    local skillCount = 0
    
     for equipSite = 1, MAX_RESONANCE_SKILL_COUNT do
        local suitPrefabInfo = self:GetShowingPrefabInfo()
        local equipId = suitPrefabInfo:GetEquipId(equipSite)

        local grid = self.GridDoubleResonanceSkills[equipSite]
        if not grid then
            local go = CSUnityEngineObjectInstantiate(self.GridDoubleResonanceSkill, self.PanelResonanceSkillParent)
            grid = XUiGridDoubleResonanceSkill.New(go)
            self.GridDoubleResonanceSkills[equipSite] = grid
            grid.GameObject:SetActiveEx(true)
        end

        if not equipId or equipId == 0 then
            grid:RefreshByEquipId(nil, nil, equipSite)
        else
            grid:RefreshByEquipId(self.CharacterId, equipId, equipSite)
            skillCount = skillCount + 1
        end
    end

    local noResonanceSkill = skillCount == 0
    self.PanelResonanceSkillParent.gameObject:SetActiveEx(not noResonanceSkill)
    self.PanelNoResonanceSkill.gameObject:SetActiveEx(noResonanceSkill)
end

function XUiEquipAwarenessSuitPrefab:UpdateSavePanel()
    local isPreafabSaved = self.CurPrefabIndex ~= CUR_SUIT_PREFAB_INDEX
    self.PanelSavedPrefab.gameObject:SetActiveEx(isPreafabSaved)
    self.PanelUnSavedPrefab.gameObject:SetActiveEx(not isPreafabSaved)

    if not isPreafabSaved then
        local suitPrefabInfo = self:GetShowingPrefabInfo()
        self.BtnSetName:SetName(suitPrefabInfo:GetName())
    end
end

function XUiEquipAwarenessSuitPrefab:UpdateDynamicTable(resetScroll)
    local num = #self.SuitPrefabInfoList-1
    if self.TabType == TAB_TYPE.ALL then
        self.TxtTotalNum.text = CSXTextManagerGetText("EquipSuitPrefabNum", num, XDataCenter.EquipManager.GetSuitPrefabNumMax())
        self.TextName.text = CSXTextManagerGetText("AwarenessGroup")
    elseif self.TabType == TAB_TYPE.ONE then
        local charConfig = XMVCA.XCharacter:GetCharacterTemplate(self.CharacterId)
        self.TxtTotalNum.text = CSXTextManagerGetText("EquipSuitPrefabNum", num, XDataCenter.EquipManager.GetEquipSuitCharacterPrefabMaxNum())
        self.TextName.text = CSXTextManagerGetText("AwarenessGroupWithName", charConfig.TradeName)
    end    

    self.DynamicTable:SetDataSource(self.SuitPrefabInfoList)
    self.DynamicTable:ReloadDataASync(resetScroll and 1)
end

function XUiEquipAwarenessSuitPrefab:OnDynamicTableEvent(event, index, grid)
    local suitPrefabIndex = self.SuitPrefabInfoList[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local suitPrefabInfo = self:GetShowingPrefabInfo(suitPrefabIndex)
        local isPreafabSaved = suitPrefabIndex ~= CUR_SUIT_PREFAB_INDEX
        grid:Refresh(suitPrefabInfo, index-1, isPreafabSaved)
        if self.CurPrefabIndex == suitPrefabIndex then
            grid:SetSelected(true)
            self.LastSelectSuitPrefabGird = grid
        else
            grid:SetSelected(false)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.LastSelectSuitPrefabGird then
            self.LastSelectSuitPrefabGird:SetSelected(false)
        end
        self.LastSelectSuitPrefabGird = grid
        if self.LastSelectSuitPrefabGird then
            self.LastSelectSuitPrefabGird:SetSelected(true)
        end
        self:UpdateCurEquipGrids(suitPrefabIndex)
        self:ClosePopup()
    end
end

function XUiEquipAwarenessSuitPrefab:UpdateCurEquipGrids(suitPrefabIndex)
    self.CurPrefabIndex = suitPrefabIndex

    self:UpdateSavePanel()
    self.EquipBtnGroup:SelectIndex(self.SelectShowProperty)
    for _, equipSite in pairs(XEquipConfig.EquipSite.Awareness) do
        self:UpdateCurEquipGrid(equipSite)
    end
end

function XUiEquipAwarenessSuitPrefab:UpdateCurEquipGrid(equipSite)
    local suitPrefabInfo = self:GetShowingPrefabInfo()

    local equipId = suitPrefabInfo:GetEquipId(equipSite)
    if not equipId or equipId == 0 then
        self.CurEquipGirds[equipSite]:Close()
        self["PanelNoEquip" .. equipSite].gameObject:SetActiveEx(true)
    else
        self.CurEquipGirds[equipSite]:Refresh(equipId)
        self.CurEquipGirds[equipSite]:Open()
        self["PanelNoEquip" .. equipSite].gameObject:SetActiveEx(false)
    end
end

function XUiEquipAwarenessSuitPrefab:ClosePopup()
    if XLuaUiManager.IsUiShow("UiEquipAwarenessPopup") then
        XLuaUiManager.Close("UiEquipAwarenessPopup")
    end
end

function XUiEquipAwarenessSuitPrefab:OnSelectEquip(equipId)
    local equipSite = XDataCenter.EquipManager.GetEquipSite(equipId)
    self:OnSelectEquipSite(equipSite)

    if self.CurEquipGirds[equipSite] then
        XLuaUiManager.Open("UiEquipAwarenessPopup", self, nil, equipId, self.CharacterId, true)
    end
end

function XUiEquipAwarenessSuitPrefab:OnSelectEquipSite(equipSite)
    if self.LastSelectPos then
        local go = self["ImgSelect" .. self.LastSelectPos]
        if go then
            go.gameObject:SetActiveEx(false)
        end
    end
    self.LastSelectPos = equipSite
    if self.LastSelectPos then
        local go = self["ImgSelect" .. self.LastSelectPos]
        if go then
            go.gameObject:SetActiveEx(true)
        end
    end

    if self.LastSelectCurGrid then
        self.LastSelectCurGrid:SetSelected(false)
    end
    self.LastSelectCurGrid = self.CurEquipGirds[equipSite]
    if self.LastSelectCurGrid then
        self.LastSelectCurGrid:SetSelected(true)
    end

    self:ClosePopup()
end

function XUiEquipAwarenessSuitPrefab:GetShowingPrefabInfo(prefabIndex)
    prefabIndex = prefabIndex or self.CurPrefabIndex
    return XDataCenter.EquipManager.GetSuitPrefabInfo(prefabIndex) or self.UnSavedPrefabInfo
end

function XUiEquipAwarenessSuitPrefab:GetSuitPrefabIndexList(tabType)
    if tabType == nil then tabType = self.TabType end
    local tl = {0} --0对应自定义的那列
    local suitPrefabInfoList = XDataCenter.EquipManager.GetSuitPrefabIndexList()

    for i,suitPrefabIndex in ipairs(suitPrefabInfoList) do
        local suitPrefabInfo = self:GetShowingPrefabInfo(suitPrefabIndex)
        if tabType == TAB_TYPE.ALL then
            if suitPrefabInfo:GetCharacterId() == 0 then
                table.insert(tl, suitPrefabIndex)
            end
        elseif tabType == TAB_TYPE.ONE then
            if suitPrefabInfo:GetCharacterId() == self.CharacterId then
                table.insert(tl, suitPrefabIndex)
            end
        end
    end

    return tl
end

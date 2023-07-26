local XUiGridSuitDetail = XClass(nil, "XUiGridSuitDetail")
local XUiPanelSuitList = XClass(nil, "XUiPanelSuitList")

local XUiGridEquip = require("XUi/XUiEquipAwarenessReplace/XUiGridEquip")
local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")
local Dropdown = CS.UnityEngine.UI.Dropdown
local CSInstantiate = CS.UnityEngine.Object.Instantiate
local ALL_SUIT_ID = 0 -- 显示全部对应的套装id
local SKILL_DES_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("188649"),
    [false] = XUiHelper.Hexcolor2Color("1B3750")
}
local SELECT = CS.UiButtonState.Select
local NORMAL = CS.UiButtonState.Normal

local XUiEquipAwarenessReplaceV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipAwarenessReplaceV2P6")

function XUiEquipAwarenessReplaceV2P6:OnAwake()
    self.CompareEffect = self.Transform:Find("SafeAreaContentPane/Right/Effect")
    self.SuitItem.gameObject:SetActiveEx(false)
    self.SuitList.gameObject:SetActiveEx(false)
    self.EquipDetail1.gameObject:SetActiveEx(false)
    self.EquipDetail2.gameObject:SetActiveEx(false)

    self.IsOpenSuitList = false
    self.SuitGoList = {}
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    
    self:SetButtonCallBack()
    self:InitDynamicTable()
end

function XUiEquipAwarenessReplaceV2P6:OnStart(characterId, equipSite, notShowStrengthenBtn)
    self.CharacterId = characterId
    self.SelectSite = equipSite or XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.ONE
    self.SelectSuitId = ALL_SUIT_ID
    self.NotShowStrengthenBtn = notShowStrengthenBtn == true

    -- 刷新套装页签、位置选中
    self:UpdateSuitTitle()
    self.PanelTogPos:SelectIndex(self.SelectSite) -- 由于self.SelectSite == site，只刷UI不会重复筛选、刷新列表
end

function XUiEquipAwarenessReplaceV2P6:OnEnable()
    self.IsEnableShow = true
    self:UpdateView()
end

function XUiEquipAwarenessReplaceV2P6:OnDisable()
    self.FxUiLihuiChuxian01.gameObject:SetActiveEx(false)
    self:OnBtnSuitTitleClick(false)
end

function XUiEquipAwarenessReplaceV2P6:OnDestroy()
    self:ReleaseModel()
    self:ReleaseLihuiTimer()
end

--注册监听事件
function XUiEquipAwarenessReplaceV2P6:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_PUTON_NOTYFY
        , XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY
        , XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY
        , XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY
        , XEventId.EVENT_EQUIP_RECYCLE_NOTIFY
    }
end

--处理事件监听
function XUiEquipAwarenessReplaceV2P6:OnNotify(evt, ...)
    local args = { ... }

    if evt == XEventId.EVENT_EQUIP_PUTON_NOTYFY then
        self:UpdateView()

        local grid = self.DynamicTable:GetGridByIndex(1)
        local effect = grid.Transform:Find("Effect")
        effect.gameObject:SetActive(false)
        effect.gameObject:SetActive(true)
    elseif evt == XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY then
        self:UpdateView()
    end
end

function XUiEquipAwarenessReplaceV2P6:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainClick)
    self:RegisterClickEvent(self.BtnBg, self.OnBtnBgClick)
    self:RegisterClickEvent(self.SuitTitle, function() self:OnBtnSuitTitleClick(true) end)
    self:RegisterClickEvent(self.SuitTitleSelect, function() self:OnBtnSuitTitleClick(false) end)

    -- 位置按钮
    self.PosTogList = {self.Tog1, self.Tog2, self.Tog3, self.Tog4, self.Tog5, self.Tog6}
    self.PanelTogPos:Init(self.PosTogList, function(index) 
        self:OnSelectSite(index) 
    end)

    -- 装备详情操作按钮
    self:RegisterClickEvent(self.EquipDetail1:GetObject("BtnStrengthen"), function() self:OnBtnStrengthenClick(self.DetailEquipId1) end)
    self:RegisterClickEvent(self.EquipDetail1:GetObject("BtnPutOn"), function() self:OnBtnPutOnClick(self.DetailEquipId1) end)
    self:RegisterClickEvent(self.EquipDetail1:GetObject("BtnTakeOff"), function() self:OnBtnTakeOffClick(self.DetailEquipId1) end)
end

function XUiEquipAwarenessReplaceV2P6:OnBtnBackClick()
    self:Close()
end

function XUiEquipAwarenessReplaceV2P6:OnBtnMainClick()
    XLuaUiManager.RunMain()
end

function XUiEquipAwarenessReplaceV2P6:OnBtnBgClick()
    self:OnBtnSuitTitleClick(false)

    if self.IsDetail2Show then
        self.IsDetail2Show = false
        self:PlayAnimation("EquipDetail2Disable", function()
            self.EquipDetail2.gameObject:SetActiveEx(false)
        end)
    end
end

function XUiEquipAwarenessReplaceV2P6:OnBtnSuitTitleClick(isOpen)
    if self.IsOpenSuitList == isOpen then
        return
    end

    self.IsOpenSuitList = isOpen
    self.SuitTitle.gameObject:SetActiveEx(not isOpen)
    self.SuitTitleSelect.gameObject:SetActiveEx(isOpen)
    if isOpen then
        self.SuitList.gameObject:SetActiveEx(true)
        self:PlayAnimation("SuitListEnable")
        self:UpdateSuitList()
    else
        self:PlayAnimation("SuitListDisable", function()
            self.SuitList.gameObject:SetActiveEx(false)
        end)
    end
end

function XUiEquipAwarenessReplaceV2P6:OnSelectSite(site)
    self:OnBtnSuitTitleClick(false)
    if self.SelectSite == site then
        return
    end
    self:PlayAnimation("SuitQieHuan")
    self:PlayAnimation("EquipDetail2QieHuan")

    -- 非选中 "全部" 页签，筛选无意识则不给切换
    local awarenessList
    if self.SelectSuitId ~= ALL_SUIT_ID then
        awarenessList = self._Control:GetAwarenessList(self.CharacterId, site, self.SelectSuitId)
        if #awarenessList == 0 then
            XUiManager.TipText("FilterAwarenessEmpty")
            self.PanelTogPos:SelectIndex(self.SelectSite)
            return
        end
    end
    
    self.SelectSite = site
    self:UpdateAwarenessList(awarenessList)
    self:UpdateEquipDetail()
end

function XUiEquipAwarenessReplaceV2P6:OnSelectSuit(suitId)
    self.SelectSuitId = suitId
    self:OnBtnSuitTitleClick(false)
    self:UpdateSuitTitle()
    self:UpdateAwarenessList()
    self:UpdateEquipDetail()
end

function XUiEquipAwarenessReplaceV2P6:OnBtnStrengthenClick(equipId)
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipDetail(equipId, nil, self.CharacterId, nil, nil, nil, true)
end

function XUiEquipAwarenessReplaceV2P6:OnBtnPutOnClick(equipId)
    local characterId = self.CharacterId

    local wearingCharacterId = XDataCenter.EquipManager.GetEquipWearingCharacterId(equipId)
    if wearingCharacterId and wearingCharacterId > 0 then
        local fullName = XCharacterConfigs.GetCharacterFullNameStr(wearingCharacterId)
        local content = string.gsub(CSXTextManagerGetText("EquipAwarenessReplaceTip", fullName), " ", "")
        XUiManager.DialogTip(
            CSXTextManagerGetText("TipTitle"),
            content,
            XUiManager.DialogType.Normal,
            function()
            end,
            function()
                XMVCA:GetAgency(ModuleId.XEquip):PutOn(characterId, equipId)
            end
        )
    else
        XMVCA:GetAgency(ModuleId.XEquip):PutOn(characterId, equipId)
    end
end

function XUiEquipAwarenessReplaceV2P6:OnBtnTakeOffClick(equipId)
    XMVCA:GetAgency(ModuleId.XEquip):TakeOff({equipId})
end

-- 刷新界面
function XUiEquipAwarenessReplaceV2P6:UpdateView()
    self:UpdateAwarenessList()
    self:UpdateEquipDetail()
end

-- 刷新意识列表
function XUiEquipAwarenessReplaceV2P6:UpdateAwarenessList(awarenessList)
    self.AwarenessList = awarenessList or self._Control:GetAwarenessList(self.CharacterId, self.SelectSite, self.SelectSuitId)

    -- 检测当前选中角色是否失效
    if self.SelectEquipId then
        local isExitEquip = false
        for _, equip in ipairs(self.AwarenessList) do
            if equip.Id == self.SelectEquipId then
                isExitEquip = true
                break
            end
        end
        if not isExitEquip then
            self.SelectEquipId = nil
        end
    end

    -- 默认选中第一个装备
    if not self.SelectEquipId and #self.AwarenessList > 0 then
        self.SelectEquipId = self.AwarenessList[1].Id
    end

    self.DynamicTable:SetDataSource(self.AwarenessList)
    self.DynamicTable:ReloadDataSync(#self.AwarenessList > 0 and 1 or -1)
    local isEmpty = #self.AwarenessList == 0
    self.PanelNoEquip.gameObject:SetActiveEx(isEmpty)
end

function XUiEquipAwarenessReplaceV2P6:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEquipList)
    self.DynamicTable:SetProxy(XUiGridEquip, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiEquipAwarenessReplaceV2P6:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local equip = self.AwarenessList[index]
        local isSelect = self.SelectEquipId == equip.Id
        grid:Refresh(equip.Id)
        grid:SetSelected(isSelect)
        grid.Transform:Find("Effect").gameObject:SetActiveEx(false)

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local grids = self.DynamicTable:GetGrids()
        for _, grid in pairs(grids) do
            grid:SetSelected(false)
        end

        self.SelectEquipId = self.AwarenessList[index].Id
        grid:SetSelected(true)
        self:UpdateEquipDetail()
    end
end

-- 刷新装备详情
function XUiEquipAwarenessReplaceV2P6:UpdateEquipDetail()
    -- 刷新装备详情
    local wearEquipId = XDataCenter.EquipManager.GetWearingEquipIdBySite(self.CharacterId, self.SelectSite)
    local isCompare = false
    if self.SelectEquipId and wearEquipId and self.SelectEquipId ~= wearEquipId then
        self.DetailEquipId1 = self.SelectEquipId
        self.DetailEquipId2 = wearEquipId
        isCompare = true
    else
        self.DetailEquipId1 = self.SelectEquipId or wearEquipId
        self.DetailEquipId2 = nil
    end
    self:UpdateOneEquipDetail(1, self.DetailEquipId1, wearEquipId, isCompare)
    self:UpdateOneEquipDetail(2, self.DetailEquipId2, wearEquipId, isCompare)

    -- 刷新模型
    self:UpdateModel(self.DetailEquipId1)
end

-- 刷新一个装备详情
function XUiEquipAwarenessReplaceV2P6:UpdateOneEquipDetail(equipIndex, equipId, wearEquipId, isCompare)
    local uiObj = equipIndex == 1 and self.EquipDetail1 or self.EquipDetail2
    local isShow = equipId ~= nil

    -- 播放动画
    if equipIndex == 1 then
        uiObj.gameObject:SetActiveEx(isShow)
    else
        if isShow ~= self.IsDetail2Show then
            self.IsDetail2Show = isShow
            if isShow then
                uiObj.gameObject:SetActiveEx(true)
                self:PlayAnimation("EquipDetail2Enable")
                self.CompareEffect.gameObject:SetActive(false)
                self.CompareEffect.gameObject:SetActive(true)

            else
                self:PlayAnimation("EquipDetail2Disable", function()
                    uiObj.gameObject:SetActiveEx(false)
                end)
            end
        elseif isShow then
            self:PlayAnimation("EquipDetail2QieHuan")
            self.CompareEffect.gameObject:SetActive(false)
            self.CompareEffect.gameObject:SetActive(true)
        end
    end

    if not isShow then 
        return 
    end

    -- 刷新面板
    local equip = XMVCA:GetAgency(ModuleId.XEquip):GetEquip(equipId)
    local isWear = equipId == wearEquipId
    local icon = XDataCenter.EquipManager.GetEquipIconBagPath(equip.TemplateId, equip.Breakthrough)
    uiObj:GetObject("RImgIcon"):SetRawImage(icon)
    local name = XMVCA:GetAgency(ModuleId.XEquip):GetEquipName(equip.TemplateId)
    uiObj:GetObject("TxtName").text = name
    uiObj:GetObject("TxtLv").text = equip.Level

    -- 意识属性
    local attrMap = XMVCA:GetAgency(ModuleId.XEquip):GetEquipAttrMap(equipId)
    for i = 1, XEnumConst.EQUIP.MAX_ATTR_COUNT do
        local attrInfo = attrMap[i]
        local isShow = attrInfo ~= nil
        uiObj:GetObject("PanelAttr" .. i).gameObject:SetActiveEx(isShow)
        if isShow then
            uiObj:GetObject("TxtName" .. i).text = attrInfo.Name
            uiObj:GetObject("TxtAttr" .. i).text = attrInfo.Value
        end
    end

    -- 套装技能
    local suitId = XMVCA:GetAgency(ModuleId.XEquip):GetEquipSuitId(equip.TemplateId)
    local activeCount, siteCheckDic = XDataCenter.EquipManager.GetActiveSuitEquipsCount(self.CharacterId, suitId)
    if not isWear then
        local wearSuitId
        if wearEquipId then
            local wearEquip = XMVCA:GetAgency(ModuleId.XEquip):GetEquip(wearEquipId)
            wearSuitId = XMVCA:GetAgency(ModuleId.XEquip):GetEquipSuitId(wearEquip.TemplateId)
        end
        if wearSuitId ~= suitId then
            activeCount = activeCount + 1 -- 预览穿上的激活效果
        end
    end
    local isOverrun = XMVCA:GetAgency(ModuleId.XEquip):IsCharacterOverrunSuit(self.CharacterId, suitId)
    local skillDesList = XMVCA:GetAgency(ModuleId.XEquip):GetSuitActiveSkillDesList(suitId, activeCount, isOverrun, isOverrun)
    for i = 1, XEnumConst.EQUIP.MAX_SUIT_SKILL_COUNT do
        local skillInfo = skillDesList[i]
        local isShow = skillInfo ~= nil
        local txtSkillDes = uiObj:GetObject("TxtSkillDes" .. i)
        txtSkillDes.gameObject:SetActiveEx(isShow)
        if isShow then
            local color = SKILL_DES_COLOR[skillInfo.IsActive]
            txtSkillDes.text = skillInfo.SkillDes
            txtSkillDes.color = color
            local txtPos = uiObj:GetObject("TxtPos" .. i)
            txtPos.color = color
        end
    end

    -- 共鸣、超频
    local canResonance = XDataCenter.EquipManager.CanResonanceByTemplateId(equip.TemplateId)
    uiObj:GetObject("PanelResonanceTitle").gameObject:SetActiveEx(canResonance)
    uiObj:GetObject("PanelResonance").gameObject:SetActiveEx(canResonance)
    if canResonance then
        for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
            local resonanceUiObj = uiObj:GetObject("ResonanceSkill" .. pos)
            self:UpdateResonanceSkill(equipIndex, resonanceUiObj, equipId, pos)
        end
    end

    -- 按钮
    -- 在比较2件装备时，当前穿戴的装备不显示穿戴/卸下按钮，显示“当前装备”
    local showCurWear = isCompare and isWear
    uiObj:GetObject("PanelCurrentEquipment").gameObject:SetActiveEx(showCurWear)
    uiObj:GetObject("BtnStrengthen").gameObject:SetActiveEx(not showCurWear and not self.NotShowStrengthenBtn)
    uiObj:GetObject("BtnTakeOff").gameObject:SetActiveEx(not showCurWear and isWear)
    uiObj:GetObject("BtnPutOn").gameObject:SetActiveEx(not showCurWear and not isWear)
end

-- 刷新单个意识共鸣
function XUiEquipAwarenessReplaceV2P6:UpdateResonanceSkill(equipIndex, resonanceUiObj, equipId, pos)
    local isEquip = XDataCenter.EquipManager.CheckEquipPosResonanced(equipId, pos) ~= nil
    local panelNoResnoance = resonanceUiObj:GetObject("PanelNoResnoance")
    panelNoResnoance.gameObject:SetActive(not isEquip)
    if not isEquip then
        panelNoResnoance:GetObject("BtnClick").CallBack = function()
            self:OnBtnResonanceSkill(equipIndex, pos)
        end
    end

    local skillGo = resonanceUiObj:GetObject("GridResnanceSkill")
    skillGo.gameObject:SetActive(isEquip)

    if isEquip then
        self.ResonanceSkillDic = self.ResonanceSkillDic or {}
        local hashCode = skillGo.transform:GetHashCode()
        local grid = self.ResonanceSkillDic[hashCode]
        if not grid then
            grid = XUiGridResonanceSkill.New(skillGo, equipId, pos, self.CharacterId, function()
                self:OnBtnResonanceSkill(equipIndex)
            end, nil, self.ForceShowBindCharacter)
            self.ResonanceSkillDic[hashCode] = grid
        end
        grid:SetEquipIdAndPos(equipId, pos)
        grid:Refresh()
    end
end

-- 点击意识共鸣
function XUiEquipAwarenessReplaceV2P6:OnBtnResonanceSkill(equipIndex, pos)
    local equipId = equipIndex == 1 and self.DetailEquipId1 or self.DetailEquipId2
    XLuaUiManager.Open("UiEquipDetailV2P6", equipId, nil, self.CharacterId, nil, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE, nil, pos)
end

-- 刷新模型
function XUiEquipAwarenessReplaceV2P6:UpdateModel(modelEquipId)
    if not modelEquipId then
        self.FxUiLihuiChuxian01.gameObject:SetActiveEx(false)
        return
    end

    self:ReleaseModel()
    local equip = XMVCA:GetAgency(ModuleId.XEquip):GetEquip(modelEquipId)
    local resPath = XDataCenter.EquipManager.GetEquipLiHuiPath(equip.TemplateId, equip.Breakthrough)
    self.Resource = CS.XResourceManager.Load(resPath)
    local texture = self.Resource.Asset
    self.MeshLihui.sharedMaterial:SetTexture("_MainTex", texture)
    self.ModelEquipId = modelEquipId

    local delayTime = self.IsEnableShow and 500 or 300
    self.IsEnableShow = false
    self:ReleaseLihuiTimer()
    self.FxUiLihuiChuxian01.gameObject:SetActive(false)
    self.LihuiTimer = XScheduleManager.ScheduleOnce(function()
        self.FxUiLihuiChuxian01.gameObject:SetActive(true)
        self.LihuiTimer = nil
    end, delayTime)
end

-- 释放模型
function XUiEquipAwarenessReplaceV2P6:ReleaseModel()
    if self.Resource then
        CS.XResourceManager.Unload(self.Resource)
        self.Resource = nil
    end
end

-- 释放定时器
function XUiEquipAwarenessReplaceV2P6:ReleaseLihuiTimer()
    if self.LihuiTimer then
        XScheduleManager.UnSchedule(self.LihuiTimer)
        self.LihuiTimer = nil
    end
end

-- 刷新套装标题
function XUiEquipAwarenessReplaceV2P6:UpdateSuitTitle()
    local isAll = self.SelectSuitId == ALL_SUIT_ID
    self.ImgSuitIcon.gameObject:SetActiveEx(not isAll)
    self.ImgSuitIconSelect.gameObject:SetActiveEx(not isAll)
    local suitName
    if isAll then
        suitName = XUiHelper.GetText("ScreenAll")
    else
        suitName = XMVCA:GetAgency(ModuleId.XEquip):GetEquipSuitName(self.SelectSuitId)
        local iconPath = XMVCA:GetAgency(ModuleId.XEquip):GetEquipSuitIconPath(self.SelectSuitId)
        self.ImgSuitIcon:SetSprite(iconPath)
        self.ImgSuitIconSelect:SetSprite(iconPath)
    end

    local title = XUiHelper.GetText("CurrentFilterSuit", suitName)
    self.TxtSuitTitle.text = title
    self.TxtSuitTitleSelect.text = title
end
    
-- 刷新套装列表
function XUiEquipAwarenessReplaceV2P6:UpdateSuitList()
    if not self.UiPanelSuitList then
        self.UiPanelSuitList = XUiPanelSuitList.New(self, self.SuitList)
    end

    local suitInfoList = self:GetSuitInfoList()
    self.UiPanelSuitList:UpdateSuitList(suitInfoList)
end

-- 获取套装列表
function XUiEquipAwarenessReplaceV2P6:GetSuitInfoList()
    local priorityDic = {}
    local suitPriorityCfg = self._Control:GetConfigCharacterSuitPriority(self.CharacterId)
    if suitPriorityCfg then
        for index, suitType in ipairs(suitPriorityCfg.PriorityType) do
            priorityDic[suitType] = index
        end
    end

    -- 排序
    local suitInfoList = self._Control:GetSuitInfoList(self.CharacterId, self.SelectSite)
    table.sort(suitInfoList, function(a, b)
        -- 专属套装优先
        if suitPriorityCfg.ExclusiveSuitId ~= 0 then
            local isExclusiveA = suitPriorityCfg.ExclusiveSuitId == a.SuitId
            local isExclusiveB = suitPriorityCfg.ExclusiveSuitId == b.SuitId
            if isExclusiveA ~= isExclusiveB then
                return isExclusiveA
            end
        end

        -- 根据优先级排序
        local suitTypeA = XMVCA:GetAgency(ModuleId.XEquip):GetEquipSuitSuitType(a.SuitId)
        local suitTypeB = XMVCA:GetAgency(ModuleId.XEquip):GetEquipSuitSuitType(b.SuitId)
        local priorityA = priorityDic[suitTypeA] or 100000
        local priorityB = priorityDic[suitTypeB] or 100000
        if priorityA ~= priorityB then
            return priorityA < priorityB
        end

        -- 按照意识套装ID从大到小排序
        return a.SuitId > b.SuitId
    end)

    -- 全部按钮
    local allCount = 0
    for _, suitInfo in ipairs(suitInfoList) do
        allCount = allCount + suitInfo.Count
    end
    table.insert(suitInfoList, 1, { SuitId = 0, Count = allCount})

    return suitInfoList
end

-------------------------------------#region 意识套装滑动列表 XUiPanelSuitList --------------------------------
function XUiPanelSuitList:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:InitDynamicTable()
end

function XUiPanelSuitList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridSuitDetail)
end

function XUiPanelSuitList:UpdateSuitList(suitInfoList)
    XTool.ReverseList(suitInfoList) -- 从下往上反序显示
    self.SuitInfoList = suitInfoList
    self.DynamicTable:SetDataSource(self.SuitInfoList)
    self.DynamicTable:ReloadDataASync(#self.SuitInfoList > 0 and #self.SuitInfoList or -1)
end

function XUiPanelSuitList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local suitInfo = self.SuitInfoList[index]
        local isSelect = suitInfo.SuitId == self.RootUi.SelectSuitId
        grid:Refresh(suitInfo, isSelect)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local suitInfo = self.SuitInfoList[index]
        self.RootUi:OnSelectSuit(suitInfo.SuitId)
    end
end
-------------------------------------#endregion 意识套装滑动列表 XUiPanelSuitList --------------------------------

-------------------------------------#region XUiGridSuitDetail --------------------------------
function XUiGridSuitDetail:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridSuitDetail:Init(rootUi)
    self.RootUi = rootUi
end

function XUiGridSuitDetail:Refresh(suitInfo, isSelect)
    local state = isSelect and SELECT or NORMAL
    self.UiButton:SetButtonState(state)
    self.UiButton.TempState = state

    local stateObjList = { self.Normal, self.Press, self.Select }
    for _, showObj in ipairs(stateObjList) do
        local isAll = suitInfo.SuitId == ALL_SUIT_ID
        showObj:GetObject("ImgSuitIcon").gameObject:SetActiveEx(not isAll)
        showObj:GetObject("TxtSuitDesc").gameObject:SetActiveEx(not isAll)
        if isAll then
            showObj:GetObject("TxtSuitName").text = XUiHelper.GetText("ScreenAll")
            showObj:GetObject("TxtNumber").text = "x" .. suitInfo.Count
        else
            showObj:GetObject("TxtSuitName").text = XMVCA:GetAgency(ModuleId.XEquip):GetEquipSuitName(suitInfo.SuitId)
            showObj:GetObject("TxtNumber").text = "x" .. suitInfo.Count
            local iconPath = XMVCA:GetAgency(ModuleId.XEquip):GetEquipSuitIconPath(suitInfo.SuitId)
            showObj:GetObject("ImgSuitIcon"):SetSprite(iconPath)
            showObj:GetObject("TxtSuitDesc").text = XMVCA:GetAgency(ModuleId.XEquip):GetEquipSuitDescription(suitInfo.SuitId)
        end
    end
end
-------------------------------------#endregion XUiGridSuitDetail --------------------------------

return XUiEquipAwarenessReplaceV2P6

local XUiEquipOverrunSelect = XLuaUiManager.Register(XLuaUi, "UiEquipOverrunSelect")
local XUiEquipOverrunSelectGrid = require("XUi/XUiEquipOverrun/XUiEquipOverrunSelectGrid")
local CSInstantiate = CS.UnityEngine.Object.Instantiate
local CanNotBuyColor = CS.XGame.ClientConfig:GetString("ActivityShopItemTextCanNotBuyColor")

function XUiEquipOverrunSelect:OnAwake()
    self.GridSuitSimple.gameObject:SetActiveEx(false)
    self.PanelActive.gameObject:SetActiveEx(false)
    self.PanelNotActive.gameObject:SetActiveEx(false)
    self.ActiveGoList = {}
    self.NotActiveGoList = {}

    self:SetButtonCallBack()
    self:InitDynamicTable()
end

function XUiEquipOverrunSelect:OnStart(equipId, selectCallBack, isPreview)
    self.EquipId = equipId
    self.SelectCallBack = selectCallBack
    self.IsPreview = isPreview == true
    self.Equip = XDataCenter.EquipManager.GetEquip(self.EquipId)
    self.LastSelectSuitId = self.Equip:GetOverrunChoseSuit()
    self.CurSelectSuitId = self.LastSelectSuitId
    self:Refresh()
end

function XUiEquipOverrunSelect:OnEnable()
    self:RefreshCost()
end

function XUiEquipOverrunSelect:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnActive, self.OnBtnActive)
    XUiHelper.RegisterClickEvent(self, self.BtnChange, self.OnBtnChange)
    XUiHelper.RegisterClickEvent(self, self.RImgSpendIcon, self.OnBtnRImgSpendIcon)
end

function XUiEquipOverrunSelect:OnBtnActive()
    if not self.CanActive then 
        XUiManager.TipText("PokemonUpgradeItemNotEnough")
        return
    end

    -- 二次确认
    local activePos
    for _, skillInfo in ipairs(self.SkillInfoList) do
        if skillInfo.IsActiveByOverrun then
            activePos = skillInfo.Pos
        end
    end
    local suitName = XMVCA:GetAgency(ModuleId.XEquip):GetEquipSuitName(self.CurSelectSuitId)
    local content = activePos and XUiHelper.GetText("EquipOverrunActiveEffectTips1", activePos, suitName) or XUiHelper.GetText("EquipOverrunActiveEffectTips2", suitName)
    XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, function()
        XMVCA:GetAgency(ModuleId.XEquip):EquipWeaponActiveOverrunSuitRequest(self.EquipId, self.CurSelectSuitId, function()
            self:OnBtnChange()
        end)
    end)
end

function XUiEquipOverrunSelect:OnBtnChange()
    if self.SelectSuitData.Id == self.LastSelectSuitId then
        return
    end

    XMVCA:GetAgency(ModuleId.XEquip):EquipWeaponChoseOverrunSuitRequest(self.EquipId, self.CurSelectSuitId, function()
        local tips = XUiHelper.GetText("DormTemplateSelectSuccess")
        XMVCA:GetAgency(ModuleId.XEquip):TipEquipOperation(nil, tips)
        self.SelectCallBack()
        self:Close()
    end)
end

function XUiEquipOverrunSelect:OnBtnRImgSpendIcon()
    local overrunSuitCfg = XEquipConfig.GetWeaponOverrunSuitCfgByTemplateId(self.Equip.TemplateId)
    XLuaUiManager.Open("UiTip", overrunSuitCfg.ActiveSuitItemId)
end

-- 刷新意识列表
function XUiEquipOverrunSelect:Refresh()
    self.TxtTitle.gameObject:SetActiveEx(not self.IsPreview)
    self.TxtPreviewTitle.gameObject:SetActiveEx(self.IsPreview)

    self.SuitDataList = self:GetSuitDataList()
    local suitData = self.SuitDataList[1]
    self.CurSelectSuitId = suitData.Id
    self.DynamicTable:SetDataSource(self.SuitDataList)
    self.DynamicTable:ReloadDataASync(1)

    self:RefreshSuitDetail(suitData)
end

-- 意识激活回调
function XUiEquipOverrunSelect:OnActiveSuit()
    self.SuitDataList = self:GetSuitDataList()
    self.DynamicTable:SetDataSource(self.SuitDataList)
    self.DynamicTable:ReloadDataASync(1)

    for _, suitData in ipairs(self.SuitDataList) do
        if suitData.Id == self.CurSelectSuitId then
            self:RefreshSuitDetail(suitData)
        end
    end
end

function XUiEquipOverrunSelect:GetSuitDataList()
    local overrunSuitCfg = XEquipConfig.GetWeaponOverrunSuitCfgByTemplateId(self.Equip.TemplateId)
    local bindType = overrunSuitCfg.ChipBindType
    -- 类型配置为0的武器，装备在角色身上时，需额外判断，只显示与当前角色匹配的意识套装
    if bindType == XEquipConfig.UserType.All and self.Equip:IsWearing() then
        bindType = XCharacterConfigs.GetCharacterType(self.Equip.CharacterId)
    end
    local suitIdList = XEquipConfig.GetSuitIdListByCharacterType(bindType, XEquipConfig.OVERRUN_BLIND_SUIT_MIN_QUALITY, true, true)

    -- 意识套装品质、是否跟角色身上装备的意识一样
    local suitDataDic = {}
    for _, suitId in ipairs(suitIdList) do
        local suitData = {}
        suitData.Id = suitId
        suitData.Quality = XEquipConfig.GetSuitQuality(suitId)
        suitData.IsCharWear = false
        suitData.CharWearCnt = 0 -- 角色装备该套装意识数量
        suitData.IsActive = false
        suitDataDic[suitId] = suitData
    end

    -- 意识套装是否穿戴
    if self.Equip:IsWearing() then 
        local awarenessIds = XDataCenter.EquipManager.GetCharacterWearingAwarenessIds(self.Equip.CharacterId)
        for _, awarenessId in ipairs(awarenessIds) do
            local templateId = XDataCenter.EquipManager.GetEquipTemplateId(awarenessId)
            local equipCfg = XEquipConfig.GetEquipCfg(templateId)
            local suitData = suitDataDic[equipCfg.SuitId]
            if suitData then
                suitData.IsCharWear = true
                suitData.CharWearCnt = suitData.CharWearCnt + 1
            end
        end
    end

    -- 意识套装是否已激活
    local activeSuits = self.Equip:GetOverrunActiveSuits()
    for _, suitId in ipairs(activeSuits) do
        local suitData = suitDataDic[suitId]
        if suitData then
            suitData.IsActive = true
        end
    end

    -- 转换成list
    local suitDataList = {}
    for _, suitData in pairs(suitDataDic) do
        table.insert(suitDataList, suitData)
    end

    -- 排序
    table.sort(suitDataList, function(a, b)
        -- 当前已绑定的意识套装
        local priorityA = a.Id == self.LastSelectSuitId and 10000 or 0
        local priorityB = b.Id == self.LastSelectSuitId and 10000 or 0

        -- 武器穿戴角色身上装备的意识套装，武器未穿戴在角色身上时此项忽略
        priorityA = priorityA + (a.IsCharWear and 1000 or 0)
        priorityB = priorityB + (b.IsCharWear and 1000 or 0)

        -- 已激活的意识套装
        priorityA = priorityA + (a.IsActive and 100 or 0)
        priorityB = priorityB + (b.IsActive and 100 or 0)

        -- 按照品质排序
        priorityA = priorityA + (a.Quality > b.Quality and 10 or 0)
        priorityB = priorityB + (b.Quality > a.Quality and 10 or 0)

        return priorityA > priorityB
    end)

    return suitDataList
end

function XUiEquipOverrunSelect:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSelectList.gameObject)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiEquipOverrunSelectGrid)
end

function XUiEquipOverrunSelect:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local suitData = self.SuitDataList[index]
        local isLastSelect = suitData.Id == self.LastSelectSuitId
        local isCurSelect = suitData.Id == self.CurSelectSuitId
        grid:Refresh(suitData, isLastSelect)
        grid:SetCurSelect(isCurSelect)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local suitData = self.SuitDataList[index]
        self.CurSelectSuitId = suitData.Id
        local grids = self.DynamicTable:GetGrids()
        for _, grid in pairs(grids) do
            grid:SetCurSelect(false)
        end
        grid:SetCurSelect(true)
        self:RefreshSuitDetail(suitData)
    end
end

-- 刷新意识套装详情
function XUiEquipOverrunSelect:RefreshSuitDetail(suitData)
    self:PlayAnimation("QieHuan")
    self.SelectSuitData = suitData
    self.TxtName.text = XMVCA:GetAgency(ModuleId.XEquip):GetEquipSuitName(suitData.Id)
    local iconPath = XMVCA:GetAgency(ModuleId.XEquip):GetEquipSuitIconPath(suitData.Id)
    self.RImgIcon:SetRawImage(iconPath)

    -- 刷新意识
    for _, activeGo in ipairs(self.ActiveGoList) do
        activeGo.gameObject:SetActiveEx(false)
    end
    for _, notActiveGo in ipairs(self.NotActiveGoList) do
        notActiveGo.gameObject:SetActiveEx(false)
    end

    self.SkillInfoList = XMVCA:GetAgency(ModuleId.XEquip):GetSuitActiveSkillDesList(suitData.Id, suitData.CharWearCnt, true)
    local activeIndex = 1
    local notActiveIndex = 1
    for i, info in ipairs(self.SkillInfoList) do
        local showActive = suitData.Id == self.LastSelectSuitId and info.IsActive or (info.IsActive and not info.IsActiveByOverrun)
        if showActive then
            local activeGo = self.ActiveGoList[activeIndex]
            if not activeGo then
                activeGo = CSInstantiate(self.PanelActive, self.PanelActive.transform.parent)
                table.insert(self.ActiveGoList, activeGo)
            end
            activeGo.gameObject:SetActiveEx(true)
            activeGo.transform:SetAsLastSibling()
            local uiObj = activeGo:GetComponent("UiObject")
            uiObj:GetObject("TxtTitle").text = info.PosDes
            uiObj:GetObject("TxtSkill").text = info.SkillDes

            -- 超限激活状态
            local imgState = XUiHelper.TryGetComponent(uiObj.transform, "PanelTitle/ImgState")
            imgState.gameObject:SetActiveEx(info.IsActiveByOverrun)
            if info.IsActiveByOverrun then
                local txtState = XUiHelper.TryGetComponent(uiObj.transform, "PanelTitle/ImgState/TxtState", "Text")
                txtState.gameObject:SetActiveEx(true)
                txtState.text = XUiHelper.GetText("EquipOverrunActive")
            end

            activeIndex = activeIndex + 1
        else 
            local notActiveGo = self.NotActiveGoList[notActiveIndex]
            if not notActiveGo then
                notActiveGo = CSInstantiate(self.PanelNotActive, self.PanelNotActive.transform.parent)
                table.insert(self.NotActiveGoList, notActiveGo)
            end
            notActiveGo.gameObject:SetActiveEx(true)
            notActiveGo.transform:SetAsLastSibling()
            local uiObj = notActiveGo:GetComponent("UiObject")
            uiObj:GetObject("TxtTitle").text = info.PosDes
            uiObj:GetObject("TxtSkill").text = info.SkillDes
            notActiveIndex = notActiveIndex + 1

            uiObj:GetObject("PanelCanActive").gameObject:SetActiveEx(info.IsActiveByOverrun)
        end
    end

    -- 意识
    if self.Equip:IsWearing() then
        local isActiveByOverrun = false
        for _, info in ipairs(self.SkillInfoList) do
            if info.IsActiveByOverrun then
                isActiveByOverrun = true
                self.TxtDetail.text = info.OverrunTips
            end
        end
        if not isActiveByOverrun then
            self.TxtDetail.text = XUiHelper.GetText("EquipOverrunNotActive")
        end
    else
        self.TxtDetail.text = XUiHelper.GetText("EquipOverrunNotEquip")
    end

    -- 按钮
    if self.IsPreview then
        self.BtnCanActive.gameObject:SetActiveEx(true)
        self.BtnCanActive:SetDisable(true)
        self.BtnChange.gameObject:SetActiveEx(false)
        self.BtnActive.gameObject:SetActiveEx(false)
    else
        self.BtnCanActive.gameObject:SetActiveEx(false)
        self.BtnChange.gameObject:SetActiveEx(suitData.IsActive)
        self.BtnActive.gameObject:SetActiveEx(not suitData.IsActive)
        self.TxtSpend.gameObject:SetActiveEx(not suitData.IsActive)
        if suitData.IsActive then
            self.BtnChange:SetDisable(suitData.Id == self.LastSelectSuitId)
        end
    end

    -- 消耗
    self:RefreshCost()
end

-- 刷新消耗
function XUiEquipOverrunSelect:RefreshCost()
    if self.SelectSuitData.IsActive then
        return
    end

    local overrunSuitCfg = XEquipConfig.GetWeaponOverrunSuitCfgByTemplateId(self.Equip.TemplateId)
    local icon = XItemConfigs.GetItemIconById(overrunSuitCfg.ActiveSuitItemId)
    local ownCnt = XDataCenter.ItemManager.GetCount(overrunSuitCfg.ActiveSuitItemId)
    self.RImgSpendIcon:SetRawImage(icon)
    self.CanActive = ownCnt >= overrunSuitCfg.ActiveSuitItemCount
    if self.CanActive then
        self.TxtSpend.text = tostring(ownCnt) .. "/" .. tostring(overrunSuitCfg.ActiveSuitItemCount)
    else
        self.TxtSpend.text = string.format("<color=#%s>%s</color>/%s", CanNotBuyColor, ownCnt, overrunSuitCfg.ActiveSuitItemCount)
    end
end
local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")
local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")
local ATTR_COLOR = {
    EQUAL = XUiHelper.Hexcolor2Color("1B3750"), -- 属性与当前装备一样
    OVER = XUiHelper.Hexcolor2Color("188649"), -- 属性超出当前装备
    BELOW = XUiHelper.Hexcolor2Color("d11e38"), -- 属性低于当前装备
}

local XUiEquipReplaceV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipReplaceV2P6")

function XUiEquipReplaceV2P6:OnAwake()
    self.IsAscendOrder = false --初始降序
    self.PriorSortType = XEnumConst.EQUIP.PRIOR_SORT_TYPE.STAR
    self.ChangeEquipSuccess = false
    self.IsShowExtend = false -- 当前是否显示扩展面板

    self.ImgAscend.gameObject:SetActive(self.IsAscendOrder)
    self.ImgDescend.gameObject:SetActive(not self.IsAscendOrder)
    self.GridEquip.gameObject:SetActive(false)
    self.PanelExtend.gameObject:SetActiveEx(false)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:SetButtonCallBack()
    self:InitDynamicTable()

    self.PanelAddEffect = self.PanelAdd.transform:Find("Effect")
    self.PanelAdd2Effect = self.PanelAdd2.transform:Find("Effect")
    self.GridEquipResonanceEffect1 = self.GridEquipResonance1.transform:Find("Effect")
    self.GridEquipResonanceEffect2 = self.GridEquipResonance2.transform:Find("Effect")
    self.GridEquipResonanceEffect3 = self.GridEquipResonance3.transform:Find("Effect")
    self.GridEquipResonanceEffect1.gameObject:SetActiveEx(false)
    self.GridEquipResonanceEffect2.gameObject:SetActiveEx(false)
    self.GridEquipResonanceEffect3.gameObject:SetActiveEx(false)
    self.OverrunBlindEffect = self.BtnOverrunBlind.transform:Find("Normal/Effect")
end

function XUiEquipReplaceV2P6:OnStart(charId, closecallback, notShowStrengthenBtn)
    self.CharacterId = charId
    self.CloseCallback = closecallback
    self.NotShowStrengthenBtn = notShowStrengthenBtn == true

    local equipId = XDataCenter.EquipManager.GetCharacterWearingWeaponId(charId)  --初始为角色身上的装备
    self.SelectEquipId = equipId
    self.UsingEquipId = equipId
end

function XUiEquipReplaceV2P6:OnEnable()
    self.PanelAddEffect.gameObject:SetActiveEx(false)
    self.PanelAdd2Effect.gameObject:SetActiveEx(false)
    self:UpdateView()
end

function XUiEquipReplaceV2P6:OnDestroy()
    if self.CloseCallback then
        self.CloseCallback(self.CharacterId, self.ChangeEquipSuccess)
    end
end

--注册监听事件
function XUiEquipReplaceV2P6:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_PUTON_NOTYFY, 
        XEventId.EVENT_EQUIP_RESONANCE_NOTYFY,
    }
end

--处理事件监听
function XUiEquipReplaceV2P6:OnNotify(evt, ...)
    local args = { ... }
    local equipId = args[1]

    if evt == XEventId.EVENT_EQUIP_PUTON_NOTYFY then
        self.UsingEquipId = equipId
        self:OnPutOnEquip()
        
        local grid = self.DynamicTable:GetGridByIndex(1)
        local effect = grid.Transform:Find("Effect")
        effect.gameObject:SetActive(false)
        effect.gameObject:SetActive(true)
    elseif evt == XEventId.EVENT_EQUIP_RESONANCE_NOTYFY then
        XMVCA:GetAgency(ModuleId.XEquip):TipEquipOperation(nil, XUiHelper.GetText("DormTemplateSelectSuccess"))
        self:UpdateEquipResonance()

        local slots = args[2]
        for _, pos in ipairs(slots) do
            self["GridEquipResonanceEffect"..pos].gameObject:SetActiveEx(true)
        end
    end
end

function XUiEquipReplaceV2P6:OnPutOnEquip()
    self:OnSortTypeChange()
    self:UpdateEquipDetail()
end

function XUiEquipReplaceV2P6:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnStrengthen, self.OnBtnStrengthenClick)
    self:RegisterClickEvent(self.BtnTakeOn, self.OnBtnTakeOnClick)

    self:RegisterClickEvent(self.BtnOrder, self.OnBtnOrderClick)
    self.DrdSort.onValueChanged:AddListener(function()
        self.PriorSortType = self.DrdSort.value
        self:OnSortTypeChange()
    end)

    self:RegisterClickEvent(self.PanelAdd, self.ShowPanelSkill)
    self:RegisterClickEvent(self.PanelAdd2, self.ShowPanelExtend)

    -- 武器共鸣
    self:RegisterClickEvent(self.GridEquipResonance1, function() self:OnBtnResonanceSkill(1) end)
    self:RegisterClickEvent(self.GridEquipResonance2, function() self:OnBtnResonanceSkill(2) end)
    self:RegisterClickEvent(self.GridEquipResonance3, function() self:OnBtnResonanceSkill(3) end)
    self:RegisterClickEvent(self.BtnResonance, function() self:OnBtnResonanceSkill() end)

    -- 武器超限
    self:RegisterClickEvent(self.BtnOverrun, self.OnBtnOverrun)
    self:RegisterClickEvent(self.BtnOverrunBlind, self.OnBtnOverrunClick)
    self:RegisterClickEvent(self.BtnOverrunEmpty, self.OnBtnOverrunClick)
end

function XUiEquipReplaceV2P6:OnBtnBackClick()
    self:Close()
end

function XUiEquipReplaceV2P6:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiEquipReplaceV2P6:OnBtnStrengthenClick()
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipDetail(self.SelectEquipId, nil, self.CharacterId, nil, nil, nil, true)
end

function XUiEquipReplaceV2P6:OnBtnTakeOnClick()
    local equip = XDataCenter.EquipManager.GetEquip(self.SelectEquipId)
    local characterId = equip.CharacterId
    --其他角色使用中
    if characterId and characterId > 0 then
        --自己穿戴了专属装备
        local specialCharacterId = XDataCenter.EquipManager.GetEquipSpecialCharacterId(self.UsingEquipId)
        if specialCharacterId and specialCharacterId > 0 then
            XUiManager.TipText("EquipWithSpecialCharacterIdCanNotBeReplaced")
            return
        end

        local fullName = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
        local content = string.gsub(CS.XTextManager.GetText("EquipReplaceTip", fullName), " ", "")
        XUiManager.DialogTip(CS.XTextManager.GetText("TipTitle"), content, XUiManager.DialogType.Normal, function() end, function()
            XMVCA:GetAgency(ModuleId.XEquip):PutOn(self.CharacterId, self.SelectEquipId)
            self.ChangeEquipSuccess = true
        end)
    
    -- 检测这个角色穿戴是否意识不匹配
    elseif not equip:IsOverrunBlindMatch(self.CharacterId) then
        local content = CS.XTextManager.GetText("EquipOverrunBlindNotMatchTips")
        XUiManager.DialogTip(CS.XTextManager.GetText("TipTitle"), content, XUiManager.DialogType.Normal, function() end, function()
            XMVCA:GetAgency(ModuleId.XEquip):PutOn(self.CharacterId, self.SelectEquipId)
            self.ChangeEquipSuccess = true
        end)
    else
        XMVCA:GetAgency(ModuleId.XEquip):PutOn(self.CharacterId, self.SelectEquipId)
        self.ChangeEquipSuccess = true
    end
end

function XUiEquipReplaceV2P6:OnBtnOrderClick()
    self.IsAscendOrder = not self.IsAscendOrder
    self.ImgAscend.gameObject:SetActive(self.IsAscendOrder)
    self.ImgDescend.gameObject:SetActive(not self.IsAscendOrder)

    XTool.ReverseList(self.WeaponIdList)
    self:UpdateEquipList()
end

function XUiEquipReplaceV2P6:OnBtnResonanceSkill(pos)
    local equip = XMVCA:GetAgency(ModuleId.XEquip):GetEquip(self.SelectEquipId)
    local star = XMVCA:GetAgency(ModuleId.XEquip):GetEquipQuality(equip.TemplateId)

    -- 共鸣技能替换界面，武器且选中位置与当前角色是共鸣
    if equip:IsWeapon() and pos and equip:GetResonanceBindCharacterId(pos) == self.CharacterId then
        XLuaUiManager.Open("UiEquipResonanceSkillChangeV2P6", self.CharacterId, self.SelectEquipId)

    -- 5星武器只能共鸣一次
    elseif equip:IsWeapon() and equip:GetResonanceInfo(pos) and star == XEnumConst.EQUIP.FIVE_STAR then
        XLuaUiManager.Open("UiEquipDetailV2P6", self.SelectEquipId, nil, self.CharacterId, nil, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE)
    else
        XLuaUiManager.Open("UiEquipDetailV2P6", self.SelectEquipId, nil, self.CharacterId, nil, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE, nil, pos)
    end
end

function XUiEquipReplaceV2P6:OnBtnOverrun()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipOverrun) then 
        local tips = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.EquipOverrun)
        XUiManager.TipError(tips)
        return
    end
        
    XLuaUiManager.Open("UiEquipDetailV2P6", self.SelectEquipId, nil, self.CharacterId, nil, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERRUN)
end

function XUiEquipReplaceV2P6:OnBtnOverrunClick()
    if self.OverrunIconTips then
        XUiManager.TipError(self.OverrunIconTips)
        return
    end

    XLuaUiManager.Open("UiEquipOverrunSelect", self.SelectEquipId, function()
        self:UpdateOverrun()
        self.OverrunBlindEffect.gameObject:SetActiveEx(true)
    end)
end

function XUiEquipReplaceV2P6:OnSortTypeChange()
    XDataCenter.EquipManager.SortEquipIdListByPriorType(self.WeaponIdList, self.PriorSortType)
    if self.IsAscendOrder then
        XTool.ReverseList(self.WeaponIdList)
    end
    self:UpdateEquipList()
end

function XUiEquipReplaceV2P6:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEquipScroll)
    self.DynamicTable:SetProxy(XUiGridEquip, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiEquipReplaceV2P6:UpdateEquipList()
    self:MoveUsingWeaponInFirst()
    self.DynamicTable:SetDataSource(self.WeaponIdList)
    self.DynamicTable:ReloadDataASync(#self.WeaponIdList > 0 and 1 or -1)
    self:PlayAnimation("LeftQieHuan")
end

-- 把当前使用的装备移动到第一个位置
function XUiEquipReplaceV2P6:MoveUsingWeaponInFirst()
    local usingEquipId
    for index, equipId in pairs(self.WeaponIdList) do
        if equipId == self.UsingEquipId then
            usingEquipId = table.remove(self.WeaponIdList, index)
        end
    end
    if usingEquipId then
        table.insert(self.WeaponIdList, 1, usingEquipId)
    end
end

function XUiEquipReplaceV2P6:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local equipId = self.WeaponIdList[index]
        grid:Refresh(equipId)

        local isSelected = equipId == self.SelectEquipId
        grid:SetSelected(isSelected)
        if isSelected then
            self.LastSelectGrid = grid
        end
        grid.Transform:Find("Effect").gameObject:SetActiveEx(false)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.SelectEquipId = self.WeaponIdList[index]
        self:UpdateEquipDetail()
        if self.LastSelectGrid then
            self.LastSelectGrid:SetSelected(false)
        end
        self.LastSelectGrid = grid
        self.LastSelectGrid:SetSelected(true)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        XEventManager.DispatchEvent(XEventId.EVENT_GUIDE_STEP_OPEN_EVENT)
    end
end

function XUiEquipReplaceV2P6:GuideGetDynamicTableIndex(id)
    for i, v in ipairs(self.WeaponIdList) do
        local equip = XDataCenter.EquipManager.GetEquip(v)
        if tostring(equip.TemplateId) == id then
            return i
        end
    end

    return -1
end

-- 刷新界面
function XUiEquipReplaceV2P6:UpdateView()
    self.WeaponIdList = XDataCenter.EquipManager.GetCanUseWeaponIds(self.CharacterId)
    self:OnSortTypeChange()
    self:UpdateEquipDetail()
end

-- 刷新装备详情
function XUiEquipReplaceV2P6:UpdateEquipDetail()
    local templateId = XMVCA:GetAgency(ModuleId.XEquip):GetEquipTemplateId(self.SelectEquipId)
    self.TxtEquipName.text = XMVCA:GetAgency(ModuleId.XEquip):GetEquipName(templateId)
    self:UpdateEquipAttr()
    self:UpdateEquipSkillDesc()
    self:UpdateEquipResonance()
    self:UpdateOverrun()
    self:UpdateBtnState()

    -- 刷新技能和能力扩展栏状态
    local isShow = self.PaneEquipResonance.gameObject.activeSelf or self.PaneOverrun.gameObject.activeSelf
    self.PanelExtendTitle.gameObject:SetActiveEx(isShow)
    if isShow then
        self:UpdateExtendName()
    end
    if not isShow and self.IsShowExtend then
        self:ShowPanelSkill()
    end
end

-- 刷新装备属性
function XUiEquipReplaceV2P6:UpdateEquipAttr()
    -- 当前穿戴装备属性
    local showCurAttr = self.UsingEquipId ~= self.SelectEquipId
    local curAttrMap = showCurAttr and XMVCA:GetAgency(ModuleId.XEquip):GetEquipAttrMap(self.UsingEquipId) or {}

    -- 选择装备属性
    local attrMap = XMVCA:GetAgency(ModuleId.XEquip):GetEquipAttrMap(self.SelectEquipId)
    for i = 1, XEnumConst.EQUIP.MAX_ATTR_COUNT do
        local curAttrInfo = curAttrMap[i]
        local attrInfo = attrMap[i]
        local isShow = attrInfo ~= nil
        self["PanelAttr" .. i].gameObject:SetActiveEx(isShow)
        if isShow then
            self["TxtName" .. i].text = attrInfo.Name
            self["TxtCurAttr" .. i].text = showCurAttr and curAttrInfo.Value or ""
            self["ImgArrow" .. i].gameObject:SetActiveEx(showCurAttr)
            self["TxtAttr" .. i].text = attrInfo.Value

            local color = ATTR_COLOR.EQUAL
            if showCurAttr then
                if attrInfo.Value > curAttrInfo.Value then
                    color = ATTR_COLOR.OVER
                elseif attrInfo.Value < curAttrInfo.Value then
                    color = ATTR_COLOR.BELOW
                end
            end
            self["TxtAttr" .. i].color = color
        end
    end
end

-- 刷新技能详情
function XUiEquipReplaceV2P6:UpdateEquipSkillDesc()
    local templateId = XMVCA:GetAgency(ModuleId.XEquip):GetEquipTemplateId(self.SelectEquipId)
    local weaponSkillInfo = XDataCenter.EquipManager.GetOriginWeaponSkillInfo(templateId)
    self.TxtSkillName.text = weaponSkillInfo.Name
    self.TxtSkillDes.text = weaponSkillInfo.Description

    local noWeaponSkill = not weaponSkillInfo.Name and not weaponSkillInfo.Description
    self.PanelAwarenessSkillDes.gameObject:SetActiveEx(false)
    self.PanelNoAwarenessSkill.gameObject:SetActiveEx(false)
    self.PanelWeaponSkillDes.gameObject:SetActiveEx(not noWeaponSkill)
    self.PanelNoWeaponSkill.gameObject:SetActiveEx(noWeaponSkill)
end

-- 刷新装备共鸣
function XUiEquipReplaceV2P6:UpdateEquipResonance()
    local templateId = XMVCA:GetAgency(ModuleId.XEquip):GetEquipTemplateId(self.SelectEquipId)
    local canResonance = XDataCenter.EquipManager.CanResonanceByTemplateId(templateId)
    self.PaneEquipResonance.gameObject:SetActive(canResonance)
    if not canResonance then
        return
    end

    for pos = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
        self:UpdateEquipResonanceSkill(pos)
    end
end

-- 刷新单个装备共鸣
function XUiEquipReplaceV2P6:UpdateEquipResonanceSkill(pos)
    local isEquip = XDataCenter.EquipManager.CheckEquipPosResonanced(self.SelectEquipId, pos) ~= nil
    local uiObj = self["GridEquipResonance" .. pos]
    uiObj:GetComponent("XUiButton"):SetDisable(not isEquip)
    self["GridEquipResonanceEffect"..pos].gameObject:SetActiveEx(false)
    if isEquip then
        if not self.ResonanceSkillDic then 
            self.ResonanceSkillDic = {} 
        end

        -- 按钮每个状态对应创建一个XUiGridResonanceSkill
        local stateNameList = {"Normal", "Press"}
        if not self.ResonanceSkillDic[pos] then 
            self.ResonanceSkillDic[pos] = {}
            for _, stateName in ipairs(stateNameList) do
                local stateGo = uiObj:GetObject(stateName)
                self.ResonanceSkillDic[pos][stateName] = XUiGridResonanceSkill.New(stateGo, self.SelectEquipId, pos, self.CharacterId, function()
                    self:OnBtnResonanceSkill(pos)
                end, nil, self.ForceShowBindCharacter)
            end
        end
        
        -- 刷新所有状态的XUiGridResonanceSkill
        for _, stateName in ipairs(stateNameList) do
            local grid = self.ResonanceSkillDic[pos][stateName]
            grid:SetEquipIdAndPos(self.SelectEquipId, pos)
            grid:Refresh()
        end
    end
end

-- 刷新武器超限
function XUiEquipReplaceV2P6:UpdateOverrun()
    self.OverrunIconTips = nil
    local templateId = XMVCA:GetAgency(ModuleId.XEquip):GetEquipTemplateId(self.SelectEquipId)
    self.CanOverrun = self._Control:CanOverrunByTemplateId(templateId)
    self.PaneOverrun.gameObject:SetActiveEx(self.CanOverrun)
    if not self.CanOverrun then 
        return
    end

    local equip = XDataCenter.EquipManager.GetEquip(self.SelectEquipId)
    local lv = equip:GetOverrunLevel()
    local btnName = XUiHelper.GetText("EquipOverrun")
    if lv > 0 then
        btnName = self._Control:GetWeaponDeregulateUIName(lv)
    elseif not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipOverrun) then
        btnName = XUiHelper.GetText("EquipOverrunUnlockTips")
    end
    self.BtnOverrun:SetName(btnName)

    self.BtnOverrunBlind.gameObject:SetActiveEx(false)
    self.BtnOverrunEmpty.gameObject:SetActiveEx(false)

    -- 未解锁
    local canBind = equip:IsOverrunCanBlindSuit()
    if not canBind then
        self.BtnOverrunBlind.gameObject:SetActiveEx(true)
        self.BtnOverrunBlind:SetDisable(true)
        self.OverrunIconTips = XUiHelper.GetText("EquipOverrunClickTips")
        return 
    end

    -- 解锁未绑定
    local choseSuitId = equip:GetOverrunChoseSuit()
    local isChoose = choseSuitId ~= 0
    if not isChoose then 
        self.BtnOverrunEmpty.gameObject:SetActiveEx(true)
        return
    end

    -- 解锁并且有绑定
    self.BtnOverrunBlind.gameObject:SetActiveEx(true)
    self.BtnOverrunBlind:SetDisable(false)
    local stateList = { "Normal", "Press"}
    local iconPath = XMVCA:GetAgency(ModuleId.XEquip):GetEquipSuitIconPath(choseSuitId)
    local isMatch = equip:IsOverrunBlindMatch(self.CharacterId)
    local uiObj = self.BtnOverrunBlind:GetComponent("UiObject")
    for _, stateName in ipairs(stateList) do
        local stateObj = uiObj:GetObject(stateName)
        stateObj:GetObject("RImgSuit"):SetRawImage(iconPath)
        stateObj:GetObject("ImgNotMatching").gameObject:SetActiveEx(not isMatch)
    end
    self.OverrunBlindEffect.gameObject:SetActiveEx(false)
end

-- 刷新按钮状态
function XUiEquipReplaceV2P6:UpdateBtnState()
    -- 培养按钮
    self.BtnStrengthen.gameObject:SetActive(not self.NotShowStrengthenBtn)

    -- 当前/装备 按钮
    local isEquip = self.UsingEquipId == self.SelectEquipId
    self.BtnTakeOn.gameObject:SetActive(not isEquip)
    self.ImgEquipOn.gameObject:SetActive(isEquip)
end

-- 刷新扩展按钮名称
function XUiEquipReplaceV2P6:UpdateExtendName()
    local nameKey = self.CanOverrun and "EquipWeaponBtnName" or "EquipResonanceName"
    local btnName = XUiHelper.GetText(nameKey)
    self.PanelAdd2:SetName(btnName)
    self.TxtExtendTitleNormal.text = btnName
end

-- 显示技能面板
function XUiEquipReplaceV2P6:ShowPanelSkill()
    self.IsShowExtend = false
    self:PlayAnimation("AnimUnFold")
    self.PanelAddEffect.gameObject:SetActiveEx(false)
    self.PanelAdd2Effect.gameObject:SetActiveEx(true)
    self.GridEquipResonanceEffect1.gameObject:SetActiveEx(false)
    self.GridEquipResonanceEffect2.gameObject:SetActiveEx(false)
    self.GridEquipResonanceEffect3.gameObject:SetActiveEx(false)
    self.OverrunBlindEffect.gameObject:SetActiveEx(false)
end

-- 显示扩展面板
function XUiEquipReplaceV2P6:ShowPanelExtend()
    self.IsShowExtend = true
    self:PlayAnimation("AnimFold")
    self.PanelAddEffect.gameObject:SetActiveEx(true)
    self.PanelAdd2Effect.gameObject:SetActiveEx(false)
end

return XUiEquipReplaceV2P6
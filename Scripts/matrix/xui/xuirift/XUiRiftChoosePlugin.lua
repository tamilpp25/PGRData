--大秘境角色插件选择
local XUiRiftChoosePlugin = XLuaUiManager.Register(XLuaUi, "UiRiftChoosePlugin")
local XUiRiftPluginAdditonGrid = require("XUi/XUiRift/Grid/XUiRiftPluginAdditonGrid")
local XUiRiftPluginEffectiveGrid = require("XUi/XUiRift/Grid/XUiRiftPluginEffectiveGrid")
local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")

local IsEffectTrigger = nil
local ToggleSelectKey = "ToggleSelectKey"
local DynamicTableType =  -- 用来判断刷新时动态列表是哪个类型的
{
    Addition = 1,
    Effective = 2,
    Bag = 3,
}

function XUiRiftChoosePlugin:OnAwake()
    self.CurrAddEffSeleIndex = nil -- 当前右边列表点击选中的插件index
    self.AttrGameObjDic = {}
    self.StarSelectList = {true, true, true, true, true, true}
    self:InitButton()
    self:InitToggleList()
    self:InitDynamicTable()
    self:InitTimes()
end

function XUiRiftChoosePlugin:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, "RiftPluginHelp")
    XUiHelper.RegisterClickEvent(self, self.BtnTeamAttribute, self.OnBtnTeamAttributeClick)
    XUiHelper.RegisterClickEvent(self, self.BtnUnwear, self.OnBtnUnwearClick)
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnClosePopup, function() self.PanelPlugin.gameObject:SetActiveEx(false) end)
    XUiHelper.RegisterClickEvent(self, self.PanelPluginScrollList, function() self.PanelPlugin.gameObject:SetActiveEx(false) end)
    XUiHelper.RegisterClickEvent(self, self.PanelEffectiveList, function() self.PanelPlugin.gameObject:SetActiveEx(false) end)
    XUiHelper.RegisterClickEvent(self, self.PanelAdditionList, function() self.PanelPlugin.gameObject:SetActiveEx(false) end)
    -- 右边的单选按钮
    local tabBtns = { self.BtnEffective, self.BtnAddition }
    self.PanelTabBtns:Init(tabBtns, function(index) self:OnselectPluginAE(index) end)

    -- 左边的筛选框
    XUiHelper.RegisterClickEvent(self, self.TogCurrRole, self.RefreshDynamicTableBag)
    XUiHelper.RegisterClickEvent(self, self.TogStar3, self.OnTogStar3Click)
    XUiHelper.RegisterClickEvent(self, self.TogStar4, self.OnTogStar4Click)
    XUiHelper.RegisterClickEvent(self, self.TogStar5, self.OnTogStar5Click)
    XUiHelper.RegisterClickEvent(self, self.TogStar6, self.OnTogStar6Click)
end

function XUiRiftChoosePlugin:InitToggleList()
    self.StarSelectList = {true, true, true, true, true, true}
    for index, isSelect in ipairs(self.StarSelectList) do
        local tog = self["TogStar" .. index]
        if tog then
            local state = isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal
            tog:SetButtonState(state)
        end
    end
    self.BtnIsShowPlugin:SetButtonState(CS.UiButtonState.Select)

    -- 缓存的toggle信息
    local isShow = XSaveTool.GetData(ToggleSelectKey)
    if isShow then
        self.TogCurrRole:SetButtonState(CS.UiButtonState.Select)
    else
        self.TogCurrRole:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiRiftChoosePlugin:OnTogStar3Click()
    local isOn = self.TogStar3:GetToggleState()
    self.StarSelectList[1] = isOn
    self.StarSelectList[2] = isOn
    self.StarSelectList[3] = isOn
    self:RefreshDynamicTableBag()
end

function XUiRiftChoosePlugin:OnTogStar4Click()
    local isOn = self.TogStar4:GetToggleState()
    self.StarSelectList[4] = isOn
    self:RefreshDynamicTableBag()
end

function XUiRiftChoosePlugin:OnTogStar5Click()
    local isOn = self.TogStar5:GetToggleState()
    self.StarSelectList[5] = isOn
    self:RefreshDynamicTableBag()
end

function XUiRiftChoosePlugin:OnTogStar6Click()
    local isOn = self.TogStar6:GetToggleState()
    self.StarSelectList[6] = isOn
    self:RefreshDynamicTableBag()
end

function XUiRiftChoosePlugin:OnselectPluginAE(index)
    self.Transform:Find("Animation/QieHuan"):PlayTimelineAnimation()
    if index == DynamicTableType.Addition then
        self.PanelAdditionList.gameObject:SetActiveEx(true)
        self.PanelEffectiveList.gameObject:SetActiveEx(false)
    elseif index == DynamicTableType.Effective then
        self.PanelAdditionList.gameObject:SetActiveEx(false)
        self.PanelEffectiveList.gameObject:SetActiveEx(true)
    end
    self:RefeshDynamicTableByClickAddOrEff()
end

-- 初始化三个动态列表
function XUiRiftChoosePlugin:InitDynamicTable()
    -- 已装备插件效果列表
    self.DynamicTableAddition = XDynamicTableNormal.New(self.PanelAdditionList)
    self.DynamicTableAddition:SetProxy(XUiRiftPluginAdditonGrid)
    self.DynamicTableAddition:SetDelegate(self)
    self.DynamicTableAddition:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicTableEvent(event, index, grid, DynamicTableType.Addition)
    end)
    -- 已装备插件描述列表
    self.DynamicTableEffective = XDynamicTableNormal.New(self.PanelEffectiveList)
    self.DynamicTableEffective:SetProxy(XUiRiftPluginEffectiveGrid)
    self.DynamicTableEffective:SetDelegate(self)
    self.DynamicTableEffective:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicTableEvent(event, index, grid, DynamicTableType.Effective)
    end)
    -- 已拥有插件列表背包
    self.DynamicTableBag = XDynamicTableNormal.New(self.PanelPluginScrollList)
    self.DynamicTableBag:SetProxy(XUiRiftPluginGrid)
    self.DynamicTableBag:SetDelegate(self)
    self.DynamicTableBag:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicTableEvent(event, index, grid, DynamicTableType.Bag)
    end)
end

function XUiRiftChoosePlugin:OnStart(xRole)
    self.XRole = xRole
end

function XUiRiftChoosePlugin:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshDynamicTableAddition()
    self:RefreshDynamicTableEffective()
    self:RefreshDynamicTableBag()
    self:RefreshUiShow()
    self.PanelTabBtns:SelectIndex(DynamicTableType.Effective)
end

function XUiRiftChoosePlugin:RefreshUiShow()
    -- 负载信息
    self.TxtLoadNum.text = CS.XTextManager.GetText("RiftPluginLoad", self.XRole:GetCurrentLoad(), XDataCenter.RiftManager.GetMaxLoad())
    self.ImgLoadProgress.fillAmount = self.XRole:GetCurrentLoad() / XDataCenter.RiftManager.GetMaxLoad()
    -- 加点信息
    local defaultTemp = XDataCenter.RiftManager.GetAttrTemplate()
    local allAttr =  XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftTeamAttribute)
    for i, cfg in pairs(allAttr) do
        local go = self.AttrGameObjDic[i]
        if not go then
            go = CS.UnityEngine.Object.Instantiate(self.PanelAttribute, self.PanelAttribute.parent)
        end
        local v = defaultTemp:GetAttrLevel(i)
        go.transform:Find("TxtAttributeName"):GetComponent("Text").text = cfg.Name
        go.transform:Find("TxtAttributeLevel"):GetComponent("Text").text = v
    end
    self.PanelAttribute.gameObject:SetActiveEx(false)

    self.BtnTeamAttribute:SetNameByGroup(0, defaultTemp:GetAllLevel())

    local isUnlock = XDataCenter.RiftManager.IsFuncUnlock(XRiftConfig.FuncUnlockId.Attribute)
    self.BtnTeamAttribute.transform.parent.gameObject:SetActiveEx(isUnlock)
end

function XUiRiftChoosePlugin:RefreshPluginTipDetail(xPlugin)
    -- 插件详情弹窗
    if self.TipsPluginGrid == nil then
        self.TipsPluginGrid = XUiRiftPluginGrid.New(self.GridRiftPluginTips:GetObject("GridRiftPlugin"))
    end
    self.TipsPluginGrid:Refresh(xPlugin)
    self.GridRiftPluginTips:GetObject("TxtPluginName").text = xPlugin:GetName()
    self.GridRiftPluginTips:GetObject("TxtCoreExplain").text = xPlugin:GetDesc()

    -- 补正属性
    local fixTypeList = xPlugin:GetAttrFixTypeList()
    for i = 1, XRiftConfig.PluginMaxFixCnt do
        local isShow = #fixTypeList >= i
        self.GridRiftPluginTips:GetObject("PanelAddition" .. i).gameObject:SetActiveEx(isShow)
        if isShow then
            self.GridRiftPluginTips:GetObject("TxtAddition" .. i).text = fixTypeList[i]
        end
    end
 
    -- 补正效果
    local attrFixList = xPlugin:GetEffectStringList()
    for i = 1, XRiftConfig.PluginMaxFixCnt do
        local isShow = #attrFixList >= i
        self.GridRiftPluginTips:GetObject("PanelEntry" .. i).gameObject:SetActiveEx(isShow)
        if isShow then
            local attrFix = attrFixList[i]
            self.GridRiftPluginTips:GetObject("TxtEntry" .. i).text = attrFix.Name
            self.GridRiftPluginTips:GetObject("TxtEntryNum" .. i).text = attrFix.ValueString
        end
    end

    -- 效果描述
    self.GridRiftPluginTips:GetObject("TxtPluginExplain").text = xPlugin:GetDesc()
end

function XUiRiftChoosePlugin:RefreshDynamicTableAddition(index)
    self.RolePlugins = self.XRole:GetPlugIns()
    local isEmpty = XTool.IsTableEmpty(self.RolePlugins)
    self.PanelNoPlugin1.gameObject:SetActiveEx(isEmpty)
    self.PanelNoPlugin2.gameObject:SetActiveEx(isEmpty)
    
    self.DynamicTableAddition:SetDataSource(self.RolePlugins)
    self.DynamicTableAddition:ReloadDataSync(index or 1)
end

function XUiRiftChoosePlugin:RefreshDynamicTableEffective(index)
    self.RolePlugins = self.XRole:GetPlugIns()
    self.DynamicTableEffective:SetDataSource(self.RolePlugins)
    self.DynamicTableEffective:ReloadDataSync(index or 1)
end

function XUiRiftChoosePlugin:RefreshDynamicTableBag()
    self.BagPluginList = XDataCenter.RiftManager.GetOwnPluginList(self.StarSelectList)
    
    local isFilter = self.TogCurrRole:GetToggleState()
    if isFilter then
        local filterRes = {}
        for k, xPlugin in ipairs(self.BagPluginList) do
            if not xPlugin:CheckCharacterWearLimit(self.XRole:GetCharacterId()) then
                table.insert(filterRes, xPlugin)
            end
        end
        self.BagPluginList = filterRes
    end

    self.PanelNoPluginBag.gameObject:SetActiveEx(XTool.IsTableEmpty(self.BagPluginList))
    self.DynamicTableBag:SetDataSource(self.BagPluginList)
    self.DynamicTableBag:ReloadDataSync(1)
end

function XUiRiftChoosePlugin:AutoPosIndexInBagListByRightGrid(additonGrid)
    local index = 1
    for k, xPlugin in pairs(self.BagPluginList) do
        if xPlugin == additonGrid.XPlugin then
            index = k
            IsEffectTrigger = additonGrid.XPlugin
            break
        end
    end
    self.DynamicTableBag:SetDataSource(self.BagPluginList)
    self.DynamicTableBag:ReloadDataSync(index)
end

function XUiRiftChoosePlugin:OnDynamicTableEvent(event, index, grid, dynamicTableType)
    if dynamicTableType == DynamicTableType.Addition then
        -- Addition 
        if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
            grid:Refresh(self.RolePlugins[index])
            local isSelect = self.CurrAddEffSeleIndex == index
            if isSelect then
                self.CurAddGrid = grid
                grid.Btn:SetButtonState(CS.UiButtonState.Select)
            else
                grid.Btn:SetButtonState(CS.UiButtonState.Normal)
            end

        elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
            if self.CurAddGrid then
                self.CurAddGrid.Btn:SetButtonState(CS.UiButtonState.Normal)
            end
            grid.Btn:SetButtonState(CS.UiButtonState.Select)
            self.CurrAddEffSeleIndex = index
            self.CurAddGrid = grid

            self:AutoPosIndexInBagListByRightGrid(grid)
        end
    elseif dynamicTableType == DynamicTableType.Effective then
        -- Effective
        if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
            grid:Refresh(self.RolePlugins[index])
            local isSelect = self.CurrAddEffSeleIndex == index
            if isSelect then
                grid.Btn:SetButtonState(CS.UiButtonState.Select)
                self.CurEffGrid = grid
            else
                grid.Btn:SetButtonState(CS.UiButtonState.Normal)
            end
        elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
            if self.CurEffGrid then
                self.CurEffGrid.Btn:SetButtonState(CS.UiButtonState.Normal)
            end
            grid.Btn:SetButtonState(CS.UiButtonState.Select)
            self.CurrAddEffSeleIndex = index
            self.CurEffGrid = grid

            self:AutoPosIndexInBagListByRightGrid(grid)
        end
    elseif dynamicTableType == DynamicTableType.Bag  then
        -- Bag
        if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
            local xPlugin = self.BagPluginList[index]
            local isWear = self.XRole:CheckHasPlugin(xPlugin:GetId())
            grid:Refresh(xPlugin)
            local isEffect = self:CheckEffectTrigger(xPlugin)
            grid.Effct.gameObject:SetActiveEx(false)
            if isEffect then
                grid.Effct.gameObject:SetActiveEx(true)
            end
            grid:SetIsWear(isWear)
            -- 有负载或类型限制，则ban
            local isBan = (self.XRole:CheckLoadLimitAddPlugin(xPlugin:GetId()) or xPlugin:CheckCurPluginTypeLimit(self.XRole)) and not isWear
            grid:SetBan(isBan)
            grid:Init(function ()
                self:OnBagPluginClick(grid)
            end)
        end
    end
end

-- 装备插件后的背包刷新(只刷新格子状态 不刷新位置)
function XUiRiftChoosePlugin:RefeshDynamicTableByWear()
    for k, grid in pairs(self.DynamicTableBag:GetGrids()) do
        local xPlugin = grid.XPlugin
        local isWear = self.XRole:CheckHasPlugin(xPlugin:GetId())
        grid:Refresh(xPlugin)
        grid:SetIsWear(isWear)
        -- 有负载或类型限制，则ban
        local isBan = (self.XRole:CheckLoadLimitAddPlugin(xPlugin:GetId()) or xPlugin:CheckCurPluginTypeLimit(self.XRole)) and not isWear
        grid:SetBan(isBan)
    end
end

-- 点击右边动态列表的刷新
function XUiRiftChoosePlugin:RefeshDynamicTableByClickAddOrEff()
    for index, grid in pairs(self.DynamicTableAddition:GetGrids()) do
        local xPlugin = self.RolePlugins[index]
        if xPlugin then
            grid:Refresh(xPlugin)
            local isSelect = self.CurrAddEffSeleIndex == index
            if isSelect then
                self.CurAddGrid = grid
                grid.Btn:SetButtonState(CS.UiButtonState.Select)
            else
                grid.Btn:SetButtonState(CS.UiButtonState.Normal)
            end
        end
    end

    for index, grid in pairs(self.DynamicTableEffective:GetGrids()) do
        local xPlugin = self.RolePlugins[index]
        if xPlugin then
            grid:Refresh(self.RolePlugins[index])
            local isSelect = self.CurrAddEffSeleIndex == index
            if isSelect then
                self.CurEffGrid = grid
                grid.Btn:SetButtonState(CS.UiButtonState.Select)
            else
                grid.Btn:SetButtonState(CS.UiButtonState.Normal)
            end
        end
    end
end

function XUiRiftChoosePlugin:OnBagPluginClick(gridPlugin)
    local xPlugin = gridPlugin.XPlugin
    -- 弹出详情
    if self.BtnIsShowPlugin:GetToggleState() then
        self:RefreshPluginTipDetail(xPlugin)
        self.PanelPlugin.gameObject:SetActiveEx(true)
    end

    local pluginId = xPlugin:GetId()
    local pluginList = self.XRole:GetPlugInIdList()
    local res, index = table.contains(pluginList, pluginId)
    local afterChangePluginList = XTool.Clone(pluginList)
    -- 没有插件就装备，有就卸下
    if res then
        -- 卸下插件
        table.remove(afterChangePluginList, index)
        if index == self.CurrAddEffSeleIndex then
            self.CurrAddEffSeleIndex = nil -- 删除了选中状态的插件 要移除选中格子
        end
    else
        -- 装备上插件
        -- 插件角色限制检测
        if xPlugin:CheckCharacterWearLimit(self.XRole:GetCharacterId()) then
            XUiManager.TipError(CS.XTextManager.GetText("RiftPluginCharLimit"))
            return
        end

        -- 插件负载上限检测
        if self.XRole:CheckLoadLimitAddPlugin(pluginId) then 
            XUiManager.TipError(CS.XTextManager.GetText("RiftPluginLoadNoneLeft"))
            return
        end
        
        -- 插件类型穿戴限制检测
        if xPlugin:CheckCurPluginTypeLimit(self.XRole) then
            XUiManager.TipError(CS.XTextManager.GetText("RiftPluginTypeLimit"))
            return
        end
        -- 装备上插件
        table.insert(afterChangePluginList, pluginId)
    end

    XDataCenter.RiftManager.RiftSetCharacterPluginsRequest(self.XRole, afterChangePluginList, function ()
        gridPlugin:SetIsWear(not res)
        self:RefreshDynamicTableAddition(index or #afterChangePluginList) -- 右边的动态列表为了保持刷新后不变位置，重新定位到装备前的位置
        self:RefreshDynamicTableEffective(index or #afterChangePluginList)
        self:RefeshDynamicTableByWear() 
        self:RefreshUiShow()
    end)
end

function XUiRiftChoosePlugin:OnBtnTeamAttributeClick()
    local isUnlock = XDataCenter.RiftManager.IsFuncUnlock(XRiftConfig.FuncUnlockId.Attribute)
    if isUnlock then
        XLuaUiManager.Open("UiRiftAttribute")
    end
end

-- 卸下指定插件
function XUiRiftChoosePlugin:OnBtnUnwearClick()
    local pluginList = self.XRole:GetPlugInIdList()

    if XTool.IsTableEmpty(pluginList) then
        return
    end
    
    if not self.CurrAddEffSeleIndex or self.CurrAddEffSeleIndex > #pluginList then
        return
    end

    local afterChangePluginList = XTool.Clone(pluginList)
    table.remove(afterChangePluginList, self.CurrAddEffSeleIndex)

    XDataCenter.RiftManager.RiftSetCharacterPluginsRequest(self.XRole, afterChangePluginList, function ()
        local refreshIndex = self.CurrAddEffSeleIndex > #afterChangePluginList and #afterChangePluginList or self.CurrAddEffSeleIndex 
        self:RefreshDynamicTableAddition(refreshIndex)
        self:RefreshDynamicTableEffective(refreshIndex)
        self:RefeshDynamicTableByWear()
        self:RefreshUiShow()
    end)
end

function XUiRiftChoosePlugin:OnDestroy()
    XSaveTool.SaveData(ToggleSelectKey, self.TogCurrRole:GetToggleState())
end

function XUiRiftChoosePlugin:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.RiftManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

function XUiRiftChoosePlugin:CheckEffectTrigger(targetPlayEffectPlugin)
    if IsEffectTrigger == targetPlayEffectPlugin then
        IsEffectTrigger = false
        return true
    end
end

return XUiRiftChoosePlugin
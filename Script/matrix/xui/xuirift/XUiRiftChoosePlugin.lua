local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiRiftChoosePlugin : XLuaUi
---@field _Control XRiftControl
local XUiRiftChoosePlugin = XLuaUiManager.Register(XLuaUi, "UiRiftChoosePlugin")

local DynamicTableType = { All = 1, Own = 2 }

function XUiRiftChoosePlugin:OnAwake()
    ---@type XCharacterAgency
    self.CharacterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    self.BtnBack.CallBack = handler(self, self.Close)
    self.BtnConfirm.CallBack = handler(self, self.Close)
    self.BtnMainUi.CallBack = handler(self, self.OnClickMain)
    self.BtnShaixuan.CallBack = handler(self, self.OnClickFilter)
    self.BtnToggle.CallBack = handler(self, self.OnClickToggle)
    self.BtnUnwear.CallBack = handler(self, self.ReqUnwearPlugin)
    self.BtnRecommend.CallBack = handler(self, self.OnClickRecommend)
    self:BindHelpBtn(self.BtnHelp, "RiftPluginHelp")
end

function XUiRiftChoosePlugin:OnStart(role)
    ---@type XBaseRole
    self._Role = role
    self._CurPluginId = nil
    ---@type XUiRiftPluginEffectiveGrid
    self._CurSelectGrid = nil
    self._ClickRecordTime = 0
    self:InitCompnent()
    self:InitFilter()
    self:RefreshBtnToggle()
    self:RefreshUIShow()
    self:RefreshOwnPluginList()
    self.BtnUnwear.gameObject:SetActiveEx(false)
    self._Control:SetCharacterRedPoint(false)
end

function XUiRiftChoosePlugin:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_RIFT_DATA_UPDATE, self.RefreshGrids, self)
    XEventManager.AddEventListener(XEventId.EVENT_RIFT_PLUGIN_AFFIX_UPDATE, self.RefreshGrids, self)
    XEventManager.AddEventListener(XEventId.EVENT_RIFT_PLUGIN_GUIDE, self.OnPluginGuide, self)
end

function XUiRiftChoosePlugin:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_RIFT_DATA_UPDATE, self.RefreshGrids, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RIFT_PLUGIN_AFFIX_UPDATE, self.RefreshGrids, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RIFT_PLUGIN_GUIDE, self.OnPluginGuide, self)
end

function XUiRiftChoosePlugin:InitCompnent()
    self.ImgRole:SetRawImage(self.CharacterAgency:GetCharSmallHeadIcon(self._Role:GetCharacterId()))
    ---@type XDynamicTableNormal
    self.DynamicAllTable = XDynamicTableNormal.New(self.PanelPluginScrollList)
    self.DynamicAllTable:SetProxy(require("XUi/XUiRift/Grid/XUiRiftPluginEffectiveGrid"), self)
    self.DynamicAllTable:SetDelegate(self)
    self.DynamicAllTable:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicAllTableEvent(event, index, grid)
    end)
    ---@type XDynamicTableNormal
    self.DynamicOwnTable = XDynamicTableNormal.New(self.PanelEffectiveList)
    self.DynamicOwnTable:SetProxy(require("XUi/XUiRift/Grid/XUiRiftPluginEffectiveGrid"), self)
    self.DynamicOwnTable:SetDelegate(self)
    self.DynamicOwnTable:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicOwnTableEvent(event, index, grid)
    end)

    local ItemIds = { XDataCenter.ItemManager.ItemId.RiftGold, XDataCenter.ItemManager.ItemId.RiftCoin }
    XUiHelper.NewPanelActivityAssetSafe(ItemIds, self.PanelSpecialTool, self)

    self.GridAll.gameObject:SetActiveEx(false)
    self.GridOwn.gameObject:SetActiveEx(false)
end

function XUiRiftChoosePlugin:InitFilter()
    local btnTabs = { self.BtnAll }
    local datas = XEnumConst.Rift.StarFilter
    XUiHelper.RefreshCustomizedList(self.BtnStar.transform.parent, self.BtnStar, #datas, function(index, go)
        local title = XUiHelper.GetText("RiftPluginFilterTagName", datas[index])
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.BtnStar:SetNameByGroup(0, title)
        table.insert(btnTabs, uiObject.BtnStar)
    end, true)
    self.PanelTabBtn:Init(btnTabs, function(index)
        local setting = self._Control:GetFilterSertting(XEnumConst.Rift.FilterSetting.PluginChoose)
        setting[XEnumConst.Rift.Filter.Star] = {}
        if index == 1 then
            -- 选中‘全部’
            for _, star in pairs(datas) do
                setting[XEnumConst.Rift.Filter.Star][star] = true
            end
        else
            setting[XEnumConst.Rift.Filter.Star][datas[index - 1]] = true
        end
        self._Control:SaveFilterSertting(XEnumConst.Rift.FilterSetting.PluginChoose, setting)
        self:RefreshAllPluginList()
    end)
    self.BtnStar.gameObject:SetActiveEx(false)
    self.PanelTabBtn:SelectIndex(1)
end

---@param grid XUiRiftPluginEffectiveGrid
function XUiRiftChoosePlugin:OnDynamicAllTableEvent(event, index, grid)
    local data = self.DynamicAllTable:GetData(index)
    if not grid or not data then
        return
    end
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        self:SetGrid(grid, data, DynamicTableType.All)
        grid.GameObject.name = data.Id
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        -- 点击直接穿戴/卸下
        local realTime = CS.XTimerManager.GetRealTime()
        if realTime - self._ClickRecordTime <= 0.3 then
            return
        end
        self:DoSelect(nil)
        self:ReqWearPlugin(data)
        self._ClickRecordTime = realTime
    end
end

---@param grid XUiRiftPluginEffectiveGrid
function XUiRiftChoosePlugin:OnDynamicOwnTableEvent(event, index, grid)
    local data = self.DynamicOwnTable:GetData(index)
    if not grid or not data then
        return
    end
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local plugin = self._Control:GetPlugin(data)
        self:SetGrid(grid, plugin, DynamicTableType.Own)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        -- 点击选中，点击按钮才能卸下
        local plugin = self._Control:GetPlugin(data)
        self:DoSelect(plugin)
    end
end

function XUiRiftChoosePlugin:RefreshUIShow()
    local cur = self._Control:GetCurrentLoad(self._Role)
    local total = self._Control:GetMaxLoad()
    self.TxtLoadNum.text = XUiHelper.GetText("RiftPluginLoad", cur, total)
    self.ImgLoadProgress.fillAmount = cur / total
end

function XUiRiftChoosePlugin:RefreshAllPluginList()
    local roleElement = self.CharacterAgency:GetCharacterElement(self._Role:GetCharacterId())
    local bagPluginList = self._Control:GetOwnPluginList(roleElement, self._Role:GetCharacterId())
    table.sort(bagPluginList, handler(self, self.SortBagList))

    self.DynamicAllTable:SetDataSource(bagPluginList)
    self.DynamicAllTable:ReloadDataASync(1)
    self.PanelNoPluginBag.gameObject:SetActiveEx(XTool.IsTableEmpty(bagPluginList))
end

--region 排序

---@param a XTableRiftPlugin
---@param b XTableRiftPlugin
function XUiRiftChoosePlugin:SortBagList(a, b)
    -- 当前专属>通用>非当前专属
    local aFirstSort = self:GetFirstSort(a)
    local bFirstSort = self:GetFirstSort(b)
    if aFirstSort ~= bFirstSort then
        return aFirstSort < bFirstSort
    end
    -- 暗金>非暗金
    local isASpecial = self._Control:IsPluginSpecialQuality(a.Quality)
    local isBSpecial = self._Control:IsPluginSpecialQuality(b.Quality)
    if isASpecial ~= isBSpecial then
        return isASpecial == true
    end
    -- 角色2S时 其他插件>升阶插件
    local isAUp = self:GetThirdSort(a)
    local isBUp = self:GetThirdSort(a)
    if isAUp ~= isBUp then
        return isAUp < isBUp
    end
    -- 星级
    local aStar = a.Star
    local bStar = b.Star
    if aStar ~= bStar then
        return aStar > bStar
    end
    -- 排序字段
    local aSort = a.Sort
    local bSort = b.Sort
    if aSort ~= bSort then
        return aSort < bSort
    end
    -- Id
    return a.Id < b.Id
end

---@param plugin XTableRiftPlugin
function XUiRiftChoosePlugin:GetFirstSort(plugin)
    if plugin.CharacterId == self._Role:GetCharacterId() then
        return 1
    elseif not XTool.IsNumberValid(plugin.CharacterId) then
        return 2
    else
        return 3
    end
end

---@param plugin XTableRiftPlugin
function XUiRiftChoosePlugin:GetThirdSort(plugin)
    --1  2  3  4   5    6
    --B  A  S  SS  SSS  SSS+
    local isSS = self.CharacterAgency:GetCharacterQuality(self._Role:GetCharacterId()) >= 4
    if isSS then
        return self._Control:IsPluginStageUpgrade(plugin.Id) and 1 or -1
    else
        return self._Control:IsPluginStageUpgrade(plugin.Id) and -1 or 1
    end
end

--endregion

function XUiRiftChoosePlugin:RefreshOwnPluginList()
    self._OwnPluginList = self._Control:GetRolePlugInIdList(self._Role)
    self.DynamicOwnTable:SetDataSource(self._OwnPluginList)
    self.DynamicOwnTable:ReloadDataASync()
    self.PanelNoPlugin1.gameObject:SetActiveEx(XTool.IsTableEmpty(self._OwnPluginList))
end

function XUiRiftChoosePlugin:RefreshGrids()
    self:RefreshAllBagGrid()
    self:RefreshOwnGrid()
end

function XUiRiftChoosePlugin:RefreshAllBagGrid()
    -- 仅刷新
    for i, grid in pairs(self.DynamicAllTable:GetGrids()) do
        local data = self.DynamicAllTable:GetData(i)
        self:SetGrid(grid, data, DynamicTableType.All)
    end
end

function XUiRiftChoosePlugin:RefreshOwnGrid()
    for i, grid in pairs(self.DynamicOwnTable:GetGrids()) do
        local data = self.DynamicOwnTable:GetData(i)
        if data then
            local plugin = self._Control:GetPlugin(data)
            grid:Refresh(plugin, self._IsDetail)
            grid:SetSelected(plugin.Id == self._CurPluginId)
        end
    end
end

---@param grid XUiRiftPluginEffectiveGrid
---@param data XTableRiftPlugin
function XUiRiftChoosePlugin:SetGrid(grid, data, type)
    local isBagAll = type == DynamicTableType.All
    grid:Init(self._Role, data, self._IsDetail, isBagAll)
    grid:Refresh(data, self._IsDetail)
    if data.Id == self._CurPluginId and not isBagAll then -- 插件背包不显示选中状态
        grid:SetSelected(true)
        self._CurSelectGrid = grid
    else
        grid:SetSelected(false)
    end
end

---@param plugin XTableRiftPlugin
function XUiRiftChoosePlugin:DoSelect(plugin)
    if self._CurSelectGrid then
        self._CurSelectGrid:SetSelected(false)
        self._CurSelectGrid = nil
    end
    if plugin then
        self._CurPluginId = plugin.Id
        self.BtnUnwear.gameObject:SetActiveEx(true)
        self:RefreshOwnGrid()
    else
        self._CurPluginId = nil
        self.BtnUnwear.gameObject:SetActiveEx(false)
    end
end

function XUiRiftChoosePlugin:RefreshBtnToggle()
    self._IsDetail = XSaveTool.GetData("UiRiftChoosePluginTxt") == 1
    self.BtnToggle:SetButtonState(self._IsDetail and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiRiftChoosePlugin:OnClickRecommend()
    local pluginIds = self._Control:GetOneKeyRecommendList(self._Role)
    if XTool.IsTableEmpty(pluginIds) then
        XUiManager.TipText("RiftOneKeyEquipFail")
        return
    end

    local doRecommend = function()
        self._Control:RiftSetCharacterPluginsRequest(self._Role, pluginIds, function()
            self:RefreshUIShow()
            self:RefreshAllBagGrid()
            self:RefreshOwnPluginList()
        end)
    end

    if XTool.IsTableEmpty(self._OwnPluginList) then
        doRecommend()
    else
        XUiManager.DialogTip("", XUiHelper.GetText("RiftOneKeyEquipTip"), XUiManager.DialogType.Normal, nil, function()
            doRecommend()
        end)
    end
end

---@param plugin XTableRiftPlugin
function XUiRiftChoosePlugin:ReqWearPlugin(plugin)
    local pluginId = plugin.Id
    local pluginList = self._Control:GetRolePlugInIdList(self._Role) or {}
    local res, index = table.contains(pluginList, pluginId)
    local afterChangePluginList = XTool.Clone(pluginList)
    -- 没有插件就装备，有就卸下
    if res then
        -- 卸下插件
        table.remove(afterChangePluginList, index)
    else
        -- 装备上插件
        -- 插件角色限制检测
        if self._Control:CheckCharacterWearLimit(pluginId, self._Role:GetCharacterId()) then
            XUiManager.TipError(XUiHelper.GetText("RiftPluginCharLimit"))
            return
        end
        -- 插件负载上限检测
        if self._Control:CheckLoadLimitAddPlugin(self._Role, pluginId) then
            XUiManager.TipError(XUiHelper.GetText("RiftPluginLoadNoneLeft"))
            return
        end
        -- 插件类型穿戴限制检测
        if self._Control:CheckCurPluginTypeLimit(plugin.Type, self._Role) then
            XUiManager.TipError(XUiHelper.GetText("RiftPluginTypeLimit"))
            return
        end
        -- 装备上插件
        table.insert(afterChangePluginList, pluginId)
    end

    self._Control:RiftSetCharacterPluginsRequest(self._Role, afterChangePluginList, function()
        self:RefreshUIShow()
        self:RefreshAllBagGrid()
        self:RefreshOwnPluginList()
    end)
end

function XUiRiftChoosePlugin:ReqUnwearPlugin()
    local pluginList = self._Control:GetRolePlugInIdList(self._Role)

    if XTool.IsTableEmpty(pluginList) or not self._CurPluginId then
        return
    end

    local afterChangePluginList = XTool.Clone(pluginList)
    local index = table.indexof(afterChangePluginList, self._CurPluginId)
    if index then
        table.remove(afterChangePluginList, index)
    end

    self._Control:RiftSetCharacterPluginsRequest(self._Role, afterChangePluginList, function()
        self:DoSelect(nil)
        self:RefreshUIShow()
        self:RefreshAllBagGrid()
        self:RefreshOwnPluginList()
    end)
end

function XUiRiftChoosePlugin:OnClickToggle()
    self._IsDetail = self.BtnToggle:GetToggleState()
    self:RefreshGrids()
    XSaveTool.SaveData("UiRiftChoosePluginTxt", self._IsDetail and 1 or 0)
end

function XUiRiftChoosePlugin:OnClickFilter()
    XLuaUiManager.Open("UiRiftPluginFilterTips", XEnumConst.Rift.FilterSetting.PluginChoose, handler(self, self.RefreshAllPluginList))
end

function XUiRiftChoosePlugin:OnClickMain()
    XLuaUiManager.RunMain()
end

function XUiRiftChoosePlugin:PlayUnlockAffixTween(pluginId, type, slot)
    ---@type XUiRiftPluginEffectiveGrid[]
    local grids = {}
    appendArray(grids, self.DynamicAllTable:GetGrids())
    appendArray(grids, self.DynamicOwnTable:GetGrids())
    for _, grid in pairs(grids) do
        grid:PlayTween(pluginId, type, slot)
    end
end

function XUiRiftChoosePlugin:OnPluginGuide(pluginId)
    pluginId = tonumber(pluginId)
    if not XTool.IsNumberValid(pluginId) then
        return
    end
    -- 取消筛选和星级
    self._Control:SaveFilterSertting(XEnumConst.Rift.FilterSetting.PluginChoose)
    self.PanelTabBtn:SelectIndex(1)

    local jumpTo
    for i, v in ipairs(self.DynamicAllTable.DataSource) do
        if v.Id == pluginId then
            jumpTo = i
            break
        end
    end
    if not XTool.IsNumberValid(jumpTo) then
        XLog.Warning("引导未找到该插件：" .. pluginId)
        return
    end
    self.DynamicAllTable:ReloadDataASync(jumpTo)
end

return XUiRiftChoosePlugin
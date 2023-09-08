---@class XUiRiftChoosePlugin : XLuaUi
local XUiRiftChoosePlugin = XLuaUiManager.Register(XLuaUi, "UiRiftChoosePlugin")

local DynamicTableType = { All = 1, Own = 2 }

function XUiRiftChoosePlugin:OnAwake()
    ---@type XCharacterAgency
    self.CharacterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnConfirm, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, self.OnClickMain)
    self:RegisterClickEvent(self.BtnShaixuan, self.OnClickFilter)
    self:RegisterClickEvent(self.BtnToggle, self.OnClickToggle)
    self:RegisterClickEvent(self.BtnUnwear, self.ReqUnwearPlugin)
    self:RegisterClickEvent(self.BtnRecommend, self.OnClickRecommend)
    self:RegisterClickEvent(self.BtnNext, self.OnClickNext)
    self:RegisterClickEvent(self.BtnLast, self.OnClickLast)
    self:BindHelpBtn(self.BtnHelp, "RiftPluginHelp")
end

---@param role XRiftRole
function XUiRiftChoosePlugin:OnStart(role)
    self._Role = role
    self._CurPluginId = nil
    ---@type XUiRiftPluginEffectiveGrid
    self._CurSelectGrid = nil
    self:InitCompnent()
    self:RefreshBtnToggle()
    self:RefreshUIShow()
    self:RefreshAllPluginList()
    self:RefreshOwnPluginList()
    XDataCenter.RiftManager:SetCharacterRedPoint(false)
end

function XUiRiftChoosePlugin:OnDestroy()

end

function XUiRiftChoosePlugin:InitCompnent()
    self.ImgRole:SetRawImage(self.CharacterAgency:GetCharSmallHeadIcon(self._Role.Id))
end

function XUiRiftChoosePlugin:RefreshUIShow()
    local cur = self._Role:GetCurrentLoad()
    local total = XDataCenter.RiftManager.GetMaxLoad()
    self.TxtLoadNum.text = XUiHelper.GetText("RiftPluginLoad", cur, total)
    self.ImgLoadProgress.fillAmount = cur / total
end

function XUiRiftChoosePlugin:RefreshAllPluginList()
    self._PluginIndexMap = {}
    self._BagPluginGrids = {}
    local roleElement = self.CharacterAgency:GetCharacterElement(self._Role.Id)
    local bagPluginList = XDataCenter.RiftManager:GetOwnPluginList(roleElement, self._Role.Id)
    table.sort(bagPluginList, handler(self, self.SortBagList))

    if not self._TempListCount or self._TempListCount ~= #bagPluginList then
        self._PluginPageDats = {}
        self._TempListCount = #bagPluginList
        local count = XDataCenter.RiftManager:GetPluginPageCount()
        local index = 1
        for i, v in ipairs(bagPluginList) do
            if not self._PluginPageDats[index] then
                self._PluginPageDats[index] = {}
            end
            table.insert(self._PluginPageDats[index], v)
            self._PluginIndexMap[v:GetId()] = index
            if i % count == 0 then
                index = index + 1
            end
        end
    end

    self:ShowPluginPage(1)
    self.PanelNoPluginBag.gameObject:SetActiveEx(XTool.IsTableEmpty(bagPluginList))
end

function XUiRiftChoosePlugin:ShowPluginPage(pageIndex, dimPluginId)
    local dimGrid
    self._CurPageIndex = pageIndex
    self._CurPageData = self._PluginPageDats[pageIndex] or {}
    XUiHelper.RefreshCustomizedList(self.PanelPluginContent.transform, self.GridAll, #self._CurPageData, function(index, go)
        local grid = require("XUi/XUiRift/Grid/XUiRiftPluginEffectiveGrid").New(go, self)
        local data = self._CurPageData[index]
        self:SetGrid(grid, data, DynamicTableType.All)
        self._BagPluginGrids[index] = grid
        if dimPluginId == data:GetId() then
            dimGrid = grid
        end
    end)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelPluginContent.transform)
    if dimGrid then
        local listH = self.PanelPluginScrollList.transform.rect.height
        local offset = math.abs(dimGrid.Transform.localPosition.y)
        local scrollArea = self.GridAll.parent.rect.height - listH
        self.PanelPluginScrollList.verticalNormalizedPosition = 1 - offset / scrollArea
    else
        self.PanelPluginScrollList.verticalNormalizedPosition = 1
    end
    self.TxtPage.text = string.format("%s/%s", pageIndex, #self._PluginPageDats)
    self.BtnLast.gameObject:SetActiveEx(pageIndex > 1)
    self.BtnNext.gameObject:SetActiveEx(pageIndex < #self._PluginPageDats)
end

--region 排序

---@param a XRiftPlugin
---@param b XRiftPlugin
function XUiRiftChoosePlugin:SortBagList(a, b)
    -- 当前专属>通用>非当前专属
    local aFirstSort = self:GetFirstSort(a)
    local bFirstSort = self:GetFirstSort(b)
    if aFirstSort ~= bFirstSort then
        return aFirstSort < bFirstSort
    end
    -- 暗金>非暗金
    local isASpecial = a:IsSpecialQuality()
    local isBSpecial = b:IsSpecialQuality()
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
    local aStar = a:GetStar()
    local bStar = b:GetStar()
    if aStar ~= bStar then
        return aStar > bStar
    end
    -- 排序字段
    local aSort = a.Config.Sort
    local bSort = b.Config.Sort
    if aSort ~= bSort then
        return aSort < bSort
    end
    -- Id
    return a.Config.Id < b.Config.Id
end

---@param plugin XRiftPlugin
function XUiRiftChoosePlugin:GetFirstSort(plugin)
    if plugin.Config.CharacterId == self._Role.Id then
        return 1
    elseif not XTool.IsNumberValid(plugin.Config.CharacterId) then
        return 2
    else
        return 3
    end
end

---@param plugin XRiftPlugin
function XUiRiftChoosePlugin:GetThirdSort(plugin)
    --1  2  3  4   5    6
    --B  A  S  SS  SSS  SSS+
    local isSS = self.CharacterAgency:GetCharacterQuality(self._Role.Id) >= 4
    if isSS then
        return plugin:IsStageUpgrade() and 1 or -1
    else
        return plugin:IsStageUpgrade() and -1 or 1
    end
end

--endregion

function XUiRiftChoosePlugin:RefreshOwnPluginList()
    self._OwnPluginGrids = {}
    self._OwnPluginList = self._Role:GetPlugIns()
    XUiHelper.RefreshCustomizedList(self.PanelContent.transform, self.GridOwn, #self._OwnPluginList, function(index, go)
        local grid = require("XUi/XUiRift/Grid/XUiRiftPluginEffectiveGrid").New(go, self)
        local data = self._OwnPluginList[index]
        self:SetGrid(grid, data, DynamicTableType.Own)
        self._OwnPluginGrids[index] = grid
    end)
    self.PanelEffectiveList.verticalNormalizedPosition = 1
    self.PanelNoPlugin1.gameObject:SetActiveEx(XTool.IsTableEmpty(self._OwnPluginList))
end

function XUiRiftChoosePlugin:RefreshGrids()
    self:RefreshAllBagGrid()
    self:RefreshOwnGrid()
end

function XUiRiftChoosePlugin:RefreshAllBagGrid(pluginId)
    -- 仅刷新
    for i, grid in ipairs(self._BagPluginGrids) do
        self:SetGrid(grid, self._CurPageData[i], DynamicTableType.All)
    end
end

function XUiRiftChoosePlugin:GetPageIndexById(pluginId)
    return self._PluginIndexMap[pluginId] or 1
end

function XUiRiftChoosePlugin:RefreshOwnGrid()
    for i, grid in pairs(self._OwnPluginGrids) do
        local data = self._OwnPluginList[i]
        grid:Refresh(data, self._IsDetail)
        grid:SetSelected(data:GetId() == self._CurPluginId)
    end
end

function XUiRiftChoosePlugin:SetGrid(grid, data, type)
    local isBagAll = type == DynamicTableType.All
    grid:Init(self._Role, data, self._IsDetail, isBagAll, function()
        if isBagAll then
            -- 点击直接穿戴/卸下
            self:DoSelect(nil)
            self:ReqWearPlugin(data)
        else
            -- 点击选中，点击按钮才能卸下
            self:DoSelect(data)
        end
    end)
    grid:Refresh(data, self._IsDetail)
    if data:GetId() == self._CurPluginId and not isBagAll then -- 插件背包不显示选中状态
        grid:SetSelected(true)
        self._CurSelectGrid = grid
    else
        grid:SetSelected(false)
    end
end

---@param plugin XRiftPlugin
function XUiRiftChoosePlugin:DoSelect(plugin)
    if self._CurSelectGrid then
        self._CurSelectGrid:SetSelected(false)
        self._CurSelectGrid = nil
    end
    if plugin then
        self._CurPluginId = plugin:GetId()
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
    local pluginIds = XDataCenter.RiftManager:GetOneKeyRecommendList(self._Role)
    if XTool.IsTableEmpty(pluginIds) then
        XUiManager.TipText("RiftOneKeyEquipFail")
        return
    end

    local doRecommend = function()
        XDataCenter.RiftManager.RiftSetCharacterPluginsRequest(self._Role, pluginIds, function()
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

---@param plugin XRiftPlugin
function XUiRiftChoosePlugin:ReqWearPlugin(plugin)
    local pluginId = plugin:GetId()
    local pluginList = self._Role:GetPlugInIdList()
    local res, index = table.contains(pluginList, pluginId)
    local afterChangePluginList = XTool.Clone(pluginList)
    -- 没有插件就装备，有就卸下
    if res then
        -- 卸下插件
        table.remove(afterChangePluginList, index)
    else
        -- 装备上插件
        -- 插件角色限制检测
        if plugin:CheckCharacterWearLimit(self._Role.Id) then
            XUiManager.TipError(XUiHelper.GetText("RiftPluginCharLimit"))
            return
        end
        -- 插件负载上限检测
        if self._Role:CheckLoadLimitAddPlugin(pluginId) then
            XUiManager.TipError(XUiHelper.GetText("RiftPluginLoadNoneLeft"))
            return
        end
        -- 插件类型穿戴限制检测
        if plugin:CheckCurPluginTypeLimit(self._Role) then
            XUiManager.TipError(XUiHelper.GetText("RiftPluginTypeLimit"))
            return
        end
        -- 装备上插件
        table.insert(afterChangePluginList, pluginId)
    end

    XDataCenter.RiftManager.RiftSetCharacterPluginsRequest(self._Role, afterChangePluginList, function()
        self:RefreshUIShow()
        self:RefreshAllBagGrid()
        self:RefreshOwnPluginList()
    end)
end

function XUiRiftChoosePlugin:ReqUnwearPlugin()
    local pluginList = self._Role:GetPlugInIdList()

    if XTool.IsTableEmpty(pluginList) or not self._CurPluginId then
        return
    end

    local afterChangePluginList = XTool.Clone(pluginList)
    local index = table.indexof(afterChangePluginList, self._CurPluginId)
    if index then
        table.remove(afterChangePluginList, index)
    end

    XDataCenter.RiftManager.RiftSetCharacterPluginsRequest(self._Role, afterChangePluginList, function()
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

function XUiRiftChoosePlugin:OnClickNext()
    self:ShowPluginPage(self._CurPageIndex + 1)
end

function XUiRiftChoosePlugin:OnClickLast()
    self:ShowPluginPage(self._CurPageIndex - 1)
end

return XUiRiftChoosePlugin
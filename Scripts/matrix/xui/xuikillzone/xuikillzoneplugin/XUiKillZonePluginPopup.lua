local XUiGridKillZonePluginDesc = require("XUi/XUiKillZone/XUiKillZonePlugin/XUiGridKillZonePluginDesc")

local Vector2 = CS.UnityEngine.Vector2
local CsXTextManagerGetText = CsXTextManagerGetText

local XUiKillZonePluginPopup = XLuaUiManager.Register(XLuaUi, "UiKillZonePluginPopup")

function XUiKillZonePluginPopup:OnAwake()
    self:AutoAddListener()
    self:InitDynamicTable()

    self.BtnActive.gameObject:SetActiveEx(false)
    self.GridDesc.gameObject:SetActiveEx(false)
    self.PanelSelect = self:FindTransform("PanelSelect"):GetComponent("RectTransform")
    self.Bg = self:FindTransform("Bg"):GetComponent("RectTransform")
end

function XUiKillZonePluginPopup:OnStart(slot, pluginId, isPreview, closeCb, specialPosition, hideAllBtns)
    self.Slot = slot
    self.PluginId = pluginId
    self.IsPreview = isPreview
    self.CloseCb = closeCb
    self.HideAllBtns = hideAllBtns

    if specialPosition then
        self.PanelSelect.anchorMax = Vector2(0, 0.5)
        self.PanelSelect.anchorMin = Vector2(0, 0.5)
        self.PanelSelect.anchoredPosition = Vector2(self.PanelSelect.rect.width / 2, 0)
        self.Bg.rotation = CS.UnityEngine.Quaternion.Euler(0, 0, 180)
    else
        self.PanelSelect.anchorMax = Vector2(1, 0.5)
        self.PanelSelect.anchorMin = Vector2(1, 0.5)
        self.PanelSelect.anchoredPosition = Vector2(self.PanelSelect.rect.width / -2, 0)
        self.Bg.rotation = CS.UnityEngine.Quaternion.Euler(0, 0, 0)
    end
end

function XUiKillZonePluginPopup:OnEnable()
    self:UpdateView()
end

function XUiKillZonePluginPopup:OnDestroy()
    if self.CloseCb then self.CloseCb() end
end

function XUiKillZonePluginPopup:OnGetEvents()
    return {
        XEventId.EVENT_KILLZONE_PLUGIN_CHANGE,
    }
end

function XUiKillZonePluginPopup:OnNotify(evt, ...)
    if self.IsEnd then return end

    local args = { ... }
    if evt == XEventId.EVENT_KILLZONE_PLUGIN_CHANGE then
        self:UpdateView()
    end
end

function XUiKillZonePluginPopup:InitDynamicTable()
    --self.DynamicTable = XDynamicTableNormal.New(self.PaneSkillDes)
    --self.DynamicTable:SetProxy(XUiGridKillZonePluginDesc)
    --self.DynamicTable:SetDelegate(self)
end

function XUiKillZonePluginPopup:OnDynamicTableEvent(event, index, grid)
    --if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
    --    local level = index
    --    local currentLevel = XDataCenter.KillZoneManager.GetPluginLevel(self.PluginId)
    --    local desc = self.DescList[level]
    --    grid:Refresh(desc, level, currentLevel)
    --end
end

function XUiKillZonePluginPopup:UpdateView()
    local pluginId = self.PluginId
    local isPreview = self.IsPreview
    local hideAllBtns = self.HideAllBtns

    self.TxtCost.gameObject:SetActiveEx(false)
    self.TxtCostUnlock.gameObject:SetActiveEx(false)
    self.TxtCostActive.gameObject:SetActiveEx(false)
    self.TxtRemind.gameObject:SetActiveEx(hideAllBtns)

    local icon = XKillZoneConfigs.GetPluginIcon(pluginId)
    self.RImgIcon:SetRawImage(icon)

    local name = XKillZoneConfigs.GetPluginName(pluginId)
    self.TxtName.text = name

    local level = XDataCenter.KillZoneManager.GetPluginShowLevelStr(pluginId)
    self.TxtLevel.text = level

    --解锁
    local isLock = XDataCenter.KillZoneManager.IsPluginLock(pluginId)
    if not hideAllBtns and not isPreview and isLock then
        local itemId, count = XKillZoneConfigs.GetPluginUnlockCost(pluginId)
        local icon = XItemConfigs.GetItemIconById(itemId)
        self.RImgCostUnlock:SetRawImage(icon)
        self.TxtCostUnlock.text = count
        self.TxtCostUnlock.gameObject:SetActiveEx(true)
        self.BtnUnlock.gameObject:SetActiveEx(true)
    else
        self.BtnUnlock.gameObject:SetActiveEx(false)
    end

    --升级
    local canLevelUp = XDataCenter.KillZoneManager.CheckPluginCanLevelUp(pluginId)
    if not hideAllBtns and not isPreview and canLevelUp then
        local itemId, count = XDataCenter.KillZoneManager.GetPluginLevelUpCost(pluginId)
        local icon = XItemConfigs.GetItemIconById(itemId)
        self.RImgCost:SetRawImage(icon)
        self.TxtCost.text = count
        self.TxtCost.gameObject:SetActiveEx(true)
        self.BtnStrengthen.gameObject:SetActiveEx(true)
    else
        self.BtnStrengthen.gameObject:SetActiveEx(false)
    end

    --重置
    if not hideAllBtns then
        local canReset = XDataCenter.KillZoneManager.IsPluginCanReset(pluginId)
        self.BtnReset.gameObject:SetActiveEx(canReset)
    else
        self.BtnReset.gameObject:SetActiveEx(false)
    end

    local isWearing = XDataCenter.KillZoneManager.IsPluginWearing(pluginId)
    self.PanelWearing.gameObject:SetActiveEx(isWearing)
    self.BtnTakeOffOnly.gameObject:SetActiveEx(not hideAllBtns and isWearing and isPreview) --预览模式的卸下按钮
    self.BtnTakeOff.gameObject:SetActiveEx(not hideAllBtns and isWearing and not isPreview) --卸下
    self.BtnPutOn.gameObject:SetActiveEx(not hideAllBtns and not isWearing and not isLock and not isPreview) --穿戴

    --技能描述
    local level = XDataCenter.KillZoneManager.GetPluginLevel(pluginId)
    local selectIndex = XMath.Clamp(level, -1, level)
    self.DescList = XKillZoneConfigs.GetPluginLevelSkillDescList(pluginId)
    --self.DynamicTable:SetDataSource(self.DescList)
    --self.DynamicTable:ReloadDataASync(selectIndex)

    self:RefreshTemplateGrids(
            self.GridDesc,
            self.DescList,
            self.PanelContent,
            XUiGridKillZonePluginDesc,
            "GridDesc",
            function(grid, info)
                local level = grid.Index
                local currentLevel = XDataCenter.KillZoneManager.GetPluginLevel(self.PluginId)
                local desc = self.DescList[level]
                grid:Refresh(desc, level, currentLevel)
            end
    )
    XScheduleManager.ScheduleOnce(function()
        local gridList = self._GridsDic["GridDesc"]
        if gridList and gridList[selectIndex] then
            local grid = gridList[selectIndex]
            local maxGrid = gridList[#gridList]
            local viewSize = maxGrid.Transform.localPosition.y
            local gridPosY = grid.Transform.localPosition.y
            --XLog.Error(viewSize, gridPosY)
            local rate = 1 - gridPosY / viewSize
            self.PaneSkillDes.verticalNormalizedPosition = CS.UnityEngine.Mathf.Clamp01(rate)
        end
    end, 1)
end

function XUiKillZonePluginPopup:AutoAddListener()
    self.BtnTakeOff.CallBack = function() self:OnClickBtnTakeOff() end
    self.BtnTakeOffOnly.CallBack = function() self:OnClickBtnTakeOff() end
    self.BtnPutOn.CallBack = function() self:OnClickBtnPutOn() end
    self.BtnUnlock.CallBack = function() self:OnClickBtnUnlock() end
    self.BtnStrengthen.CallBack = function() self:OnClickBtnStrengthen() end
    self.BtnReset.CallBack = function() self:OnClickBtnReset() end
    self.BtnClose.CallBack = function() self:Close() end
end

--卸下
function XUiKillZonePluginPopup:OnClickBtnTakeOff()
    local pluginId = self.PluginId
    local slot = self.Slot

    XDataCenter.KillZoneManager.KillZoneUsePluginRequest(slot, pluginId, true)
end

--穿戴
function XUiKillZonePluginPopup:OnClickBtnPutOn()
    local pluginId = self.PluginId
    local slot = self.Slot

    XDataCenter.KillZoneManager.KillZoneUsePluginRequest(slot, pluginId, false)
end

--解锁
function XUiKillZonePluginPopup:OnClickBtnUnlock()
    local pluginId = self.PluginId

    local itemId, count = XKillZoneConfigs.GetPluginUnlockCost(pluginId)
    if not XDataCenter.ItemManager.CheckItemCountById(itemId, count) then
        XUiManager.TipText("KillZonePlguinUnlockCostLack")
        return
    end

    XDataCenter.KillZoneManager.KillZoneUnlockPluginRequest(pluginId)
end

--升级
function XUiKillZonePluginPopup:OnClickBtnStrengthen()
    local pluginId = self.PluginId

    local itemId, count = XDataCenter.KillZoneManager.GetPluginLevelUpCost(pluginId)
    if not XDataCenter.ItemManager.CheckItemCountById(itemId, count) then
        XUiManager.TipText("KillZonePlguinLevelUpCostLack")
        return
    end

    XDataCenter.KillZoneManager.KillZoneUpgradePluginRequest(pluginId)
end

--重置
function XUiKillZonePluginPopup:OnClickBtnReset()
    XLuaUiManager.Open("UiKillZonePluginReset", { self.PluginId })
end
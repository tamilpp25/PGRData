local XUiGridAreaWarPlugin = require("XUi/XUiAreaWar/XUiGridAreaWarPlugin")

local XUiAreaWarJingHua = XLuaUiManager.Register(XLuaUi, "UiAreaWarJingHua")

--===========================================================================
--region 生命周期
--===========================================================================
function XUiAreaWarJingHua:OnAwake()
    self.GridBuff.gameObject:SetActiveEx(false)
    self:AutoAddListener()
end

function XUiAreaWarJingHua:OnStart()
    self.BtnGrids = {}
    self.BuffGrids = {}
end

function XUiAreaWarJingHua:OnEnable()
    if self.IsEnd then
        return
    end
    if XDataCenter.AreaWarManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end

    self:UpdatePurificationLevel()
    self:UpdatePlugins()
    self.UiInited = true
end
--==========================================================================
--endregion
--==========================================================================

--==========================================================================
--region 初始化
--==========================================================================

function XUiAreaWarJingHua:AutoAddListener()
    self:BindHelpBtn(self.BtnHelp, "AreaWarJingHua")
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
end

--==========================================================================
--endregion
--==========================================================================

--==========================================================================
--region 数据更新
--==========================================================================

--更新插件列表
function XUiAreaWarJingHua:UpdatePlugins()
    local pluginIds = XAreaWarConfigs.GetAllPluginIds()
    local isFirst=true
    local pluginCount=#pluginIds
    for index, pluginId in ipairs(pluginIds) do
        local grid = self.BuffGrids[index]
        if not grid then
            local go = index == 1 and self.GridBuff or CSObjectInstantiate(self.GridBuff, self.BuffListContent)
            local clickCb = handler(self, self.OnClickPlugin)
            grid = XUiGridAreaWarPlugin.New(go, clickCb)
            self.BuffGrids[index] = grid
        end
        grid:Refresh(pluginId,isFirst,index==pluginCount)
        grid.GameObject:SetActiveEx(true)
        isFirst=false
    end
    for index = #pluginIds + 1, #self.BuffGrids do
        self.BuffGrids[index].GameObject:SetActiveEx(false)
    end
end

--更新增幅等级
function XUiAreaWarJingHua:UpdatePurificationLevel()
    local level = XDataCenter.AreaWarManager.GetSelfPurificationLevel()
    local curExp = XDataCenter.AreaWarManager.GetSelfPurificationExp()
    local maxExp = XAreaWarConfigs.GetPfLevelNextLevelExp(level)

    --属性
    local addAttrs = XAreaWarConfigs.GetPfLevelAddAttrs(level)
    for index, attr in ipairs(addAttrs) do
        self["TxtAttr" .. index].text = attr
    end
end

--==========================================================================
--endregion
--==========================================================================

--==========================================================================
--region 事件处理
--==========================================================================

function XUiAreaWarJingHua:OnClickPlugin(pluginId)
    local canUnlock = XDataCenter.AreaWarManager.IsPluginCanUnlock(pluginId) --可解锁
    if canUnlock then
        --待解锁时点击则请求解锁
        XDataCenter.AreaWarManager.AreaWarUnlockPurificationBuffRequest(pluginId)
    else
        --未解锁或者已解锁则看效果
        XLuaUiManager.Open("UiAreaWarJingHuaUp", pluginId, 1)
    end
end

function XUiAreaWarJingHua:OnGetEvents()
    return {
        XEventId.EVENT_AREA_WAR_PLUGIN_USE_STATUS_CHANGE,
        XEventId.EVENT_AREA_WAR_PLUGIN_UNLOCK,
        XEventId.EVENT_AREA_WAR_ACTIVITY_END
    }
end

function XUiAreaWarJingHua:OnNotify(evt, ...)
    if self.IsEnd then
        return
    end

    local args = {...}
    if evt == XEventId.EVENT_AREA_WAR_PLUGIN_USE_STATUS_CHANGE then
        local slot = args[1]
        local isUse = args[2]
        if isUse then
            self:ShowBtnEffect(slot)
        end
        self:UpdatePluginSlots()
        self:UpdatePlugins()
    elseif evt == XEventId.EVENT_AREA_WAR_PLUGIN_UNLOCK then
        self:UpdatePlugins()
    elseif evt == XEventId.EVENT_AREA_WAR_ACTIVITY_END then
        if XDataCenter.AreaWarManager.OnActivityEnd() then
            self.IsEnd = true
            return
        end
    end
end

--==========================================================================
--endregion
--==========================================================================







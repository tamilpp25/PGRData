local XUiGridAreaWarPlugin = require("XUi/XUiAreaWar/XUiGridAreaWarPlugin")

local XUiAreaWarJingHua = XLuaUiManager.Register(XLuaUi, "UiAreaWarJingHua")

function XUiAreaWarJingHua:OnAwake()
    self.BtnExpand.gameObject:SetActiveEx(true)
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
    self:UpdatePluginSlots()
    self:UpdatePlugins()
    self.UiInited = true
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

function XUiAreaWarJingHua:AutoAddListener()
    self:BindHelpBtn(self.BtnHelp, "AreaWarJingHua")
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
    self.BtnExpand.CallBack = function()
        self:OnClickBtnExpand()
    end
    for slot = 1, XAreaWarConfigs.PluginSlotCount do
        self["BtnBuff" .. slot].CallBack = function()
            self:OnClickSlot(slot)
        end
    end
end

function XUiAreaWarJingHua:UpdatePurificationLevel()
    local level = XDataCenter.AreaWarManager.GetSelfPurificationLevel()
    local curExp = XDataCenter.AreaWarManager.GetSelfPurificationExp()
    local maxExp = XAreaWarConfigs.GetPfLevelNextLevelExp(level)

    if not XTool.IsNumberValid(maxExp) then
        --满级
        self.TxtExp.text = CSXTextManagerGetText("AreaWarAreaPurificationLevelMax")
        self.ImgProgressFillAmount.fillAmount = 1
    else
        self.TxtExp.text = curExp .. "/" .. maxExp
        self.ImgProgressFillAmount.fillAmount = curExp / maxExp
    end
    self.TxtLevel.text = level

    --属性
    local addAttrs = XAreaWarConfigs.GetPfLevelAddAttrs(level)
    for index, attr in ipairs(addAttrs) do
        self["TxtAttr" .. index].text = attr
    end
end

--更新插件槽
function XUiAreaWarJingHua:UpdatePluginSlots()
    for slot = 1, XAreaWarConfigs.PluginSlotCount do
        local btn = self["BtnBuff" .. slot]

        local isUnlock = XDataCenter.AreaWarManager.IsPluginSlotUnlock(slot)
        btn:SetDisable(not isUnlock)

        local grid = self.BtnGrids[slot]
        if not grid then
            grid = XTool.InitUiObjectByUi({}, btn)
            self.BtnGrids[slot] = grid
        end

        local isEmpty = XDataCenter.AreaWarManager.IsPluginSlotEmpty(slot)
        if not isEmpty then
            local pluginId = XDataCenter.AreaWarManager.GetSlotPluginId(slot)
            grid.RImgBuff:SetRawImage(XAreaWarConfigs.GetBuffIcon(pluginId))
        end
        grid.PanelEmpty.gameObject:SetActiveEx(isEmpty)
        grid.PanelNormal.gameObject:SetActiveEx(not isEmpty)
    end
end

--更新插件列表
function XUiAreaWarJingHua:UpdatePlugins()
    local pluginIds = XAreaWarConfigs.GetAllPluginIds()
    for index, pluginId in ipairs(pluginIds) do
        local grid = self.BuffGrids[index]
        if not grid then
            local go = index == 1 and self.GridBuff or CSObjectInstantiate(self.GridBuff, self.BuffListContent)
            local clickCb = handler(self, self.OnClickPlugin)
            grid = XUiGridAreaWarPlugin.New(go, clickCb)
            self.BuffGrids[index] = grid
        end
        grid:Refresh(pluginId)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #pluginIds + 1, #self.BuffGrids do
        self.BuffGrids[index].GameObject:SetActiveEx(false)
    end
end

--装备插件时的特效
function XUiAreaWarJingHua:ShowBtnEffect(slot)
    local btn = self["BtnBuff" .. slot]
    btn:ShowTag(false)
    btn:ShowTag(true)
end

--展开动画
function XUiAreaWarJingHua:OnClickBtnExpand()
    if not self.UiInited then
        return
    end

    local asynPlayAnimation = asynTask(self.PlayAnimationWithMask, self)
    RunAsyn(
        function()
            --展开动画只生效一次
            self.BtnExpand.gameObject:SetActiveEx(false)
            --格子同时播放展开动画
            for _, grid in pairs(self.BuffGrids) do
                grid:PlayExpandAnim()
            end
            --UI旋转动画
            asynPlayAnimation("PanelQuanRotate")
            --UI循环动画
            self:PlayAnimation("PanelQuanLoop")
        end
    )
end

function XUiAreaWarJingHua:OnClickSlot(slot)
    local isUnlock = XDataCenter.AreaWarManager.IsPluginSlotUnlock(slot)
    if not isUnlock then
        local unlockLevel = XAreaWarConfigs.GetUnlockSlotPfLevel(slot)
        local msg = CsXTextManagerGetText("AreaWarAreaUnlockSlotPurificationLevel", unlockLevel)
        XUiManager.TipMsg(msg)
        return
    end

    local isEmpty = XDataCenter.AreaWarManager.IsPluginSlotEmpty(slot)
    if isEmpty then
        --可用插件格子播放提示动画
        for _, grid in pairs(self.BuffGrids) do
            grid:PlayCanUseAnim()
        end
        XUiManager.TipText("AreaWarAreaSlotEmpty")
        return
    end

    local pluginId = XDataCenter.AreaWarManager.GetSlotPluginId(slot)
    XLuaUiManager.Open("UiAreaWarJingHuaUp", pluginId, slot, 2)
end

function XUiAreaWarJingHua:OnClickPlugin(pluginId)
    local canUnlock = XDataCenter.AreaWarManager.IsPluginCanUnlock(pluginId) --可解锁
    if canUnlock then
        --待解锁
        XDataCenter.AreaWarManager.AreaWarUnlockPurificationBuffRequest(pluginId)
    else
        local slot = XDataCenter.AreaWarManager.GetNextEmptyPluginSlot()
        XLuaUiManager.Open("UiAreaWarJingHuaUp", pluginId, slot, 1)
    end
end

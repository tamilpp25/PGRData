local XUiTheatre4HandbookGenius = require("XUi/XUiTheatre4/System/Handbook/XUiTheatre4HandbookGenius")
local XUiTheatre4HandbookProp = require("XUi/XUiTheatre4/System/Handbook/XUiTheatre4HandbookProp")
local XUiTheatre4HandbookMap = require("XUi/XUiTheatre4/System/Handbook/XUiTheatre4HandbookMap")

---@class XUiTheatre4Handbook : XLuaUi
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field TabPanelGroup XUiButtonGroup
---@field BtnTab1 XUiComponent.XUiButton
---@field BtnTab2 XUiComponent.XUiButton
---@field BtnTab3 XUiComponent.XUiButton
---@field PanelGenius UnityEngine.RectTransform
---@field PanelProp UnityEngine.RectTransform
---@field PanelMap UnityEngine.RectTransform
---@field _Control XTheatre4Control
local XUiTheatre4Handbook = XLuaUiManager.Register(XLuaUi, "UiTheatre4Handbook")

local PageType = {
    Prop = 1,
    Genius = 2,
    -- Map = 3,
}

-- region 生命周期

function XUiTheatre4Handbook:OnAwake()
    ---@type XUiTheatre4HandbookGenius
    self.PanelGeniusUi = XUiTheatre4HandbookGenius.New(self.PanelGenius, self)
    ---@type XUiTheatre4HandbookProp
    self.PanelPropUi = XUiTheatre4HandbookProp.New(self.PanelProp, self)
    -- -@type XUiTheatre4HandbookMap
    -- self.PanelMapUi = XUiTheatre4HandbookMap.New(self.PanelMap, self)
    ---@type XUiComponent.XUiButton[]
    self._BtnTabPanelGroupList = {
        self.BtnTab1,
        self.BtnTab2,
        -- self.BtnTab3,
    }
    self._CurrentSelectIndex = nil

    self._ClickType = {}

    self:_InitTab()
    self:_RegisterButtonClicks()
end

function XUiTheatre4Handbook:OnStart()

end

function XUiTheatre4Handbook:OnEnable()
    self:RefreshRedDot()
    self:_RefreshTabPage()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiTheatre4Handbook:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiTheatre4Handbook:OnDestroy()
    if self._ClickType[PageType.Prop] then
        self._Control.SystemControl:ClearAllItemRedDot()
    end
    if self._ClickType[PageType.Genius] then
        self._Control.SystemControl:ClearAllTalentRedDot()
    end
end
-- endregion

-- region 按钮事件

function XUiTheatre4Handbook:Close()
    if self.PanelGeniusUi:CheckCloseCard() or self.PanelPropUi:CheckCloseCard() then
        return
    end

    self.Super.Close(self)
end

function XUiTheatre4Handbook:OnTabPanelGroupClick(index)
    self._CurrentSelectIndex = index
    self._ClickType[index] = true
    if index == PageType.Prop then
        self.PanelPropUi:Open()
        self.PanelGeniusUi:Close()
        -- self.PanelMapUi:Close()
    elseif index == PageType.Genius then
        self.PanelGeniusUi:Open()
        self.PanelPropUi:Close()
        -- self.PanelMapUi:Close()
    -- elseif index == PageType.Map then
    --     -- self.PanelMapUi:Open()
    --     self.PanelPropUi:Close()
    --     self.PanelGeniusUi:Close()
    end
end

-- endregion

function XUiTheatre4Handbook:RefreshRedDot()
    if self._CurrentSelectIndex == PageType.Prop then
        self.BtnTab1:ShowReddot(self._Control.SystemControl:CheckItemHandBookRedDot())
    elseif self._CurrentSelectIndex == PageType.Genius then
        self.BtnTab2:ShowReddot(self._Control.SystemControl:CheckColorTalentHandBookRedDot())
    -- elseif self._CurrentSelectIndex == PageType.Map then
        -- self.BtnTab3:ShowReddot(self._Control.SystemControl:CheckMapIndexHandBookRedDot())
    else
        self.BtnTab1:ShowReddot(self._Control.SystemControl:CheckItemHandBookRedDot())
        self.BtnTab2:ShowReddot(self._Control.SystemControl:CheckColorTalentHandBookRedDot())
        -- self.BtnTab3:ShowReddot(self._Control.SystemControl:CheckMapIndexHandBookRedDot())
    end
end

-- region 私有方法

function XUiTheatre4Handbook:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self.TabPanelGroup:Init(self._BtnTabPanelGroupList, Handler(self, self.OnTabPanelGroupClick))
end

function XUiTheatre4Handbook:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiTheatre4Handbook:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiTheatre4Handbook:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiTheatre4Handbook:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiTheatre4Handbook:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiTheatre4Handbook:_RefreshTabPage()
    self.TabPanelGroup:SelectIndex(self._CurrentSelectIndex or 1)
end

function XUiTheatre4Handbook:_InitTab()
    for i = 1, 2 do
        local tab = self["BtnTab" .. i]

        if tab then
            tab:ActiveTextByGroup(1, false)
            tab:SetNameByGroup(0, self._Control:GetClientConfig("HandBookTagText", i))
        end
    end
end

-- endregion

return XUiTheatre4Handbook

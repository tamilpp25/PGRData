-- 关卡背景
local XPanelColorBg = XClass(nil, "XPanelColorBg")

function XPanelColorBg:Ctor(root, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root

    self:_InitUiObject()
end

function XPanelColorBg:Refresh(bossLevels, isHideEffect)
    self.GameObject:SetActiveEx(true)
    for colorType, level in ipairs(bossLevels) do
        self:RefreshColorBg(colorType, level, isHideEffect)
    end
end

function XPanelColorBg:RefreshColorBg(colorType, level, isHideEffect)
    if XTool.IsTableEmpty(self.ColorBg[colorType]) then
        return
    end
    local gameData = XDataCenter.ColorTableManager.GetGameManager():GetGameData()
    for index, bg in ipairs(self.ColorBg[colorType]) do
        local isNoShow = gameData:CheckIsFirstGuideStage() and XColorTableConfigs.GetGuideStageColor() ~= colorType
        if self.ColorBgEffect[colorType][index] and (bg.gameObject.activeSelf ~= (index <= level) and not isNoShow) and not isHideEffect then
            self.ColorBgEffect[colorType][index].gameObject:SetActiveEx(false)
            self.ColorBgEffect[colorType][index].gameObject:SetActiveEx(true)
        end
        bg.gameObject:SetActiveEx(index <= level and not isNoShow)
    end
end

function XPanelColorBg:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_BLOCKSETTLE, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_BOSSLEVELCHANGE, self.Refresh, self)
end

function XPanelColorBg:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_BLOCKSETTLE, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_BOSSLEVELCHANGE, self.Refresh, self)
end

-- private
--------------------------------------------------------------------------------

function XPanelColorBg:_InitUiObject()
    XTool.InitUiObject(self)
    self.ColorBg = {}
    self.ColorBgEffect = {}
    for i = 1, 6, 1 do
        if XTool.IsTableEmpty(self.ColorBg[XColorTableConfigs.ColorType.Red]) then
            self.ColorBg[XColorTableConfigs.ColorType.Red] = {}
        end
        if XTool.IsTableEmpty(self.ColorBg[XColorTableConfigs.ColorType.Green]) then
            self.ColorBg[XColorTableConfigs.ColorType.Green] = {}
        end
        if XTool.IsTableEmpty(self.ColorBg[XColorTableConfigs.ColorType.Blue]) then
            self.ColorBg[XColorTableConfigs.ColorType.Blue] = {}
        end
        table.insert(self.ColorBg[XColorTableConfigs.ColorType.Red], self["PanelRed" .. i])
        table.insert(self.ColorBg[XColorTableConfigs.ColorType.Green], self["PanelGreen" .. i])
        table.insert(self.ColorBg[XColorTableConfigs.ColorType.Blue], self["PanelBlue" .. i])
    end

    for i = 1, 6, 1 do
        if XTool.IsTableEmpty(self.ColorBgEffect[XColorTableConfigs.ColorType.Red]) then
            self.ColorBgEffect[XColorTableConfigs.ColorType.Red] = {}
        end
        if XTool.IsTableEmpty(self.ColorBgEffect[XColorTableConfigs.ColorType.Green]) then
            self.ColorBgEffect[XColorTableConfigs.ColorType.Green] = {}
        end
        if XTool.IsTableEmpty(self.ColorBgEffect[XColorTableConfigs.ColorType.Blue]) then
            self.ColorBgEffect[XColorTableConfigs.ColorType.Blue] = {}
        end
        table.insert(self.ColorBgEffect[XColorTableConfigs.ColorType.Red], self["PanelEffectRed" .. i])
        table.insert(self.ColorBgEffect[XColorTableConfigs.ColorType.Green], self["PanelEffectGreen" .. i])
        table.insert(self.ColorBgEffect[XColorTableConfigs.ColorType.Blue], self["PanelEffectBlue" .. i])
    end
end

--------------------------------------------------------------------------------

return XPanelColorBg
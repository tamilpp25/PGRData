---@class XUiRiftHandbookBuff : XLuaUi
local XUiRiftHandbookBuff = XLuaUiManager.Register(XLuaUi, "UiRiftHandbookBuff")

function XUiRiftHandbookBuff:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnBgClose, self.Close)
    self:RegisterClickEvent(self.BtnBubbleClose, self.OnClickBubbleClose)
    self:RegisterClickEvent(self.BtnHandbookBuff, self.OpenBuffBubble)
end

function XUiRiftHandbookBuff:OnStart()
    self:InitCompnent()
    self:OnClickBubbleClose()
end

function XUiRiftHandbookBuff:OnDestroy()

end

function XUiRiftHandbookBuff:InitCompnent()
    -- 进度条
    for star = 3, 6 do
        local bar = self["ImgBar" .. star]
        local title = self["TxtTitle" .. star]
        local progress = self["TxtNum" .. star]
        local gridBuff = self["GridBuff" .. star]

        local cur, all = XDataCenter.RiftManager.GetPluginCount(star)
        title.text = XUiHelper.GetText("RiftHandbookTitle", star)
        progress.text = string.format("%s/%s", cur, all)

        local effects = XDataCenter.RiftManager:GetHandbookEffect(star)
        local isForceBubble = true
        for _, data in ipairs(effects) do
            local count = data.Count
            local cfg = data.Config
            local go = XUiHelper.Instantiate(gridBuff, gridBuff.parent)
            local uiObject = {}
            XTool.InitUiObjectByUi(uiObject, go)
            uiObject.PanelOff.gameObject:SetActiveEx(cur < count)
            uiObject.PanelOn.gameObject:SetActiveEx(cur >= count)
            uiObject.TxtNum.text = count
            local attr = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftTeamAttributeEffectType, cfg.Attr)
            if attr.ShowType == XRiftConfig.AttributeFixEffectType.Value then
                uiObject.TxtBuffTitle.text = string.format("%s+%s", attr.Name, cfg.Value)
            else
                uiObject.TxtBuffTitle.text = string.format("%s+%s%%", attr.Name, tonumber(string.format("%.1f", cfg.Value / 100)))
            end
            if isForceBubble and count > cur then
                -- 强制显示最近一个未解锁的节点
                uiObject.PanelBubble.gameObject:SetActiveEx(true)
                isForceBubble = false
            else
                uiObject.PanelBubble.gameObject:SetActiveEx(false)
                self:RegisterClickEvent(go, function()
                    self:OpenBubble(uiObject.PanelBubble)
                end)
            end
        end

        local precent, temp, radio = 0, cur, 1 / (#effects + 1)
        if cur >= all then
            precent = 1
        elseif cur == 0 then
            precent = 0
        else
            for node = 1, #effects + 1 do
                local range
                if node == 1 then
                    range = effects[1].Count
                elseif node > #effects then
                    range = all - effects[#effects].Count
                else
                    range = effects[node].Count - effects[node - 1].Count
                end
                precent = precent + math.min(radio, temp / range * radio)
                temp = math.max(0, temp - range)
                if temp <= 0 then
                    break
                end
            end
        end
        bar.fillAmount = precent
        gridBuff.gameObject:SetActiveEx(false)
    end

    -- 加成
    local index = 1
    local datas = XDataCenter.RiftManager:GetHandbookTakeEffectList()
    self._IsEmpty = XTool.IsTableEmpty(datas)
    self:RefreshTemplateGrids(self.GridBuff, datas, self.GridBuff.parent, nil, "UiRiftHandbookBuffEffect", function(grid, data)
        local attr = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftTeamAttributeEffectType, data.AttrId)
        grid.ImgBg.gameObject:SetActiveEx(index % 2 == 0)
        grid.TxtName.text = attr.Name
        if attr.ShowType == XRiftConfig.AttributeFixEffectType.Value then
            grid.TxtNum.text = data.Value
        else
            grid.TxtNum.text = string.format("%s%%", tonumber(string.format("%.1f", data.Value / 100)))
        end
        index = index + 1
    end)
    self.GridBuff.parent.gameObject:SetActiveEx(false)
end

function XUiRiftHandbookBuff:OpenBubble(bubble)
    self._ActiveBubble = bubble
    self._ActiveBubble.gameObject:SetActiveEx(true)
    self.BtnBubbleClose.gameObject:SetActiveEx(true)
end

function XUiRiftHandbookBuff:OpenBuffBubble()
    if self._IsEmpty then
        XUiManager.TipError(XUiHelper.GetText("RiftHandbookNoEffect"))
        return
    end
    self:OpenBubble(self.PanelBuffBubble)
end

function XUiRiftHandbookBuff:OnClickBubbleClose()
    self.BtnBubbleClose.gameObject:SetActiveEx(false)
    if self._ActiveBubble then
        self._ActiveBubble.gameObject:SetActiveEx(false)
        self._ActiveBubble = nil
    end
end

return XUiRiftHandbookBuff
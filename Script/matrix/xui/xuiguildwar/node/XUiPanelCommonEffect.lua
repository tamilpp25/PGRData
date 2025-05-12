---@class XUiGuildWarPanelCommonEffect
---@field Parent @XUiGuildWarStageDetail
local XUiPanelCommonEffect = XClass(XUiNode, "XUiPanelCommonEffect")

function XUiPanelCommonEffect:OnStart(node)
    self._Node = node
    self.PanelUiDetail01 = {}
    ---@type XUiGuildWarStageDetailEvent[]
    self._UiEvent = {}
    self._UiGo = {}
    self.PanelBuf.gameObject:SetActiveEx(false)
    self._UiEventUsingTail = 0
end

function XUiPanelCommonEffect:SetIsHideTitle(isHide)
    self.bg.gameObject:SetActiveEx(not isHide)
    self.Text1.gameObject:SetActiveEx(not isHide)
end

---@param proxy XUiGuildWarStageDetailEvent @is or base
function XUiPanelCommonEffect:AddEffectShow(eventId, proxy)
    local eventDetailCfg = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(eventId)

    self._UiEventUsingTail = self._UiEventUsingTail + 1
    if self._UiEventUsingTail > #self._UiGo then
        local ui = XUiHelper.Instantiate(self.PanelBuf.gameObject, self.PanelBuf.transform.parent.transform)
        local uiEvent = proxy.New(ui, self)
        self._UiEvent[self._UiEventUsingTail] = uiEvent
        self._UiGo[self._UiEventUsingTail] = ui
    else
        -- 先把之前的代理释放掉
        if not XTool.IsTableEmpty(self._UiEvent[self._UiEventUsingTail]) and self._UiEvent[self._UiEventUsingTail].Release then
            self._UiEvent[self._UiEventUsingTail]:Release()
        end
        -- 使用新的代理控制显示
        self._UiEvent[self._UiEventUsingTail] = proxy.New(self._UiGo[self._UiEventUsingTail], self)
    end

    self._UiEvent[self._UiEventUsingTail]:Update(eventDetailCfg)
    self._UiEvent[self._UiEventUsingTail].GameObject:SetActiveEx(true)
end

function XUiPanelCommonEffect:RecycleEffectShow()
    if XTool.IsTableEmpty(self._UiGo) then
        return
    end
    
    -- 隐藏所有go
    for i, v in pairs(self._UiGo) do
        v.gameObject:SetActiveEx(false)
    end
    
    -- 释放所有的代理
    if not XTool.IsTableEmpty(self._UiEvent) then
        for i, v in pairs(self._UiEvent) do
            if v.Release then
                v:Release()
            end
        end
        self._UiEvent = {}
    end
    
    -- 重置索引
    self._UiEventUsingTail = 0
end

function XUiPanelCommonEffect:AddTimer(cb)
    local timeId = self.Parent:AddTimer(cb)
    return timeId
end

function XUiPanelCommonEffect:RemoveTimer(timeId)
    self.Parent:RemoveTimer(timeId)
end

return XUiPanelCommonEffect

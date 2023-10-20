local XUiPanelRogueSimBaseBubble = require("XUi/XUiRogueSim/Component/XUiPanelRogueSimBaseBubble")
---@class XUiPanelBuffDetailBubble : XUiPanelRogueSimBaseBubble
---@field private _Control XRogueSimControl
---@field private Transform UnityEngine.RectTransform
local XUiPanelBuffDetailBubble = XClass(XUiPanelRogueSimBaseBubble, "XUiPanelBuffDetailBubble")

function XUiPanelBuffDetailBubble:OnStart()
    self.CurAlignment = XEnumConst.RogueSim.Alignment.RTB
    self:SetAnchorAndPivot()
    self.GridBuff.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridBuffList = {}

    -- 最大高度
    self.MaxHeight = self.Transform.rect.height
    -- 宽度
    self.Width = self.Transform.rect.width
end

function XUiPanelBuffDetailBubble:Refresh(targetTransform)
    self.CanvasGroup.alpha = 0
    self:SetTransform(targetTransform)
    self:HideGridBuff()
    -- 波动Buff
    local volatilityBuffs = self._Control.BuffSubControl:GetBuffIdsBySourceType(XEnumConst.RogueSim.SourceType.Volatility)
    local isVolatilityEmpty = XTool.IsTableEmpty(volatilityBuffs)
    self.TxtTitle1.gameObject:SetActiveEx(not isVolatilityEmpty)
    self.PanelVolatility.gameObject:SetActiveEx(not isVolatilityEmpty)
    self:RefreshGridBuffs(volatilityBuffs, 0, self.PanelVolatility)
    -- 事件Buff
    local eventBuffs = self._Control.BuffSubControl:GetBuffIdsBySourceType(XEnumConst.RogueSim.SourceType.Event)
    local isEventEmpty = XTool.IsTableEmpty(eventBuffs)
    self.TxtTitle2.gameObject:SetActiveEx(not isEventEmpty)
    self.PanelEvent.gameObject:SetActiveEx(not isEventEmpty)
    self:RefreshGridBuffs(eventBuffs, #volatilityBuffs, self.PanelEvent)
    -- 线
    self.Line.gameObject:SetActiveEx(not isVolatilityEmpty and not isEventEmpty)

    -- 延迟一帧刷新高度
    XScheduleManager.ScheduleNextFrame(function()
        self:RefreshHeight()
        self.CanvasGroup.alpha = 1
    end)
end

function XUiPanelBuffDetailBubble:RefreshGridBuffs(ids, startIndex, parentUi)
    if XTool.IsTableEmpty(ids) then
        return
    end
    for index, id in pairs(ids) do
        index = index + startIndex
        local grid = self.GridBuffList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridBuff, parentUi)
            self.GridBuffList[index] = grid
        end
        -- 显示
        grid.gameObject:SetActiveEx(true)
        -- 设置父物体
        grid.transform:SetParent(parentUi, false)
        -- 显示在最后一个
        grid.transform:SetAsLastSibling()
        local buffId = self._Control.BuffSubControl:GetBuffIdById(id)
        grid:GetObject("RImgBuff"):SetRawImage(self._Control.BuffSubControl:GetBuffIcon(buffId))
        -- 剩余回合数
        local remainingRound = self._Control.BuffSubControl:GetBuffRemainingTurnById(id)
        grid:GetObject("PanelNum").gameObject:SetActiveEx(remainingRound >= 0)
        grid:GetObject("TxtNum").text = remainingRound >= 0 and remainingRound or ""
        grid:GetObject("TxtMarket").text = self._Control.BuffSubControl:GetBuffDesc(buffId)
    end
end

function XUiPanelBuffDetailBubble:HideGridBuff()
    for _, grid in pairs(self.GridBuffList) do
        grid.gameObject:SetActiveEx(false)
    end
end

function XUiPanelBuffDetailBubble:RefreshHeight()
    -- 实际高度
    local height = self.Content.rect.height
    -- 设置高度
    if height < self.MaxHeight then
        self.Transform.sizeDelta = CS.UnityEngine.Vector2(self.Width, height)
    else
        self.Transform.sizeDelta = CS.UnityEngine.Vector2(self.Width, self.MaxHeight)
    end
end

return XUiPanelBuffDetailBubble

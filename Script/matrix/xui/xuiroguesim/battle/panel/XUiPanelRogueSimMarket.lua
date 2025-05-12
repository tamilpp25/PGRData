-- 市场情况
---@class XUiPanelRogueSimMarket : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimMarket = XClass(XUiNode, "XUiPanelRogueSimMarket")

function XUiPanelRogueSimMarket:OnStart()
    self.GridNews.gameObject:SetActiveEx(false)
    self.GridBuff.gameObject:SetActiveEx(false)
    self.TxtNone.gameObject:SetActiveEx(false)
    ---@type XUiComponent.XUiButton[]
    self.GridNewsList = {}
    ---@type XUiComponent.XUiButton[]
    self.GridBuffList = {}
    -- 是否有格子
    self.IsHaveGrid = false
end

function XUiPanelRogueSimMarket:Refresh()
    self.IsHaveGrid = false
    self:RefreshNews()
    self:RefreshBuff()
    self.ListBuff.gameObject:SetActiveEx(self.IsHaveGrid)
    self.TxtNone.gameObject:SetActiveEx(not self.IsHaveGrid)
end

-- 刷新传闻
function XUiPanelRogueSimMarket:RefreshNews()
    local tipIds = self._Control:GetCurTurnTipIds()
    if XTool.IsTableEmpty(tipIds) then
        return
    end
    for index, tipId in pairs(tipIds) do
        self.IsHaveGrid = true
        local grid = self.GridNewsList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridNews, self.ListBuff)
            self.GridNewsList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid.transform:SetAsLastSibling()
        grid:SetRawImage(self._Control:GetTipIcon(tipId))
        grid:ShowTag(true)
        grid:SetNameByGroup(0, 1) -- 默认显示1
        grid.CallBack = function() self:OnTipClick(tipId) end
    end
    for i = #tipIds + 1, #self.GridNewsList do
        self.GridNewsList[i].gameObject:SetActiveEx(false)
    end
end

-- 刷新buff
function XUiPanelRogueSimMarket:RefreshBuff()
    local buffIds = self._Control.BuffSubControl:GetRoundStartShowBuffs()
    for index, id in ipairs(buffIds) do
        self.IsHaveGrid = true
        local grid = self.GridBuffList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridBuff, self.ListBuff)
            self.GridBuffList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid.transform:SetAsLastSibling()
        local buffId = self._Control.BuffSubControl:GetBuffIdById(id)
        grid:SetRawImageEx(self._Control.BuffSubControl:GetBuffIcon(buffId))
        -- 剩余回合数
        local remainingRound = self._Control.BuffSubControl:GetBuffRemainingTurnById(id)
        grid:ShowTag(remainingRound >= 0)
        grid:SetNameByGroup(0, remainingRound >= 0 and remainingRound or "")
        grid.CallBack = function() self:OnBuffClick() end
    end
    for i = #buffIds + 1, #self.GridBuffList do
        self.GridBuffList[i].gameObject:SetActiveEx(false)
    end
end

function XUiPanelRogueSimMarket:OnTipClick(tipId)
    XLuaUiManager.Open("UiRogueSimLog", tipId)
end

function XUiPanelRogueSimMarket:OnBuffClick()
    XLuaUiManager.Open("UiRogueSimComponent", XEnumConst.RogueSim.BubbleType.Buff, self.ListBuff.transform, {
        Alignment = XEnumConst.RogueSim.Alignment.LTB,
    })
end

return XUiPanelRogueSimMarket

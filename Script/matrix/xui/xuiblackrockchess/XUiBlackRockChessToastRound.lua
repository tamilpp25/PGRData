---@class XUiBlackRockChessToastRound : XLuaUi 战前播报
---@field _Control XBlackRockChessControl
local XUiBlackRockChessToastRound = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessToastRound")

function XUiBlackRockChessToastRound:OnStart()
    local nodeGroupId = self._Control:GetChessNodeGroupId()
    local nodeIdx = self._Control:GetChessNodeIdx()
    local nodes = self._Control:GetNodeCfgsByNodeGroupId(nodeGroupId)
    local target
    
    for i = 1, #nodes do
        local node = nodes[i]
        local go = i == 1 and self.GridStage or XUiHelper.Instantiate(self.GridStage, self.GridStage.parent)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        if i == nodeIdx then
            target = go
            uiObject.ImgNow.gameObject:SetActiveEx(true)
        else
            uiObject.ImgNow.gameObject:SetActiveEx(false)
        end
        if node.NodeType == XEnumConst.BLACK_ROCK_CHESS.NODE_TYPE.NORMAL then
            uiObject.Normal.gameObject:SetActiveEx(true)
            uiObject.Boss.gameObject:SetActiveEx(false)
            uiObject.RImgStage:SetRawImage(node.Icon[1])
            uiObject.ImgClear.gameObject:SetActiveEx(i < nodeIdx)
        else
            uiObject.Normal.gameObject:SetActiveEx(false)
            uiObject.Boss.gameObject:SetActiveEx(true)
            for j = 1, #node.Icon do
                local boss = j == 1 and uiObject.GridBoss or XUiHelper.Instantiate(uiObject.GridBoss, uiObject.GridBoss.parent)
                local bossObject = {}
                XUiHelper.InitUiClass(bossObject, boss)
                bossObject.RImgHead:SetRawImage(node.Icon[j])
                bossObject.PanelDead.gameObject:SetActiveEx(i < nodeIdx)
            end
        end
        if i < #nodes then
            XUiHelper.Instantiate(self.ImgLine, self.ImgLine.transform.parent)
        end
    end

    if target then
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.ListStage.transform)
        local scrollWidth = self.ScrollView.transform.sizeDelta.x
        local listWidth = self.ListStage.transform.sizeDelta.x
        local offset = target.anchoredPosition.x + target.sizeDelta.x + 80 - scrollWidth
        self.ScrollView.horizontalNormalizedPosition = math.max(0, offset) / (listWidth - scrollWidth)
    end

    local time = tonumber(self._Control:GetClientConfig("ToastRoundShowTime"))
    local timerId = XScheduleManager.ScheduleOnce(handler(self, self.Close), time)
    self:_AddTimerId(timerId)
end

function XUiBlackRockChessToastRound:OnDestroy()
    self:StopAllTweener()
end

return XUiBlackRockChessToastRound
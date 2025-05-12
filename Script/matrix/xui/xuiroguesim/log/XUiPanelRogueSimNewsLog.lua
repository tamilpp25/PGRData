---@class XUiPanelRogueSimNewsLog : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimNewsLog = XClass(XUiNode, "XUiPanelRogueSimNewsLog")

function XUiPanelRogueSimNewsLog:OnStart()
    self.GridHistoryNews.gameObject:SetActiveEx(false)
    self.HistoryUiObjs = {}
end

function XUiPanelRogueSimNewsLog:OnEnable()
    self:Refresh()
end

function XUiPanelRogueSimNewsLog:Refresh()
    -- 当前传闻
    local curTurn = self._Control:GetCurTurnNumber()
    local title = self._Control:GetClientConfig("BattleRoundNumDesc", 1)
    local tipIds = self._Control:GetCurTurnTipIds()
    local isShowCurTips = #tipIds > 0
    self.GridNews.gameObject:SetActiveEx(isShowCurTips)
    self.TxtTitleCur.gameObject:SetActiveEx(isShowCurTips)
    if isShowCurTips then
        local uiObj = self.GridNews:GetComponent("UiObject")
        uiObj:GetObject("TxtTitle").text = string.format(title, curTurn)
        uiObj:GetObject("TxtDetail").text = self:GetTipsContent(tipIds)
    end
    
    -- 历史传闻
    local recordDic = self._Control:GetTipRecordList()
    local records = {}
    for _, record in pairs(recordDic) do
        if record:GetTurnNumber() ~= curTurn then
            table.insert(records, record)
        end
    end
    table.sort(records, function(a, b) return a.TurnNumber < b.TurnNumber end)
    for _, uiObj in pairs(self.HistoryUiObjs) do
        uiObj.gameObject:SetActiveEx(false)
    end
    local isShowHistory = #records > 0
    self.TxtTitleHistory.gameObject:SetActiveEx(isShowHistory)
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i, record in ipairs(records) do
        local uiObj = self.HistoryUiObjs[i]
        if not uiObj then
            local go = CSInstantiate(self.GridHistoryNews, self.GridHistoryNews.transform.parent)
            uiObj = go:GetComponent("UiObject")
            self.HistoryUiObjs[i] = uiObj
        end
        uiObj.gameObject:SetActiveEx(true)
        uiObj:GetObject("TxtTitle").text = string.format(title, record:GetTurnNumber())
        uiObj:GetObject("TxtDetail").text = self:GetTipsContent(record:GetTipIds())
    end
    
    -- 无传闻
    local isEmpty = not isShowCurTips and not isShowHistory
    self.PanelEmpty.gameObject:SetActiveEx(isEmpty)
end

-- 获取传闻内容
function XUiPanelRogueSimNewsLog:GetTipsContent(tipIds)
    local content = ""
    for i, tipId in ipairs(tipIds) do
        if i > 1 then
            content = content .. "\n"
        end
        content = content .. self._Control:GetTipContent(tipId)
    end
    return content
end

return XUiPanelRogueSimNewsLog

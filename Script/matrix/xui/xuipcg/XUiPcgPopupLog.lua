---@class XUiPcgPopupLog : XLuaUi
---@field private _Control XPcgControl
local XUiPcgPopupLog = XLuaUiManager.Register(XLuaUi, "UiPcgPopupLog")

function XUiPcgPopupLog:OnAwake()
    self.MAX_ROUND_CNT = 2
    self.GridRound.gameObject:SetActiveEx(false)
    self.GridLogs = {}
    self:RegisterUiEvents()
end

function XUiPcgPopupLog:OnStart()
    
end

function XUiPcgPopupLog:OnEnable()
    self:Refresh()
end

function XUiPcgPopupLog:OnDisable()
    self:ClearMoveTimer()
end

function XUiPcgPopupLog:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBgClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiPcgPopupLog:OnBtnCloseClick()
    self:Close()
end

-- 刷新界面
function XUiPcgPopupLog:Refresh()
    local roundLogs = self._Control.GameSubControl:GetRoundLogs()
    local roundCnt = #roundLogs
    if roundCnt <= self.MAX_ROUND_CNT then
        self.RoundLogs = roundLogs
    else
        self.RoundLogs = {}
        local startIndex = roundCnt - self.MAX_ROUND_CNT + 1
        for i = startIndex, roundCnt do
            table.insert(self.RoundLogs, roundLogs[i])
        end
    end
    
    local XUiGridPcgLog = require("XUi/XUiPcg/XUiGrid/XUiGridPcgLog")
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i, roundLog in ipairs(self.RoundLogs) do
        local grid = self.GridLogs[i]
        if not grid then
            local go = CSInstantiate(self.GridRound, self.GridRound.transform.parent)
            grid = XUiGridPcgLog.New(go, self)
            table.insert(self.GridLogs, grid)
        end
        grid:Open()
        grid:SetData(roundLog)
    end
    
    self:MoveToLast()
end

-- 移动到最后
function XUiPcgPopupLog:MoveToLast()
    self:ClearMoveTimer()
    self.MoveTimer = XScheduleManager.ScheduleOnce(function()
        local contentHeight = self.Content.rect.height
        local viewportHeight = self.Content.transform.parent:GetComponent("RectTransform").rect.height
        local posY = contentHeight - viewportHeight
        self.Content.anchoredPosition = CS.UnityEngine.Vector2(self.Content.anchoredPosition.x, posY)
    end, 50)
end

function XUiPcgPopupLog:ClearMoveTimer()
    if self.MoveTimer then
        XScheduleManager.UnSchedule(self.MoveTimer)
        self.MoveTimer = nil
    end
end

return XUiPcgPopupLog

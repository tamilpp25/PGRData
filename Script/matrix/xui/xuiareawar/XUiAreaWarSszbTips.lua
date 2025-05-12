local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
--区块净化进度弹窗
local XUiAreaWarSszbTips = XLuaUiManager.Register(XLuaUi, "UiAreaWarSszbTips")

function XUiAreaWarSszbTips:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self.Grid256New.gameObject:SetActiveEx(false)
end

function XUiAreaWarSszbTips:OnStart(closeCb)
    self.CloseCb = closeCb
    self.RewardGrids = {}

    self:Refresh()
end

function XUiAreaWarSszbTips:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiAreaWarSszbTips:OnGetEvents()
    return {
        XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE
    }
end

function XUiAreaWarSszbTips:OnNotify(evt, ...)
    local args = {...}
    if evt == XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE then
        self:Refresh()
    end
end

function XUiAreaWarSszbTips:Refresh()
    local oldCount, newCount = XDataCenter.AreaWarManager.GetRecordClearBlockCount()
    self.TxtCountOld.text = oldCount
    self.TxtCountNew.text = newCount

    local rewards = XDataCenter.AreaWarManager.GetRecordNewClearBlockRewards()
    for index, item in ipairs(rewards) do
        local grid = self.RewardGrids[index]
        if not grid then
            local go = CSObjectInstantiate(self.Grid256New, self.Container)
            grid = XUiGridCommon.New(self, go)
            self.RewardGrids[index] = grid
        end

        grid:Refresh(item)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #rewards + 1, #self.RewardGrids do
        self.RewardGrids[index].GameObject:SetActiveEx(false)
    end
end

---@class XUiRogueSimSettlement : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimSettlement = XLuaUiManager.Register(XLuaUi, "UiRogueSimSettlement")

function XUiRogueSimSettlement:OnAwake()
    self.PanelStar.gameObject:SetActiveEx(false)
    self.PanelSettle.gameObject:SetActiveEx(false)
end

function XUiRogueSimSettlement:OnStart()
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
    self:OpenPanelStar()
end

function XUiRogueSimSettlement:OnDisable()
    -- 清理结算数据
    self._Control:ClearStageSettleData()
end

-- 打开星级奖励
function XUiRogueSimSettlement:OpenPanelStar()
    if not self.StarUi then
        ---@type XUiPanelRogueSimStar
        self.StarUi = require("XUi/XUiRogueSim/Settlement/XUiPanelRogueSimStar").New(self.PanelStar, self)
    end
    self.StarUi:Open()
    self.StarUi:Refresh()
end

-- 关闭星级奖励
function XUiRogueSimSettlement:ClosePanelStar()
    if self.StarUi then
        self.StarUi:Close()
    end
end

-- 打开结算
function XUiRogueSimSettlement:OpenPanelSettle()
    self:ClosePanelStar()
    if not self.SettleUi then
        ---@type XUiPanelRogueSimSettle
        self.SettleUi = require("XUi/XUiRogueSim/Settlement/XUiPanelRogueSimSettle").New(self.PanelSettle, self)
    end
    self.SettleUi:Open()
    self.SettleUi:Refresh()
end

return XUiRogueSimSettlement

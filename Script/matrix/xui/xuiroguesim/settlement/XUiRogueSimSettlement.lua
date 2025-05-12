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
    self.Super.OnDisable(self)
    -- 清理结算数据
    self._Control:ClearStageSettleData()
    -- 清除可重复触发的引导记录
    self._Control:ClearGuideRecord()
    -- 清理临时生产和出售计划
    self._Control:ClearTempProduceAndSellPlan()
end

-- 打开星级奖励
function XUiRogueSimSettlement:OpenPanelStar()
    if not self.StarUi then
        ---@type XUiPanelRogueSimStar
        self.StarUi = require("XUi/XUiRogueSim/Settlement/XUiPanelRogueSimStar").New(self.PanelStar, self)
    end
    self.StarUi:Open()
    self.StarUi:Refresh()
    self:PlayAnimationWithMask("PanelStarEnable")
end

-- 打开结算
function XUiRogueSimSettlement:OpenPanelSettle()
    if not self.SettleUi then
        ---@type XUiPanelRogueSimSettle
        self.SettleUi = require("XUi/XUiRogueSim/Settlement/XUiPanelRogueSimSettle").New(self.PanelSettle, self)
    end
    self.SettleUi:Open()
    self.SettleUi:Refresh()
    self:PlayAnimationWithMask("PanelSettleEnable")
end

return XUiRogueSimSettlement

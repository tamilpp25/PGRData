local XUiSpecialTrainBreakthroughRankPersonal = require("XUi/XUiSpecialTrainBreakthrough/Rank/XUiSpecialTrainBreakthroughRankPersonal")
local XUiSpecialTrainBreakthroughRankTeam = require("XUi/XUiSpecialTrainBreakthrough/Rank/XUiSpecialTrainBreakthroughRankTeam")

---@class XUiSpecialTrainBreakthroughRank:XLuaUi
local XUiSpecialTrainBreakthroughRank = XLuaUiManager.Register(nil, "UiSpecialTrainBreakthroughRank")

local TabIndex = {
    None = 0,
    --Personal = 1,
    --Team = 2,
    Team = 1
}

function XUiSpecialTrainBreakthroughRank:Ctor()
    self._TabIndex = TabIndex.None
    ---@type XUiSpecialTrainBreakthroughRankPersonal
    self._PanelPersonal = false
    ---@type XUiSpecialTrainBreakthroughRankTeam
    self._PanelTeam = false
end

function XUiSpecialTrainBreakthroughRank:OnStart()
    self:BindExitBtns()
    self._PanelPersonal = XUiSpecialTrainBreakthroughRankPersonal.New(self.PanelRankInfoPersonal, self)
    self._PanelTeam = XUiSpecialTrainBreakthroughRankTeam.New(self.PanelRankInfoTeam , self)

    --页签
    --local btnGroup = { self.BtnTab01, self.BtnTab02 }
    self.BtnTab01.gameObject:SetActiveEx(false)
    local btnGroup = { self.BtnTab02 }
    self.PanelTag:Init(btnGroup, function(index)
        self:SetTabIndex(index)
    end)
    self.PanelTag:SelectIndex(TabIndex.Team, true)
    self.PanelTag.gameObject:SetActiveEx(false)
end

function XUiSpecialTrainBreakthroughRank:SetTabIndex(tabIndex)
    if self._TabIndex == tabIndex then
        return
    end
    self._TabIndex = tabIndex
    self:UpdateTab()
end

function XUiSpecialTrainBreakthroughRank:UpdateTab()
    if self._TabIndex == TabIndex.Personal then
        self._PanelPersonal.GameObject:SetActiveEx(true)
        self._PanelTeam.GameObject:SetActiveEx(false)
        self._PanelPersonal:Update()
        return
    end

    if self._TabIndex == TabIndex.Team then
        self._PanelPersonal.GameObject:SetActiveEx(false)
        self._PanelTeam.GameObject:SetActiveEx(true)
        self._PanelTeam:Update()
        return
    end
end

function XUiSpecialTrainBreakthroughRank:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_UPDATE_RANK_PERSONAL, self.UpdateTab, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_UPDATE_RANK_TEAM, self.UpdateTab, self)
end

function XUiSpecialTrainBreakthroughRank:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_UPDATE_RANK_PERSONAL, self.UpdateTab, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_UPDATE_RANK_TEAM, self.UpdateTab, self)
end

return XUiSpecialTrainBreakthroughRank
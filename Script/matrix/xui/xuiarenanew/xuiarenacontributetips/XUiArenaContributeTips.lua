local XUiArenaContributeTipsReward = require("XUi/XUiArenaNew/XUiArenaContributeTips/XUiArenaContributeTipsReward")
local XUiArenaContributeTipsDetail = require("XUi/XUiArenaNew/XUiArenaContributeTips/XUiArenaContributeTipsDetail")

---@class XUiArenaContributeTips : XLuaUi
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field TxtLv UnityEngine.UI.Text
---@field PanelContent UnityEngine.RectTransform
---@field TxtTips UnityEngine.UI.Text
---@field PanelContribute UnityEngine.RectTransform
---@field PanelTab XUiButtonGroup
---@field GridArenaLevel1 XUiComponent.XUiButton
---@field GridArenaLevel2 XUiComponent.XUiButton
---@field GridArenaLevel3 XUiComponent.XUiButton
---@field GridArenaLevel4 XUiComponent.XUiButton
---@field GridRewardUp UnityEngine.RectTransform
---@field GridRewardDown UnityEngine.RectTransform
---@field GridRewardKeep UnityEngine.RectTransform
---@field _Control XArenaControl
local XUiArenaContributeTips = XLuaUiManager.Register(XLuaUi, "UiArenaContributeTips")

-- region 生命周期

function XUiArenaContributeTips:OnAwake()
    ---@type table<number, XUiArenaContributeTipsReward>
    self._GridRewardMap = nil
    ---@type XUiArenaContributeTipsDetail
    self._PanelContributeUi = nil
    self._CurrentSelectIndex = nil
    self._ChallengeId = nil
    self._ArenaLevel = nil
    self._ChallengeList = nil
    self._ScrollTimer = nil

    self:_RegisterButtonClicks()
end

function XUiArenaContributeTips:OnStart(challengeId, arenaLevel, wave, isScrollEnd)
    self._ChallengeId = self._Control:GetActivityChallengeId()
    self._ArenaLevel = arenaLevel
    self._ChallengeList = self._Control:GetPlayerLevelChallengeListById(challengeId)
    self._ContributeDetailUi = XUiArenaContributeTipsDetail.New(self.PanelContribute, self, challengeId)
    self._IsScrollEnd = isScrollEnd

    self:_InitGridReward()
    self:_InitGridArenaLevel(wave)
end

function XUiArenaContributeTips:OnEnable()
    self:_RefreshLevel()
    self:_RefreshScroll()
end

function XUiArenaContributeTips:OnDisable()
    self:_RemoveScrollTimer()
end

-- endregion

-- region 按钮事件

function XUiArenaContributeTips:OnBtnTanchuangCloseClick()
    self:Close()
    XEventManager.DispatchEvent(XEventId.EVENT_ARENA_RESHOW_MAIN_UI)
end

function XUiArenaContributeTips:OnLevelTagSelect(index)
    if self._CurrentSelectIndex ~= index then
        local challengeId = self._ChallengeList[index]

        self._CurrentSelectIndex = index
        self:_RefreshGridReward(challengeId)
        self._ContributeDetailUi:Refresh(challengeId)
    end
end

-- endregion

-- region 私有方法

function XUiArenaContributeTips:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnTanchuangCloseClick, true)
end

function XUiArenaContributeTips:_RefreshGridReward(challengeId)
    for region, grid in pairs(self._GridRewardMap) do
        grid:Refresh(challengeId)
    end
end

function XUiArenaContributeTips:_RefreshLevel()
    local maxPoint = self._Control:GetAreaMaxProtectScore()
    local currentPoint = self._Control:GetActivityProtectedScore()

    self.TxtLv.text = self._Control:GetCurrentChallengeLevelNotDescStr()
    self.TxtTips.text = XUiHelper.GetText("ArenaChargePointsDesc", currentPoint, maxPoint)
end

function XUiArenaContributeTips:_RefreshScroll()
    if self._IsScrollEnd then
        self:_RemoveScrollTimer()
        self._ScrollTimer = XScheduleManager.ScheduleOnce(Handler(self, self._ScrollTo), 1)
    end
end

function XUiArenaContributeTips:_InitGridArenaLevel(wave)
    local challengeList = self._ChallengeList
    local buttonGroup = {}
    local selectIndex = 1

    self._GridLevelList = {}
    for i, challengeId in pairs(challengeList) do
        local button = self["GridArenaLevel" .. i]

        if button then
            local currentArenaLv = self._Control:GetChallengeArenaLvById(challengeId)
            local contributeScore = self._Control:GetChallengeContributeScoreById(challengeId)
            local number = XTool.IsTableEmpty(contributeScore) and 0 or #contributeScore

            if currentArenaLv == self._ArenaLevel then
                selectIndex = i
                button:ShowTag(true)

                if self._Control:IsInActivityOverStatus() then
                    button:ActiveTextByGroup(1, false)
                else
                    button:ActiveTextByGroup(1, true)
                    button:SetNameByGroup(1, XUiHelper.GetText("ArenaWaveRate", wave))
                end
            else
                button:ShowTag(false)
                button:ActiveTextByGroup(1, false)
            end
            button:SetRawImage(self._Control:GetArenaLevelWordIconById(currentArenaLv))
            button:SetNameByGroup(0, XUiHelper.GetText("ArenaLevelPeopleNumber", number))
            table.insert(buttonGroup, button)
        end
    end

    self.PanelTab:Init(buttonGroup, Handler(self, self.OnLevelTagSelect))
    self.PanelTab:SelectIndex(selectIndex)
end

function XUiArenaContributeTips:_InitGridReward()
    self._GridRewardMap = {}
    for key, regionType in pairs(XEnumConst.Arena.RegionType) do
        self._GridRewardMap[regionType] = XUiArenaContributeTipsReward.New(self["GridReward" .. key], self, regionType)
    end
end

function XUiArenaContributeTips:_ScrollTo()
    self._ScrollTimer = nil
    XUiHelper.ScrollTo(self.PanelDetail, self.PanelContribute)
end

function XUiArenaContributeTips:_RemoveScrollTimer()
    if self._ScrollTimer then
        XScheduleManager.UnSchedule(self._ScrollTimer)
        self._ScrollTimer = nil
    end
end

-- endregion

return XUiArenaContributeTips

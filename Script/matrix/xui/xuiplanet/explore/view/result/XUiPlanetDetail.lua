local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPlanetExploreGridCharacter = require("XUi/XUiPlanet/Explore/View/Stage/XUiPlanetExploreGridCharacter")

---@class XUiPlanetDetail:XLuaUi
local XUiPlanetDetail = XLuaUiManager.Register(XLuaUi, "UiPlanetDetail")

function XUiPlanetDetail:Ctor()
    ---@type XPlanetResult
    self._Result = false
    self._RewardGrids = {}
end

function XUiPlanetDetail:OnAwake()
    --self:RegisterClickEvent(self.BtnClose, self.OnClickLeaveExplore)
    self:RegisterClickEvent(self.BtnConfirm, self.OnClickLeaveExplore)
    self:RegisterClickEvent(self.BtnCancel, self.OnClickChallengeAgain)

    self.PanelRoleNone = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelDetail/Bg/PanelRoleNone", "RectTransform")
    self.PanelDropNone = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelDetail/Bg/PanelDropNone", "RectTransform")
    self.TxtTips = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelDetail/Bg/TxtTips", "Text")
    if self.TxtTips then    -- 本期不显示失败文本
        self.TxtTips.gameObject:SetActiveEx(false)
    end
    self.GridCommon.gameObject:SetActiveEx(false)
end

---@param result XPlanetResult
function XUiPlanetDetail:OnStart(result)
    self._Result = result
    self._Scene = XDataCenter.PlanetManager.GetPlanetStageScene()
    self._Scene:UpdateCameraInSettle(function()
        XEventManager.DispatchEvent(XEventId.EVENT_PLANET_PLAY_ANIMATION_ON_RESULT, result:IsWin())
    end)

    -- 先暂停, 等待结算
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_PAUSE_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.RESULT)
end

function XUiPlanetDetail:OnEnable()
    self:Update()
end

function XUiPlanetDetail:OnDisable()
    XDataCenter.FunctionEventManager.UnLockFunctionEvent()
end

function XUiPlanetDetail:Update()
    local result = self._Result
    -- 标题
    local allTitleIcon = { self.IconLose, self.IconWin, self.IconQuit }
    for k, v in pairs(allTitleIcon) do
        v.gameObject:SetActiveEx(false)
    end
    if result:GetSettleType() == XPlanetExploreConfigs.SETTLE_TYPE.Quit then
        self.IconQuit.gameObject:SetActiveEx(true)
    elseif result:GetSettleType() == XPlanetExploreConfigs.SETTLE_TYPE.Lose then
        self.IconLose.gameObject:SetActiveEx(true)
    else
        self.IconWin.gameObject:SetActiveEx(true)
    end

    self.TxtNumber.text = XUiHelper.GetText("PlanetRunningRound", result:GetRound())

    local characters = self._Result:GetCharacterUnlock()
    for i = 1, 3 do
        local uiGrid = self["GridRole" .. i]
        if characters[i] then
            local role = XUiPlanetExploreGridCharacter.New(uiGrid)
            role:Update(characters[i])
            uiGrid.gameObject:SetActiveEx(true)
        else
            uiGrid.gameObject:SetActiveEx(false)
        end
    end

    local rewards = result:GetReward()
    local stageId = result:GetStageId()
    local stageRewardList = XRewardManager.GetRewardList(XPlanetStageConfigs.GetStageRewardId(stageId))
    local firstRewardDir = {}
    for index, reward in ipairs(rewards or {}) do
        local grid = self._RewardGrids[index]
        if not grid then
            local ui = index == 1 and self.GridCommon or CS.UnityEngine.Object.Instantiate(self.GridCommon, self.GridCommon.parent.transform)
            grid = XUiGridCommon.New(self.RootUi, ui)
            self._RewardGrids[index] = grid
        end
        grid:Refresh(reward)

        -- 首通奖励
        local isFirstReward = false
        for _, stageReward in ipairs(stageRewardList) do
            if reward.TemplateId == stageReward.TemplateId and reward.Count == stageReward.Count and not firstRewardDir[reward.TemplateId] then
                isFirstReward = true
                firstRewardDir[reward.TemplateId] = true
                break
            end
        end
        grid:SetPanelTag(result:GetFirstPass() and isFirstReward)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #rewards + 1, #self._RewardGrids do
        local grid = self._RewardGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end

    if #characters == 0 then
        self.PanelRoleNone.gameObject:SetActiveEx(true)
    else
        self.PanelRoleNone.gameObject:SetActiveEx(false)
    end

    if #rewards == 0 then
        self.PanelDropNone.gameObject:SetActiveEx(true)
    else
        self.PanelDropNone.gameObject:SetActiveEx(false)
    end
end

function XUiPlanetDetail:OnClickLeaveExplore()
    self:CloseOtherUi()
    XLuaUiManager.Close(self.Name)
end

function XUiPlanetDetail:OnClickChallengeAgain()
    self:CloseOtherUi()
    local stageId = self._Result:GetStageId()
    local stage = XDataCenter.PlanetExploreManager.GetStage(stageId)
    self.GameObject:SetActiveEx(false)
    XDataCenter.PlanetExploreManager.EnterStage(stage, function()
        XLuaUiManager.SafeClose(self.Name)
    end)
end

function XUiPlanetDetail:CloseOtherUi()
    XLuaUiManager.SafeClose("UiPlanetBattleMain")
    XLuaUiManager.SafeClose("UiPlanetFightMain")
end

return XUiPlanetDetail

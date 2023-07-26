local XUiGridMonsterCombatBtn = require("XUi/XUiMonsterCombat/XUiGridMonsterCombatBtn")
-- BVB主界面
---@class XUiMonsterCombatMain : XLuaUi
---@field GridBtnChapters table<number, XUiGridMonsterCombatBtn>
local XUiMonsterCombatMain = XLuaUiManager.Register(XLuaUi, "UiMonsterCombatMain")

function XUiMonsterCombatMain:OnAwake()
    self:RegisterUiEvents()
    self.GridBtnChapters = {}
    self.GridRewardList = {}
end

function XUiMonsterCombatMain:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    -- 开启自动关闭检查
    self.EndTime = XDataCenter.MonsterCombatManager.GetActivityEndTime()
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if isClose then
            XDataCenter.MonsterCombatManager.OnActivityEnd(true)
        else
            self:UpdateTimer()
        end
    end)
end

function XUiMonsterCombatMain:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateTimer()
    self:RefreshPanelReward()
    self:RefreshBtnChapter()
    self:RefreshRedPoint()
end

function XUiMonsterCombatMain:RefreshPanelReward()
    local limitTastList = XDataCenter.MonsterCombatManager.GetActivityTaskList()
    if XTool.IsTableEmpty(limitTastList) then
        self.Grid256New.gameObject:SetActiveEx(false)
        return
    end
    local config = XDataCenter.TaskManager.GetTaskTemplate(limitTastList[1].Id)
    self.GridRewardList = self.GridRewardList or {}
     local rewardId = config.RewardId
     local rewards = XRewardManager.GetRewardList(rewardId)
     local rewardsNum = #rewards
     for i = 1, rewardsNum do
         local grid = self.GridRewardList[i]
         if not grid then
             local go = i == 1 and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.PanelReward)
             grid = XUiGridCommon.New(self, go)
             self.GridRewardList[i] = grid
         end
         grid:Refresh(rewards[i])
         grid.GameObject:SetActiveEx(true)
     end
     for i = rewardsNum + 1, #self.GridRewardList do
         self.GridRewardList[i].GameObject:SetActiveEx(false)
     end
end

function XUiMonsterCombatMain:RefreshBtnChapter()
    local chapterIds = XDataCenter.MonsterCombatManager.GetActivityChapterIds()
    for i, chapterId in pairs(chapterIds) do
        local grid = self.GridBtnChapters[i]
        if not grid then
            local go = self["GridChapter0" .. i]
            grid = XUiGridMonsterCombatBtn.New(go, self)
            self.GridBtnChapters[i] = grid
        end
        grid:Refresh(chapterId)
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiMonsterCombatMain:RefreshRedPoint()
    -- 怪物图鉴红点
    local isMonsterShowRed = XDataCenter.MonsterCombatManager.CheckNewUnlockMonsterRedPoint()
    self.BtnGuide:ShowReddot(isMonsterShowRed)
    -- 任务红点
    local isTaskShowRed = XDataCenter.MonsterCombatManager.CheckTaskRewardRedPoint()
    self.BtnGift:ShowReddot(isTaskShowRed)
end

function XUiMonsterCombatMain:UpdateTimer()
    if XTool.UObjIsNil(self.TxtTitleDate) then
        return
    end
    local endTime = self.EndTime
    local leftTime = endTime - XTime.GetServerNowTimestamp()
    if leftTime <= 0 then
        leftTime = 0
    end
    local timeText = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    self.TxtTitleDate.text = timeText
end

function XUiMonsterCombatMain:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGuide, self.OnBtnGuideClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGift, self.OnBtnGiftClick)

    self:BindHelpBtn(self.BtnHelp, XDataCenter.MonsterCombatManager.GetHelpKey())
end

function XUiMonsterCombatMain:OnBtnBackClick()
    self:Close()
end

function XUiMonsterCombatMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

-- 怪物图鉴
function XUiMonsterCombatMain:OnBtnGuideClick()
    XLuaUiManager.Open("UiMonsterCombatRoleList", XMonsterCombatConfigs.MonsterInterfaceType.Monster)
end

-- 活动奖励
function XUiMonsterCombatMain:OnBtnGiftClick()
    XLuaUiManager.Open("UiMonsterCombatTask")
end

return XUiMonsterCombatMain
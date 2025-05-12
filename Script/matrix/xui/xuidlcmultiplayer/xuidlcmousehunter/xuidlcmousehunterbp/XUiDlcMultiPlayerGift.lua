local XUiDlcMultiPlayerGiftTask = require("XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMouseHunterBp/XUiDlcMultiPlayerGiftTask")
local XUiDlcMultiPlayerGiftReward = require("XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMouseHunterBp/XUiDlcMultiPlayerGiftReward")
local XUiDlcMultiPlayerGiftLevel = require("XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMouseHunterBp/XUiDlcMultiPlayerGiftLevel")

---@class XUiDlcMultiPlayerGift:XLuaUi
---@field TxtTitle UnityEngine.UI.Text
---@field LevelPanel UnityEngine.RectTransform
---@field RewardPanel UnityEngine.RectTransform
---@field TaskPanel UnityEngine.RectTransform
---@field BtnReward XUiComponent.XUiButton
---@field BtnTask XUiComponent.XUiButton
---@field BtnTaskDaily XUiComponent.XUiButton
---@field BtnTaskChallenge XUiComponent.XUiButton
---@field BtnClose XUiComponent.XUiButton
---@field TabBtnGroup XUiComponent.XUiButtonGroup
---@field _Control XDlcMultiMouseHunterControl
local XUiDlcMultiPlayerGift = XLuaUiManager.Register(XLuaUi, "UiDlcMultiPlayerGift")

local TaskEnum = XMVCA.XDlcMultiMouseHunter.DlcMouseHunterTaskType

function XUiDlcMultiPlayerGift:OnAwake()
    --变量声明
    self._CurSelectTabIndex = 0
    self.BtnGroupList = nil
    self.TabIndex = nil
    self.TabPanelMap = nil

    --Panel实例化
    self.LevelPanelUi = XUiDlcMultiPlayerGiftLevel.New(self.LevelPanel, self)
    self.RewardPanelUi = XUiDlcMultiPlayerGiftReward.New(self.RewardPanel, self)
    self.TaskPanelUi = XUiDlcMultiPlayerGiftTask.New(self.TaskPanel, self)
    self.RewardPanelUi:Hide()
    self.TaskPanelUi:Hide()
end

function XUiDlcMultiPlayerGift:OnStart()
    --注册点击事件
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)

    --业务初始化
    self:_InitText()
    self:_InitTab()
end

function XUiDlcMultiPlayerGift:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_BP_REWARDS, self._RefreshReawrdRedPoint, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self._RefreshTaskRedPoint, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self._RefreshTaskRedPoint, self)

    self:_RefreshReawrdRedPoint()
    self:_RefreshTaskRedPoint()
end

function XUiDlcMultiPlayerGift:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_BP_REWARDS, self._RefreshReawrdRedPoint, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self._RefreshTaskRedPoint, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self._RefreshTaskRedPoint, self)
end

-- region 业务逻辑
function XUiDlcMultiPlayerGift:_InitText()
    -- self.TxtTitle.text = XUiHelper.GetText("MultiMouseHunterBpTask")
    self.BtnReward:SetName(XUiHelper.GetText("MultiMouseHunterBpReawrd"))
    self.BtnTask:SetName(XUiHelper.GetText("MultiMouseHunterBpTask"))
    self.BtnTaskDaily:SetName(XUiHelper.GetText("MultiMouseHunterBpDaily"))
    self.BtnTaskChallenge:SetName(XUiHelper.GetText("MultiMouseHunterBpChallenge"))
end

function XUiDlcMultiPlayerGift:_InitTab()
    self.BtnGroupList = {
        self.BtnReward,
        self.BtnTask,
        self.BtnTaskDaily,
        self.BtnTaskChallenge,
    }
    self.TabIndex = {
        Reward = 1,
        TaskDaily = 3,
        TaskChallenge = 4
    }
    self.TabPanelMap = {
        [self.TabIndex.Reward] = self.RewardPanelUi,
        [self.TabIndex.TaskDaily] = self.TaskPanelUi,
        [self.TabIndex.TaskChallenge] = self.TaskPanelUi,
    }

    self.BtnTaskDaily.SubGroupIndex = 2
    self.BtnTaskChallenge.SubGroupIndex = 2

    self.TabBtnGroup:Init(self.BtnGroupList, Handler(self, self.OnSelectedTag))
    self.TabBtnGroup:SelectIndex(1)
end

function XUiDlcMultiPlayerGift:_RefreshTaskRedPoint()
    local dailyTaskRedPoint = self._Control:CheckBpTaskRedPoint(TaskEnum.Daily)
    local challengeTaskRedPoint = self._Control:CheckBpTaskRedPoint(TaskEnum.Challenge)
    self.BtnTask:ShowReddot(dailyTaskRedPoint or challengeTaskRedPoint)
    self.BtnTaskDaily:ShowReddot(dailyTaskRedPoint)
    self.BtnTaskChallenge:ShowReddot(challengeTaskRedPoint)
end

function XUiDlcMultiPlayerGift:_RefreshReawrdRedPoint()
    self.BtnReward:ShowReddot(self._Control:CheckBpRewardRedPoint())
end

-- endregion

-- region 按钮事件
function XUiDlcMultiPlayerGift:OnBtnCloseClick()
    self:Close()
end

function XUiDlcMultiPlayerGift:OnSelectedTag(index)
    if self._CurSelectTabIndex == index then
        return
    end
    if self.TabPanelMap[self._CurSelectTabIndex] then
        self.TabPanelMap[self._CurSelectTabIndex]:Hide()
    end
    self._CurSelectTabIndex = index

    local panelUi = self.TabPanelMap[index]
    if index == self.TabIndex.TaskChallenge then
        panelUi:Show(TaskEnum.Challenge)
    elseif index == self.TabIndex.TaskDaily then
        panelUi:Show(TaskEnum.Daily)
    else
        panelUi:Show()
    end
end
-- endregion

return XUiDlcMultiPlayerGift
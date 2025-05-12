local XUiTheatre4LvRewardBattlePass = require("XUi/XUiTheatre4/System/Reward/XUiTheatre4LvRewardBattlePass")
local XUiTheatre4LvRewardTask = require("XUi/XUiTheatre4/System/Reward/XUiTheatre4LvRewardTask")

---@class XUiTheatre4LvReward : XLuaUi
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field ImgPercentNormal UnityEngine.UI.Image
---@field BtnReward XUiComponent.XUiButton
---@field PanelTaskStory UnityEngine.RectTransform
---@field TxtLv UnityEngine.UI.Text
---@field TxtExpNum UnityEngine.UI.Text
---@field IconBp UnityEngine.UI.RawImage
---@field BtnGroup XUiButtonGroup
---@field BtnTab1 XUiComponent.XUiButton
---@field BtnTab2 XUiComponent.XUiButton
---@field BtnChild01 XUiComponent.XUiButton
---@field BtnChild02 XUiComponent.XUiButton
---@field BtnChild03 XUiComponent.XUiButton
---@field PanelLvReward UnityEngine.RectTransform
---@field _Control XTheatre4Control
local XUiTheatre4LvReward = XLuaUiManager.Register(XLuaUi, "UiTheatre4LvReward")

local TabType = {
    BP = 1,
    AllTask = 2,
    VersionTask = 3,
    ProcessTask = 4,
    ChallengeTask = 5,
}

-- region 生命周期

function XUiTheatre4LvReward:OnAwake()
    ---@type XUiTheatre4LvRewardBattlePass
    self.PanelBattlePassUi = XUiTheatre4LvRewardBattlePass.New(self.PanelLvReward, self)
    ---@type XUiTheatre4LvRewardTask
    self.PanelTaskStoryUi = XUiTheatre4LvRewardTask.New(self.PanelTaskStory, self)

    self._CurrentTabType = TabType.BP
    self._TabGroup = {
        [TabType.BP] = self.BtnTab1,
        [TabType.AllTask] = self.BtnTab2,
        [TabType.VersionTask] = self.BtnChild01,
        [TabType.ProcessTask] = self.BtnChild02,
        [TabType.ChallengeTask] = self.BtnChild03,
    }

    self:_InitUi()
    self:_InitTabGroup()
    self:_RegisterButtonClicks()
end

function XUiTheatre4LvReward:OnEnable()
    self:_RefreshAllRedDot()
    self:_RefreshLevel()
    self:_RegisterListeners()
end

function XUiTheatre4LvReward:OnDisable()
    self:_RemoveListeners()
end

-- endregion

-- region 按钮事件

function XUiTheatre4LvReward:OnBtnRewardClick()
    if self._CurrentTabType == TabType.BP then
        if self._Control.SystemControl:CheckBattlePassHasReward() then
            self._Control:BattlePassGetRewardRequest(XEnumConst.Theatre4.BattlePassGetRewardType.GetAll, nil,
                function(rewardGoodsList)
                    XLuaUiManager.Open("UiTheatre4PopupGetReward", rewardGoodsList)
                end)
        end
    elseif self._CurrentTabType == TabType.ChallengeTask then
        self._Control.SystemControl:FinishAllTaskIdByTaskType(XEnumConst.Theatre4.BattlePassTaskType.ChallengeTask)
    elseif self._CurrentTabType == TabType.ProcessTask then
        self._Control.SystemControl:FinishAllTaskIdByTaskType(XEnumConst.Theatre4.BattlePassTaskType.ProcessTask)
    elseif self._CurrentTabType == TabType.VersionTask then
        self._Control.SystemControl:FinishAllTaskIdByTaskType(XEnumConst.Theatre4.BattlePassTaskType.VersionTask)
    end
end

function XUiTheatre4LvReward:OnBtnGroupSelect(index)
    self._CurrentTabType = index
    if index == TabType.BP then
        self:_RefreshBattlePassPanel()
    elseif index == TabType.VersionTask then
        self:_RefreshTaskStoryList(XEnumConst.Theatre4.BattlePassTaskType.VersionTask)
    elseif index == TabType.ProcessTask then
        self:_RefreshTaskStoryList(XEnumConst.Theatre4.BattlePassTaskType.ProcessTask)
    elseif index == TabType.ChallengeTask then
        self:_RefreshTaskStoryList(XEnumConst.Theatre4.BattlePassTaskType.ChallengeTask)
    end
    self:_RefreshReceiveButton()
end

function XUiTheatre4LvReward:OnRefresh()
    self:_RefreshAllRedDot()
    self:_RefreshReceiveButton()
    self:_RefreshLevel()
end

-- endregion

-- region 私有方法

function XUiTheatre4LvReward:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:RegisterClickEvent(self.BtnReward, self.OnBtnRewardClick, true)
end

function XUiTheatre4LvReward:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE4_BP_REFRESH, self.OnRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.OnRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.OnRefresh, self)
end

function XUiTheatre4LvReward:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE4_BP_REFRESH, self.OnRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.OnRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.OnRefresh, self)
end

function XUiTheatre4LvReward:_InitUi()
    self.BtnTab1:ActiveTextByGroup(1, false)
    self.BtnTab2:ActiveTextByGroup(1, false)
end

function XUiTheatre4LvReward:_InitTabGroup()
    local buttonGroup = self._TabGroup

    for key, index in pairs(XEnumConst.Theatre4.BattlePassTaskType) do
        self["BtnChild0" .. index]:SetNameByGroup(0, self._Control.SystemControl:GetTaskTabNameByTaskType(index))
    end

    self.BtnTab1:SetNameByGroup(0, self._Control:GetClientConfig("BpRewardName", 1))
    self.BtnTab2:SetNameByGroup(0, self._Control:GetClientConfig("BpRewardName", 2))
    self.BtnChild01.SubGroupIndex = 2
    self.BtnChild02.SubGroupIndex = 2
    self.BtnChild03.SubGroupIndex = 2

    self.BtnGroup:Init(buttonGroup, Handler(self, self.OnBtnGroupSelect))
    self.BtnGroup:SelectIndex(TabType.BP)
end

function XUiTheatre4LvReward:_RefreshBattlePassPanel()
    self.PanelBattlePassUi:RefreshCurrent()
    self.PanelBattlePassUi:Open()
    self.PanelTaskStoryUi:Close()
end

function XUiTheatre4LvReward:_RefreshLevel()
    local entity, levelCurrentExp = self._Control.SystemControl:GetCurrentBattlePassEntity()
    local config = entity:GetConfig()
    local totalExp = entity:GetCurrentTotalExp()
    local levelExp = entity:GetCurrentExp()
    local icon = XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.Theatre4BpExperience)
    local maxExp = self._Control.SystemControl:GetBattlePassMaxExp()

    if totalExp >= maxExp then
        self.TxtExpNum.text = self._Control:GetClientConfig("BpFullLevelTip")
        self.ImgPercentNormal.fillAmount = 1
    else
        self.TxtExpNum.text = (totalExp - levelExp) .. "/" .. levelCurrentExp
        self.ImgPercentNormal.fillAmount = (totalExp - levelExp) / levelCurrentExp
    end

    self.IconBp:SetRawImage(icon)
    self.TxtLv.text = config:GetLevel()
end

function XUiTheatre4LvReward:_RefreshTaskStoryList(taskType)
    self.PanelBattlePassUi:Close()
    self.PanelTaskStoryUi:Open()
    self.PanelTaskStoryUi:Refresh(taskType)
end

function XUiTheatre4LvReward:_RefreshReceiveButton()
    local isShow = false

    if self._CurrentTabType == TabType.BP then
        isShow = self._Control.SystemControl:CheckBattlePassRedDot()
    else
        if self._CurrentTabType == TabType.ChallengeTask then
            isShow = self._Control.SystemControl:CheckBattlePassChallengeTaskRedDot()
        elseif self._CurrentTabType == TabType.ProcessTask then
            isShow = self._Control.SystemControl:CheckBattlePassProcessTaskRedDot()
        elseif self._CurrentTabType == TabType.VersionTask then
            isShow = self._Control.SystemControl:CheckBattlePassVersionTaskRedDot()
        end
    end

    self.BtnReward.gameObject:SetActiveEx(isShow)
    self.BtnReward:ShowReddot(isShow)
end

function XUiTheatre4LvReward:_RefreshTabRedDot()
    local tab = self._TabGroup[self._CurrentTabType]

    if tab then
        if self._CurrentTabType == TabType.BP then
            tab:ShowReddot(self._Control.SystemControl:CheckBattlePassRedDot())
        else
            local isShow = false

            if self._CurrentTabType == TabType.ChallengeTask then
                isShow = self._Control.SystemControl:CheckBattlePassChallengeTaskRedDot()
            elseif self._CurrentTabType == TabType.ProcessTask then
                isShow = self._Control.SystemControl:CheckBattlePassProcessTaskRedDot()
            elseif self._CurrentTabType == TabType.VersionTask then
                isShow = self._Control.SystemControl:CheckBattlePassVersionTaskRedDot()
            end

            self._TabGroup[TabType.AllTask]:ShowReddot(self._Control.SystemControl:CheckAllBattlePassTaskRedDot())
            tab:ShowReddot(isShow)
        end
    end
end

function XUiTheatre4LvReward:_RefreshAllRedDot()
    local isBp = self._Control.SystemControl:CheckBattlePassRedDot()
    local isChallenge = self._Control.SystemControl:CheckBattlePassChallengeTaskRedDot()
    local isProcess = self._Control.SystemControl:CheckBattlePassProcessTaskRedDot()
    local isVersion = self._Control.SystemControl:CheckBattlePassVersionTaskRedDot()

    self._TabGroup[TabType.BP]:ShowReddot(isBp)
    self._TabGroup[TabType.ChallengeTask]:ShowReddot(isChallenge)
    self._TabGroup[TabType.ProcessTask]:ShowReddot(isProcess)
    self._TabGroup[TabType.VersionTask]:ShowReddot(isVersion)
    self._TabGroup[TabType.AllTask]:ShowReddot(isVersion or isChallenge or isProcess)
end

-- endregion

return XUiTheatre4LvReward

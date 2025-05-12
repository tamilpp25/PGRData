local XUiPanelTask = require("XUi/XUiMoneyReward/XUiPanelTask")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiMoneyReward = XLuaUiManager.Register(XLuaUi, "UiMoneyReward")

function XUiMoneyReward:OnAwake()
    self:AutoAddListener()
end

function XUiMoneyReward:OnStart()
    self:Init()
end

function XUiMoneyReward:OnEnable()
    self:CheckMoneyRewardOver(function ()
            self:SetupContent()
            local selectIndex = XDataCenter.BountyTaskManager.GetSelectIndex()

            if selectIndex > 0 then

                self.PanelTask[selectIndex].GameObject:SetActive(true)
                XLuaUiManager.SetMask(true)
                self:PlayAnimation("MoneyRewardPanelTask" .. selectIndex, function()
                        XLuaUiManager.SetMask(false)
                    end)

                XDataCenter.BountyTaskManager.SetSelectIndex(-1)
            else
                XLuaUiManager.SetMask(true)

                self:PlayAnimation("MoneyRewardBegin", function()
                        XLuaUiManager.SetMask(false)
                    end)
            end
            XEventManager.AddEventListener(XEventId.EVENT_BOUNTYTASK_ACCEPT_TASK, self.SetupBountyTask, self)
            XEventManager.AddEventListener(XEventId.EVENT_BOUNTYTASK_ACCEPT_TASK_REWARD, self.OnRankLevelChange, self)
            XEventManager.AddEventListener(XEventId.EVENT_BOUNTYTASK_TASK_COMPLETE_NOTIFY, self.SetupContent, self)
            XEventManager.AddEventListener(XEventId.EVENT_BOUNTYTASK_INFO_CHANGE_NOTIFY, self.SetupContent, self)
            XEventManager.AddEventListener(XEventId.EVENT_MAINTAINERACTION_WEEK_UPDATA, self.CheckMoneyRewardOver, self)
    end)
end

function XUiMoneyReward:OnDisable()
    self:RemoveTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_BOUNTYTASK_ACCEPT_TASK_REWARD, self.OnRankLevelChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BOUNTYTASK_TASK_COMPLETE_NOTIFY, self.SetupContent, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BOUNTYTASK_INFO_CHANGE_NOTIFY, self.SetupContent, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BOUNTYTASK_ACCEPT_TASK, self.SetupBountyTask, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MAINTAINERACTION_WEEK_UPDATA, self.CheckMoneyRewardOver, self)
end

--初始化
function XUiMoneyReward:Init()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.CurExp = -1
    self.TargetExp = 0;
    self.CurRankLevel = -1
    self.TargetRankLevel = -1
    self.Timer = nil
    self.BountyInfo = nil
    self.PanelTask = {}
    self.PanelTask[1] = XUiPanelTask.New(self.PanelTask1, self, 1)
    self.PanelTask[2] = XUiPanelTask.New(self.PanelTask2, self, 2)
    self.PanelTask[3] = XUiPanelTask.New(self.PanelTask3, self, 3)
end

--关闭
function XUiMoneyReward:OnDestroy()
    self:RemoveTimer()
end

--设置面板内容
function XUiMoneyReward:SetupContent()
    self.BountyInfo = XDataCenter.BountyTaskManager.GetBountyTaskInfo()
    self:SetupBountyTask()
    self:SetLeftTime()
end

--设置领取任务信息
function XUiMoneyReward:SetupBountyTask()
    if not self.BountyInfo then
        return
    end

    local completeCount = XDataCenter.BountyTaskManager.GetBountyTaskCompletedCount()

    self.TxtTaskSum.text = string.format("<size=58><color=#ffe400>%s</color></size>/%s", completeCount, XDataCenter.BountyTaskManager.MAX_BOUNTY_TASK_COUNT)

    local fakeOrder = XDataCenter.BountyTaskManager.GetFakeTaskOrder()

    local occupyIndexs = {}
    for k, v in pairs(fakeOrder) do
        occupyIndexs[v] = k
    end

    local selectIndex = XDataCenter.BountyTaskManager.GetSelectIndex()
    if selectIndex > 0 then
        self.PanelTask[selectIndex].GameObject:SetActive(false)
    end

    for index = 1, XDataCenter.BountyTaskManager.MAX_BOUNTY_TASK_COUNT do
        self:SetTaskByIndex(index, occupyIndexs, fakeOrder)
    end
end

function XUiMoneyReward:SetTaskByIndex(index, occupyIndexs, fakeOrder)
    local task = self.BountyInfo.TaskCards[index]
    if task and fakeOrder[task.Id] then
        self.PanelTask[fakeOrder[task.Id]]:SetupContent(task)
        if fakeOrder[task.Id] ~= index and not occupyIndexs[index] then
            self.PanelTask[index]:SetupContent(nil)
        end
    elseif not occupyIndexs[index] then
        self.PanelTask[index]:SetupContent(task)
    end
end


--设置排名信息
function XUiMoneyReward:SetupRankLevel(isAnimate)
    if not self.BountyInfo then
        return
    end

    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end

    local rankLevel = self.BountyInfo.RankLevel
    local rankConfig = XDataCenter.BountyTaskManager.GetBountyTaskRankConfig(rankLevel)
    local nextNeed = rankConfig.LevelUpExp

    local itemId = XDataCenter.ItemManager.ItemId.BountyTaskExp
    local count = XDataCenter.ItemManager.GetCount(itemId)
    count = count > nextNeed and nextNeed or count

    self.PanelEffect.gameObject:SetActive(false)
    if ((self.CurExp ~= -1 and count > self.CurExp) or (self.CurRankLevel ~= -1 and self.CurRankLevel ~= rankLevel)) and isAnimate then
        self.TargetExp = count
        self.TargetRankLevel = rankLevel
    else
        self.CurExp = count
        self.CurRankLevel = self.BountyInfo.RankLevel
        self:StopExpAnimation()
    end
end

function XUiMoneyReward:OnRankLevelChange()
    self.BountyInfo = XDataCenter.BountyTaskManager.GetBountyTaskInfo()
    self:SetupBountyTask()
end

local NextExp = 0
local TargetExp = 0

function XUiMoneyReward:StartExpAnimation()
    if self.PanelEffect:Exist() then
        self.PanelEffect.gameObject:SetActive(true)
    end

    if self.TargetRankLevel > self.CurRankLevel then
        local rankConfig = XDataCenter.BountyTaskManager.GetBountyTaskRankConfig(self.CurRankLevel)

        TargetExp = rankConfig.LevelUpExp
        NextExp = rankConfig.LevelUpExp
        self.TxtNeed.text = tostring(NextExp)

        if not self.Timer then
            self.Timer = XScheduleManager.ScheduleForever(function()
                self:Update()
            end, 0)
        end
    elseif self.TargetRankLevel == self.CurRankLevel and self.TargetExp == self.CurExp then
        self:StopExpAnimation()
    else
        local rankConfig = XDataCenter.BountyTaskManager.GetBountyTaskRankConfig(self.CurRankLevel)
        NextExp = rankConfig.LevelUpExp
        TargetExp = self.TargetExp
        self.TxtNeed.text = tostring(NextExp)

        if not self.Timer then
            self.Timer = XScheduleManager.ScheduleForever(function()
                self:Update()
            end, 0)
        end
    end
end

function XUiMoneyReward:StopExpAnimation()
    self.PanelEffect.gameObject:SetActive(false)
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end

    local rankConfig = XDataCenter.BountyTaskManager.GetBountyTaskRankConfig(self.BountyInfo.RankLevel)
    local nextNeed = rankConfig.LevelUpExp

    local rankLevel = self.BountyInfo.RankLevel
    local itemId = XDataCenter.ItemManager.ItemId.BountyTaskExp
    local count = XDataCenter.ItemManager.GetCount(itemId)

    self.TxtCurValue.text = tostring(count)
    self.TxtNeed.text = tostring(nextNeed)
    self.SliderExp.value = count / nextNeed

    local MaxLevel = XDataCenter.BountyTaskManager.GetMaxBountyTaskInfoRankLevel()
    if MaxLevel == rankLevel then
        self.TxtCurValue.gameObject:SetActive(false)
        self.TxtMax.gameObject:SetActive(true)
        self.SliderExp.value = 0
        self.TxtNeed.text = "0"
    else
        self.TxtMax.gameObject:SetActive(false)
        self.TxtCurValue.gameObject:SetActive(true)
    end

    self.RImgLevelNew.gameObject:SetActive(true)
    self.RImgLevelNew:SetRawImage(rankConfig.RankIcon)
end

function XUiMoneyReward:Update()

    if not self.TxtCurValue:Exist() or not self.SliderExp:Exist() or not self.TxtNeed:Exist() or not self.RImgLevelNew:Exist() then
        if self.Timer then
            XScheduleManager.UnSchedule(self.Timer)
            self.Timer = nil
        end
        return
    end

    if self.CurExp < TargetExp then
        self.CurExp = self.CurExp + NextExp / 30 / 3
        self.TxtCurValue.text = tostring(math.floor(self.CurExp))
        self.SliderExp.value = self.CurExp / NextExp;
    else
        self.CurExp = TargetExp
        if self.TargetRankLevel > self.CurRankLevel then
            self.CurRankLevel = self.CurRankLevel + 1
            self.CurExp = 0

            local targetRankConfig = XDataCenter.BountyTaskManager.GetBountyTaskRankConfig(self.TargetRankLevel)
            self.RImgLevelNew:SetRawImage(targetRankConfig.RankIcon)

            if self.Timer then
                XScheduleManager.UnSchedule(self.Timer)
                self.Timer = nil
            end

            self:PlayAnimation("MoneyRewardRankUp", function()
                self:StartExpAnimation()
            end)
        end

    end
end

function XUiMoneyReward:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnHelper, self.OnBtnHelperClick)
end

function XUiMoneyReward:OnBtnHelperClick()
    XUiManager.UiFubenDialogTip(CS.XTextManager.GetText("BountyTaskTipTitle"), CS.XTextManager.GetText("BountyTaskTipContent"));
end

function XUiMoneyReward:OnBtnBackClick()

    self:PlayAnimation("MoneyRewardEnd", function()
        self:Close()
    end)
end

function XUiMoneyReward:OnBtnMainUiClick()
    self:PlayAnimation("MoneyRewardEnd", function()
        XLuaUiManager.RunMain()
    end)
end

--设置剩余时间
function XUiMoneyReward:SetLeftTime()
    if self.Timer then
        self:RemoveTimer()
    end

    local refreshTime = XDataCenter.BountyTaskManager.GetRefreshTime()
    refreshTime = refreshTime or 0
    local leftTime = refreshTime - XTime.GetServerNowTimestamp()

    if leftTime <= 0 then
        local dataTime = XUiHelper.GetTime(0)
        self.TxtCurTime.text = dataTime
        self:RemoveTimer()
        self:Refresh()
    else
        local dataTime = XUiHelper.GetTime(leftTime)
        self.TxtCurTime.text = dataTime
    end


    self.Timer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end

        leftTime = refreshTime - XTime.GetServerNowTimestamp()

        if leftTime <= 0 then
            local dataTime = XUiHelper.GetTime(0)
            self.TxtCurTime.text = dataTime
            self:RemoveTimer()
        else
            local dataTime = XUiHelper.GetTime(leftTime)
            self.TxtCurTime.text = dataTime
        end
    end, 1000)
end

function XUiMoneyReward:Refresh()
    self.BountyInfo = XDataCenter.BountyTaskManager.GetBountyTaskInfo()
    self:SetupBountyTask()
end


function XUiMoneyReward:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiMoneyReward:CheckMoneyRewardOver(cb)
    XUiManager.TipText("MaintainerActionEventOver")
    XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.RunMain()
        end, 100)
end
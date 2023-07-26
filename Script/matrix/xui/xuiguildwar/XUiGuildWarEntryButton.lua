---@class XUiGuildWarEntryButton
local XUiGuildWarEntryButton = XClass(nil, "XUiGuildWarEntryButton")

--最大显示奖励数
local MaxRewardShow = 2

function XUiGuildWarEntryButton:Ctor(ui, onClickCb)
    XTool.InitUiObjectByUi(self, ui)
    self.OnClickCb = onClickCb
    self.BtnGuildWarEntry.CallBack = function() self:OnClick() end

    if self.GridReward then
        self.GridReward.gameObject:SetActiveEx(false)
    end
end

function XUiGuildWarEntryButton:OnEnable()
    self.BtnGuildWarEntry:SetNameByGroup(0, XUiHelper.GetText("GuildWarEntryDate",
            os.date("%m/%d", XDataCenter.GuildWarManager.GetActivityStartTime()),
            os.date("%m/%d", XDataCenter.GuildWarManager.GetActivityEndTime()))
    )
    local cfg = XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Config, "EntryBgPath")
    if cfg then
        self.BtnGuildWarEntry:SetRawImage(cfg.Value)
    end
end

function XUiGuildWarEntryButton:OnDestroy()
    self:StopEntryBtnListener()
end

function XUiGuildWarEntryButton:StartEntryBtnListener()
    if self.EntryBtnTimeId then return end
    self:Refresh()
    self.EntryBtnTimeId = XScheduleManager.ScheduleForever(
        function()
            self:Refresh()
        end,1000
    )
end

function XUiGuildWarEntryButton:StopEntryBtnListener()
    if not self.EntryBtnTimeId then return end
    XScheduleManager.UnSchedule(self.EntryBtnTimeId)
    self.EntryBtnTimeId = nil
end

function XUiGuildWarEntryButton:Refresh()
    -- 不在活动中, 隐藏按钮
    if not XDataCenter.GuildWarManager.CheckActivityIsInTime() then
        self:StopEntryBtnListener()
        --self.Transform.parent.gameObject:SetActiveEx(false)
        self.Transform.gameObject:SetActiveEx(false)
        return
    end
    local stateText = ""
    local isInRound = XDataCenter.GuildWarManager.CheckRoundIsInTime()
    -- 在当前轮次,显示活动开启中
    if isInRound then
        stateText = XUiHelper.GetText("GuildWarIsOpening")
        self:ShowOpenTag(true)
        self:ShowCloseTag(false)
        self:StopEntryBtnListener()

    else
        -- 不在当前轮次, 显示到下一轮的时间
        self:ShowOpenTag(false)
        self:ShowCloseTag(true)
        local nextRoundStartTime = XDataCenter.GuildWarManager.GetNextRoundTime()
        -- 没有下一轮, 显示活动关闭
        if not nextRoundStartTime then
            stateText = XUiHelper.GetText("GuildWarClose")
        else
            stateText = XUiHelper.GetText("GuildWarNextRoundTime", nextRoundStartTime)
        end
    end
    self.BtnGuildWarEntry:SetNameByGroup(1, stateText)
end

function XUiGuildWarEntryButton:ShowOpenTag(value)
    self.OpenTag.gameObject:SetActiveEx(value)
end

function XUiGuildWarEntryButton:ShowCloseTag(value)
    self.CloseTag.gameObject:SetActiveEx(value)
end

function XUiGuildWarEntryButton:OnShow()
    local guildWarEntryShow = self:CheckGuildWarCanEnter()
    if guildWarEntryShow then
        --self.Transform.parent.gameObject:SetActiveEx(true)
        self.Transform.gameObject:SetActiveEx(true)
        self:StartEntryBtnListener()
        self.BtnGuildWarEntry:SetNameByGroup(2, XDataCenter.GuildWarManager.GetName())
        --self.BtnGuildWarEntry:ShowReddot(XDataCenter.GuildWarManager.CheckTaskAchieved())
        if self.GridReward and not self.InitRewards then
            local configValues = XGuildWarConfig.GetClientConfigValues("EntryRewardId", "Int")
            local rewardId = configValues and configValues[1]
            if rewardId then
                local rewards = XRewardManager.GetRewardList(rewardId)
                if rewards then
                    for i, item in ipairs(rewards) do
                        if i > MaxRewardShow then
                            break
                        end
                        local ui = XUiHelper.Instantiate(self.GridReward ,self.RewardList)
                        local grid = XUiGridCommon.New(ui)
                        grid:Refresh(item)
                        grid.GameObject:SetActiveEx(true)
                    end
                end
            end
            self.InitRewards = true
        end
    else
        --self.Transform.parent.gameObject:SetActiveEx(false)
        self.Transform.gameObject:SetActiveEx(false)
    end
end

function XUiGuildWarEntryButton:CheckGuildWarCanEnter()
    return XDataCenter.GuildWarManager.CheckActivityIsInTime()
end

function XUiGuildWarEntryButton:OnClick()
    if self.OnClickCb then
        self.OnClickCb()
    end
end

return XUiGuildWarEntryButton
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
--虚像地平线战斗结算界面
local XUiExpeditionSettleWin = XLuaUiManager.Register(XLuaUi, "UiExpeditionSettleWin")
local XUiExpeditionSettleWinHeadIcon = require("XUi/XUiExpedition/Battle/XUiExpeditionSettleWinHeadIcon")
function XUiExpeditionSettleWin:OnAwake()
    self:InitAutoScript()
end

function XUiExpeditionSettleWin:OnStart(data)
    self.WinData = data.SettleData.ExpeditionFightResult
    self.EStage = XDataCenter.ExpeditionManager.GetEStageByStageId(data.StageId)
    self.IsFirst = true;
    self:InitInfo(data)
    XLuaUiManager.SetMask(true)
    self:PlayRewardAnimation()
end

function XUiExpeditionSettleWin:OnEnable()
    if not self.IsFirst then
        XLuaUiManager.SetMask(true)
        self.Timer = XScheduleManager.ScheduleOnce(function()
                self:PlaySecondAnimation()
            end, 0)
    end
end

function XUiExpeditionSettleWin:OnDestroy()
    XDataCenter.AntiAddictionManager.EndFightAction()
end

-- 奖励动画
function XUiExpeditionSettleWin:PlayRewardAnimation()
    local delay = XDataCenter.FubenManager.SettleRewardAnimationDelay
    local interval = XDataCenter.FubenManager.SettleRewardAnimationInterval
    local this = self

    -- 没有奖励则直接播放第二个动画
    if not self.GridRewardList or #self.GridRewardList == 0 then
        self.Timer = XScheduleManager.ScheduleOnce(function()
                this:PlaySecondAnimation()
            end, delay)
        return
    end

    self.RewardAnimationIndex = 1
    self.Timer = XScheduleManager.Schedule(function()
            if this.RewardAnimationIndex == #self.GridRewardList then
                this:PlayReward(this.RewardAnimationIndex, function()
                        this:PlaySecondAnimation()
                    end)
            else
                this:PlayReward(this.RewardAnimationIndex)
            end
            this.RewardAnimationIndex = this.RewardAnimationIndex + 1
        end, interval, #self.GridRewardList, delay)
end


function XUiExpeditionSettleWin:PlaySecondAnimation()
    local this = self
    self:PlayAnimation("AnimEnable2", function()
            XLuaUiManager.SetMask(false)
            -- this:PlayTipMission()
            XDataCenter.FunctionEventManager.UnLockFunctionEvent()
            self.IsFirst = false;
        end)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiExpeditionSettleWin:InitAutoScript()
    self:AutoAddListener()
    self.PanelFriend.gameObject:SetActive(false)
    self.GridReward.gameObject:SetActive(false)
    self.GridCombo.gameObject:SetActive(false)
    self:SetBtnsInfo()
end

function XUiExpeditionSettleWin:AutoAddListener()
    self:RegisterClickEvent(self.BtnBlock, self.OnBtnExitClick)
end

function XUiExpeditionSettleWin:InitInfo(data)
    self:InitStageNameAndTime()
    self:InitRewardCharacterList()
    self:InitComboPanel()
    self:InitRewardList(data.RewardGoodsList)
    self:UpdateDrawTimes(self.WinData.AddDrawTimesReward or 0)
end

function XUiExpeditionSettleWin:SetBtnsInfo()
    self.PanelTouch.gameObject:SetActive(true)
    self.PanelBtns.gameObject:SetActive(false)
end

function XUiExpeditionSettleWin:InitStageNameAndTime()
    self.TxtStageName.text = self.EStage:GetStageName()
    -- 通关时间
    local costTime = XUiHelper.GetTime(self.WinData.UseTime, XUiHelper.TimeFormatType.SHOP)
    self.TxtCostTime.text = costTime
end

-- 角色奖励列表
function XUiExpeditionSettleWin:InitRewardCharacterList()
    self.GridWinRole.gameObject:SetActive(false)
    local teamData = XDataCenter.ExpeditionManager.GetExpeditionTeam()
    for i = 1, #teamData.TeamData do
        if teamData.TeamData[i] ~= 0 then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridWinRole)
            local grid = XUiExpeditionSettleWinHeadIcon.New(ui)
            grid.Transform:SetParent(self.PanelRoleContent, false)
            grid:RefreshData(teamData.TeamData[i])
            grid.GameObject:SetActive(true)
        end
    end
end

-- 物品奖励列表
function XUiExpeditionSettleWin:InitRewardList(rewardGoodsList)
    rewardGoodsList = rewardGoodsList or {}
    self.GridRewardList = {}
    local rewards = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
    for _, item in ipairs(rewards) do
        local ui = CS.UnityEngine.Object.Instantiate(self.GridReward)
        local grid = XUiGridCommon.New(self, ui)
        grid.Transform:SetParent(self.PanelRewardContent, false)
        grid:Refresh(item, nil, nil, true)
        grid.GameObject:SetActive(false)
        table.insert(self.GridRewardList, grid)
    end
end

function XUiExpeditionSettleWin:UpdateDrawTimes(drawTimesReward)
    -- 招募次数
    if self.DrawTimesTxt then
        self.DrawTimesTxt.text = string.format("+%d", drawTimesReward)
    end
end

function XUiExpeditionSettleWin:InitComboPanel()
    local XComboList = require("XUi/XUiExpedition/Battle/XUiExpeditionInfinityComboList")
    self.ComboList = XComboList.New(self.DyanamicTableCombo)
    self.ComboList:RefreshData()
end

function XUiExpeditionSettleWin:OnBtnExitClick()
    if XDataCenter.ExpeditionManager.GetIfBackMain() then
        if self.Timer then
            XScheduleManager.UnSchedule(self.Timer)
            self.Timer = nil
        end
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionOnClose"))
    else
        self:Close()
    end
end

function XUiExpeditionSettleWin:PlayReward(index, cb)
    self.GridRewardList[index].GameObject:SetActive(true)
    self:PlayAnimation("GridReward", cb)
end
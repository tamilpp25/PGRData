-- 兵法蓝图战斗胜利结算Ui
local XUiRpgTowerSettleWin = XLuaUiManager.Register(XLuaUi, "UiRpgTowerSettleWin")
local CharaItem = require("XUi/XUiRpgTower/Common/XUiRpgTowerCharaItem")
function XUiRpgTowerSettleWin:OnAwake()
    XTool.InitUiObject(self)
    self:InitAutoScript()
    self.GridReward.gameObject:SetActive(false)
end

function XUiRpgTowerSettleWin:OnStart(data, cb)
    self.WinData = data
    self.StageInfos = XDataCenter.FubenManager.GetStageInfo(data.StageId)
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(data.StageId)
    self.CurrentStageId = data.StageId
    self.CurrAssistInfo = data.ClientAssistInfo
    self.Cb = cb
    self.IsFirst = true
    self:InitInfo(data)
    XLuaUiManager.SetMask(true)
    self:PlayRewardAnimation()
end

function XUiRpgTowerSettleWin:OnEnable()
    if not self.IsFirst then
        XLuaUiManager.SetMask(true)
        self.Timer = XScheduleManager.ScheduleOnce(function()
                self:PlaySecondAnimation()
            end)
    end
end

function XUiRpgTowerSettleWin:OnDestroy()
    self.TeamBar:StopTimer()
    XDataCenter.AntiAddictionManager.EndFightAction()
end

-- 奖励动画
function XUiRpgTowerSettleWin:PlayRewardAnimation()
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


function XUiRpgTowerSettleWin:PlaySecondAnimation()
    local this = self
    self:PlayAnimation("AnimEnable2", function()
            XLuaUiManager.SetMask(false)
            XDataCenter.FunctionEventManager.UnLockFunctionEvent()
            self.IsFirst = false;
        end)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiRpgTowerSettleWin:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiRpgTowerSettleWin:AutoInitUi()
    self.PanelNorWinInfo = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo")
    self.PanelNor = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor")
    self.PanelBtn = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn")
    self.PanelBtns = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns")
    self.BtnLeft = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns/BtnLeft"):GetComponent("Button")
    self.TxtLeft = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns/BtnLeft/TxtLeft"):GetComponent("Text")
    self.BtnRight = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns/BtnRight"):GetComponent("Button")
    self.TxtRight = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns/BtnRight/TxtRight"):GetComponent("Text")
    self.PanelTouch = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelTouch")
    self.BtnBlock = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelTouch/BtnBlock"):GetComponent("Button")
    self.TxtLeftA = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelTouch/BtnBlock/TxtLeft"):GetComponent("Text")
    self.PanelLeft = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelLeft")
    self.PanelRoleContent = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelLeft/Team/PanelRoleContent")
    self.GridWinRole = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelLeft/Team/PanelRoleContent/GridWinRole")
    self.PanelRight = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight")
    self.TxtChapterName = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight/StageInfo/TxtChapterName"):GetComponent("Text")
    self.TxtStageName = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight/StageInfo/TxtStageName"):GetComponent("Text")
    self.PanelRewardContent = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight/RewardList/Viewport/PanelRewardContent")
    self.GridReward = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight/RewardList/Viewport/PanelRewardContent/GridReward")
    self.PanelFriend = self.Transform:Find("SafeAreaContentPane/PanelFriend")
    self.PanelInf = self.Transform:Find("SafeAreaContentPane/PanelFriend/PanelInf")
    self.TxtName = self.Transform:Find("SafeAreaContentPane/PanelFriend/PanelInf/TxtName"):GetComponent("Text")
    self.TxtLv = self.Transform:Find("SafeAreaContentPane/PanelFriend/PanelInf/TxtLv"):GetComponent("Text")
    self.PanelPlayerExpBar = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelLeft/PlayerExp/PanelPlayerExpBar")
end

function XUiRpgTowerSettleWin:AutoAddListener()
    self:RegisterClickEvent(self.BtnBlock, self.OnBtnExitClick)
end

function XUiRpgTowerSettleWin:InitInfo(data)
    self.PanelFriend.gameObject:SetActive(false)
    self:SetBtnsInfo()
    self:SetStageInfo(data)
    self:UpdatePlayerInfo(data)
    self:InitRewardCharacterList(data)
    self:InitRewardList(data.RewardGoodsList)
end

function XUiRpgTowerSettleWin:SetBtnsInfo()
    self.PanelTouch.gameObject:SetActive(true)
    self.PanelBtns.gameObject:SetActive(false)
end

function XUiRpgTowerSettleWin:SetStageInfo(data)
    local chapterName, stageName = XDataCenter.FubenManager.GetFubenNames(data.StageId)
    self.TxtChapterName.text = chapterName
    self.TxtStageName.text = stageName
end

-- 角色奖励列表
function XUiRpgTowerSettleWin:InitRewardCharacterList(data)
    self.GridWinRole.gameObject:SetActive(false)
    local teamData = XDataCenter.TeamManager.GetPlayerTeam(CS.XGame.Config:GetInt("TypeIdRpgTower"))
    for i = 1, #teamData.TeamData do
        if teamData.TeamData[i] ~= 0 then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridWinRole)
            local grid = CharaItem.New(ui, XDataCenter.RpgTowerManager.CharaItemShowType.OnlyIconAndStar, nil, true)
            grid.Transform:SetParent(self.PanelRoleContent, false)
            grid:RefreshData(XDataCenter.RpgTowerManager.GetTeamMemberByCharacterId(XRobotManager.GetCharacterId(teamData.TeamData[i])))
            grid.GameObject:SetActive(true)
        end
    end
end

-- 玩家经验
function XUiRpgTowerSettleWin:UpdatePlayerInfo(data)
    if not data or not next(data) then return end
    local TeamBar = require("XUi/XUiRpgTower/Common/XUiRpgTowerSettleWinExpBar")
    self.TeamBar = self.TeamBar or TeamBar.New(self.PanelPlayerExpBar)
    local expChanges = XDataCenter.RpgTowerManager.GetExpChanges()
    self.TeamBar:StartRun(expChanges)
end

-- 物品奖励列表
function XUiRpgTowerSettleWin:InitRewardList(rewardGoodsList)
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

function XUiRpgTowerSettleWin:OnBtnExitClick()
    if XDataCenter.RpgTowerManager.GetIsReset() then
        if self.Timer then
            XScheduleManager.UnSchedule(self.Timer)
            self.Timer = nil
        end
        self.TeamBar:StopTimer()
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerFinished"))
    else
        self:Close()
    end
end

function XUiRpgTowerSettleWin:PlayReward(index, cb)
    self.GridRewardList[index].GameObject:SetActive(true)
    self:PlayAnimation("GridReward", cb)
end
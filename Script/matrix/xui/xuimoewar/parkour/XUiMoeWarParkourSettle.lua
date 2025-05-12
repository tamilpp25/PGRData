local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
--==============================
 ---@desc 积分
--==============================
local XUiGridCond = XClass(nil, "XUiGridCond")

function XUiGridCond:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridCond:Refresh(desc, score, isBreakRecord)
    self.TxtDesc.text = desc
    self.TxtLoaded.text = score
    self.PanelNewrecord.gameObject:SetActiveEx(isBreakRecord)
end



--==============================
 ---@desc 萌战跑酷-胜利界面
--==============================
local XUiMoeWarParkourSettle = XLuaUiManager.Register(XLuaUi, "UiMoeWarParkourSettle")

function XUiMoeWarParkourSettle:OnAwake()
    self:InitCb()
end 

function XUiMoeWarParkourSettle:OnStart(winData)
    self.WinData = winData
    self.StageInfo = XDataCenter.FubenManager.GetStageInfo(winData.StageId)
    self.StageConfig = XDataCenter.FubenManager.GetStageCfg(winData.StageId)
    --教学关不发对应数据
    self.SettleResult = winData.SettleData.MoewarParkourSettleResult or {}
    
    self:InitView()
    self:PlayRewardAnimation()
end 

--region   ------------------界面显示 start-------------------

function XUiMoeWarParkourSettle:InitCb()
    self.BtnBlock.CallBack = function() 
        self:Close()
    end
end

function XUiMoeWarParkourSettle:InitView()
    self.ImgPlayerXinqingFillAdd.gameObject:SetActiveEx(false)
    self.TxtAdd.gameObject:SetActiveEx(false)
    self:InitStageView()
    self:InitCharacterView()
    self:InitRewardView()
end

--==============================
 ---@desc 初始化关卡信息显示
--==============================
function XUiMoeWarParkourSettle:InitStageView()
    self.TxtStageName.text = self.StageConfig.Name
    --移动与收集
    self.GridCondMoveAndColl  = XUiGridCond.New(self.GridCond)
    --移动距离
    self.GridCondMoveDistance = XUiGridCond.New(CS.UnityEngine.Object.Instantiate(self.GridCond, self.PanelCondContent, false))
    --总积分
    self.GridCondTotalScore   = XUiGridCond.New(CS.UnityEngine.Object.Instantiate(self.GridCond, self.PanelCondContent, false))
    
    local starDesc = self.StageConfig.StarDesc
    
    local stage = XDataCenter.MoeWarManager.GetStageById(self.WinData.StageId)
    local oldMaxScore = stage:GetAllTimeHigh()
    local newMaxScore = self.SettleResult[XMoeWarConfig.ParkourSettleResultKey.TotalScore] or 0
    local distance = self.SettleResult[XMoeWarConfig.ParkourSettleResultKey.MoveDistance] or 0
    local collectScore = self.SettleResult[XMoeWarConfig.ParkourSettleResultKey.CollectScore] or 0
    self.Tickets = self.SettleResult[XMoeWarConfig.ParkourSettleResultKey.DailyReward] or 0
    XDataCenter.MoeWarManager.RefreshParkourTicket(self.Tickets)
    local isBreakRecord = newMaxScore > oldMaxScore
    if isBreakRecord then
        stage:RefreshAllTimeHigh(newMaxScore)
    end
    self.GridCondMoveAndColl:Refresh(starDesc[1], collectScore, false)
    self.GridCondMoveDistance:Refresh(starDesc[2], distance, false)
    self.GridCondTotalScore:Refresh(starDesc[3], newMaxScore, isBreakRecord)
end

--==============================
 ---@desc 初始化角色信息显示
--==============================
function XUiMoeWarParkourSettle:InitCharacterView()
    local charExp = self.WinData.CharExp
    local count = #charExp
    if count <= 0 then
        return
    end
    for i = 1, count do
        local id = charExp[i].Id
        if XTool.IsNumberValid(id) and XRobotManager.CheckIsRobotId(id) then
            local helperId = XMoeWarConfig.GetHelperIdByRobotId(id)
            self.StandIcon:SetRawImage(XMoeWarConfig.GetMoeWarPreparationHelperCirleIcon(helperId))
            --local lastMoodValue = XDataCenter.MoeWarManager.GetLastMoodValue(helperId)
            local curMoodValue = XDataCenter.MoeWarManager.GetMoodValue(helperId)
            local moodUpLimit = XMoeWarConfig.GetPreparationHelperMoodUpLimit(helperId)
            local moodId = XMoeWarConfig.GetCharacterMoodId(curMoodValue)
            self.ImgMood:SetSprite(XMoeWarConfig.GetCharacterMoodIcon(moodId))
            --local addValue = math.max(0, math.floor(curMoodValue - lastMoodValue))
            --self.TxtAdd.text = string.format("+%d", addValue)
            --self.ImgPlayerXinqingFillAdd.fillAmount = curMoodValue / moodUpLimit
            self.ImgPlayerXinqingFill.fillAmount = curMoodValue / moodUpLimit
            break
        end
    end
   
end

--==============================
 ---@desc 初始化奖励显示
--==============================
function XUiMoeWarParkourSettle:InitRewardView()
    self.RewardGridList = {}
    local rewardList = self.WinData.RewardGoodsList or {}
    local rewards = XRewardManager.FilterRewardGoodsList(rewardList)
    rewards = XRewardManager.MergeAndSortRewardGoodsList(rewards)
    if XTool.IsTableEmpty(rewards) then
        self.GridReward.gameObject:SetActiveEx(false)
    else
        for i, reward in ipairs(rewards) do
            local ui = i == 1 and self.GridReward or CS.UnityEngine.Object.Instantiate(self.GridReward, self.PanelRewardContent, false)
            local grid = XUiGridCommon.New(self, ui)
            grid:Refresh(reward, nil, nil, true)
            grid.GameObject:SetActiveEx(false)
            table.insert(self.RewardGridList, grid)
        end
    end
end

--endregion------------------界面显示 finish------------------



--region   ------------------动画相关 start-------------------

--==============================
 ---@desc 播放奖励动画
--==============================
function XUiMoeWarParkourSettle:PlayRewardAnimation()
    local delay     = XDataCenter.FubenManager.SettleRewardAnimationDelay
    local interval  = XDataCenter.FubenManager.SettleRewardAnimationInterval
    
    local rewardCount = self.RewardGridList and #self.RewardGridList or 0

    if not XTool.IsNumberValid(rewardCount) then
        return
    end
    
    local rewardAnimationIndex = 1
    XScheduleManager.Schedule(function()
        if XTool.UObjIsNil(self.RewardGridList[rewardAnimationIndex].GameObject) then
            return
        end

        self:PlayReward(rewardAnimationIndex)
        rewardAnimationIndex = rewardAnimationIndex + 1
    end, interval, rewardCount, delay)
end

--==============================
 ---@desc 播放单个奖励动画
 ---@index 奖励Item下标 
 ---@cb 回调
--==============================
function XUiMoeWarParkourSettle:PlayReward(index, cb)
    self.RewardGridList[index].GameObject:SetActiveEx(true)
    --self:PlayAnimation("GridReward", cb)
end

--endregion------------------动画相关 finish------------------
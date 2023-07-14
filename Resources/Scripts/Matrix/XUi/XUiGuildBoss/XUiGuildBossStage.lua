--工会boss选关页面
local XUiGuildBossStageLevel = require("XUi/XUiGuildBoss/Component/XUiGuildBossStageLevel")
local XUiGuildBossRewardItem = require("XUi/XUiGuildBoss/Component/XUiGuildBossRewardItem")
local XUiGuildBossHpReward = require("XUi/XUiGuildBoss/ChildView/XUiGuildBossHpReward")
local XUiGuildBossStage = XLuaUiManager.Register(XLuaUi, "UiGuildBossStage")

function XUiGuildBossStage:OnAwake()
    self.PanelHpReward = XUiGuildBossHpReward.New(self, self.PanelHpReward)
    self.PanelHpReward:Close()
    
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "GuildBossHelp")
    self.BtnDiff.CallBack = function() self:OnBtnDiffClick() end
    self.BtnSkill.CallBack = function() self:OnBtnSkillClick() end
    self.BtnBoss.CallBack = function() self:OnBtnBossClick() end
    self.BtnDetail.CallBack = function() self:OnBtnDetailClick() end
    self.BtnLayout.CallBack = function() self:OnBtnLayoutClick() end
    self.BtnConfirm.CallBack = function() self:OnBtnConfirmClick() end
    self.BtnBossHpRewardGet.CallBack = function() self:OnBtnBossHpRewardGetClick() end
    self.BtnExitDetail.CallBack = function() self:OnBtnExitDetailClick() end
    self.HpAnimationCB = function() end
    
    self.BtnBossHpRewardGet.gameObject:SetActiveEx(true)
    self.BtnBossHpRewardGet:ShowReddot(false)
    self.BtnReward.gameObject:SetActiveEx(false)
    self.StageLevelObj.gameObject:SetActiveEx(false)
    self.Instantiate = CS.UnityEngine.GameObject.Instantiate
    self.VectorOne = CS.UnityEngine.Vector3.one
    self.VectorSmall = CS.UnityEngine.Vector3(0.8, 0.8, 1)
    self.VectorZero = CS.UnityEngine.Vector3.zero
    self.Vector2 = CS.UnityEngine.Vector2
    self.Levels = {}
    self.Rewards = {}
    self.WindowMode = 
    {
        Normal = 1,
        Order = 2, --战术布局中
        LevelDetail = 3, --显示关卡详情
    }
    self.CurWindowMode = self.WindowMode.Normal
    self.Pos = {self.Pos1,self.Pos2,self.Pos3,self.Pos4,self.Pos5,self.Pos6,self.Pos7}
    self.BtnExitDetail.gameObject:SetActiveEx(false)
    self.PanelBattleInfo.gameObject:SetActiveEx(false)
    self.IsFirstOpen = true
    self.CurStageData = nil
    self.hasHpReward = nil -- 是否有hp奖励
end

function XUiGuildBossStage:OnResume(data)
    self.CurWindowMode = data.curWindowMode
    self.CurStageData = data.curStageData
end

function XUiGuildBossStage:OnReleaseInst()
    return {curWindowMode = self.CurWindowMode, curStageData = self.CurStageData}
end

function XUiGuildBossStage:OnEnable()
    if self.IsFirstOpen then
        self.IsFirstOpen = false
       self:UpdatePage(0)
    end
    XEventManager.AddEventListener(XEventId.EVENT_GUILDBOSS_UPDATEORDER, self.UpdateAllOrderMark, self)
end

function XUiGuildBossStage:OnDisable()
    if self.AnimTimer then
        XScheduleManager.UnSchedule(self.AnimTimer)
        self.AnimTimer = nil
    end
    if self.AnimTimer2 then
        XScheduleManager.UnSchedule(self.AnimTimer2)
        self.AnimTimer2 = nil
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDBOSS_UPDATEORDER, self.UpdateAllOrderMark, self)
end

function XUiGuildBossStage:OnNotify(evt, ...)
    local args = { ... }

    if evt == CS.XEventId.EVENT_UI_ALLOWOPERATE and args[1] == self.Ui then
        if XDataCenter.GuildManager.GetGuildId() <= 0 then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildKickOutByAdministor"))
            XLuaUiManager.RunMain()
            return
        end
        if not self.IsFirstOpen then
            self:PlayBossAnimation()
        end
    end
end

function XUiGuildBossStage:OnGetEvents()
    return { CS.XEventId.EVENT_UI_ALLOWOPERATE }
end

function XUiGuildBossStage:UpdateBossHp(damage)
    --更新中间boss相关信息
    local bossMaxHp = XDataCenter.GuildBossManager.GetMaxBossHp()
    local bossCurHp = XDataCenter.GuildBossManager.GetCurBossHp() + damage
    local leftHpNum = math.floor(bossCurHp / (bossMaxHp / 100)) --剩余血量管数
    self.ImgBossHp.fillAmount = (bossCurHp - (leftHpNum * (bossMaxHp / 100))) / (bossMaxHp / 100)
    self.TxtBossCurHp.text = XUiHelper.GetLargeIntNumText(bossCurHp)
    self.PanelHpInfo.gameObject:SetActiveEx(bossCurHp > 0)
    self.PanelFinish.gameObject:SetActiveEx(bossCurHp == 0)
    self.TxtBossHpNum.text = leftHpNum
    self.TxtBossLv.text = "Lv." .. XDataCenter.GuildBossManager.GetCurBossLevel()
    self.TxtBossHp.text = XUiHelper.GetLargeIntNumText(bossMaxHp)
end

--如果damage>0则需要播放boss扣血动画
function XUiGuildBossStage:UpdatePage(damage)
    
    self:UpdateBossHp(damage)

    --更新显示关卡
    self.LevelData = XDataCenter.GuildBossManager.GetLevelData()
    local lowLevelInfo = XDataCenter.GuildBossManager.GetLowLevelInfo()
    local highLevelInfo = XDataCenter.GuildBossManager.GetHighLevelInfo()
    for i = 1, #self.LevelData do
        if self.LevelData[i].Type ~= GuildBossLevelType.Boss then
            if self.Levels[i] == nil then
                self.Levels[i] = XUiGuildBossStageLevel.New(self.Instantiate(self.StageLevelObj))
            end
            self.Levels[i].Transform:SetParent(self.Pos[i].transform)
            self.Levels[i]:Init(self.LevelData[i], self)
            self.Levels[i].Transform.localPosition = self.VectorZero
            self.Levels[i].Transform.localEulerAngles = self.VectorZero
            self.Levels[i].OrderNum.transform.eulerAngles = self.VectorZero
            self.Levels[i].GameObject:SetActiveEx(true)
            
            local curLevelInfo
            if self.LevelData[i].Type == GuildBossLevelType.Low then
                curLevelInfo = lowLevelInfo
            else
                curLevelInfo = highLevelInfo
            end
            if curLevelInfo ~= nil then
                if curLevelInfo.StageId == self.LevelData[i].StageId then
                    self.Levels[i].Transform.localScale = self.VectorOne
                    self.Levels[i].ImgBlack.gameObject:SetActiveEx(false)
                else
                    self.Levels[i].Transform.localScale = self.VectorSmall
                    self.Levels[i].ImgBlack.gameObject:SetActiveEx(true)
                end
            else
                self.Levels[i].Transform.localScale = self.VectorOne
                self.Levels[i].ImgBlack.gameObject:SetActiveEx(false)
            end
        end
    end

    self:UpdatePanelReward()
    self:XUiGuildBossHpReward()
    self:UpdateAllOrderMark()
end

--更新左边累计分数奖励及总分
function XUiGuildBossStage:UpdatePanelReward()
    local rewardData = XGuildBossConfig.ScoreRewards()
    local lastScore = 0 -- 用于控制每段的进度条长度
    for i = 1, #rewardData do
        if self.Rewards[i] == nil then
            self.Rewards[i] = XUiGuildBossRewardItem.New(self.Instantiate(self.BtnReward.gameObject), self)
        end
        self.Rewards[i].Transform:SetParent(self.PanelRewardBtn.transform)
        self.Rewards[i]:Init(rewardData[i], lastScore)
        lastScore = rewardData[i].Score
        self.Rewards[i].Transform.localScale = self.VectorOne
        self.Rewards[i].Transform.position = self.BtnReward.transform.position
        --self.Rewards[i].RectTransform.anchoredPosition = self.Vector2(self.Rewards[i].RectTransform.anchoredPosition.x, 100 * i)
        self.Rewards[i].Transform.localEulerAngles = self.VectorZero
        self.Rewards[i].GameObject:SetActiveEx(true)
    end
    self.PanelRewardLayout:SetDirty()
    self.BtnDetail:SetName(XUiHelper.GetLargeIntNumText(XDataCenter.GuildBossManager.GetMyTotalScore()))
end

function XUiGuildBossStage:OnBtnRewardClick(rewardData)
    XDataCenter.GuildBossManager.GuildBossScoreBoxRequest(rewardData.Id, function() self:UpdatePanelReward() end)
end

--更新右上boss血量阶段奖励
function XUiGuildBossStage:XUiGuildBossHpReward()
    --当前领到第几阶段
    self.CurBossHpReward = XDataCenter.GuildBossManager.GetHpBoxGot()
    --奖励数据
    local hpRewardData = XGuildBossConfig.HpRewards()
    --全部领完
    if self.CurBossHpReward >= #hpRewardData then
        self.RewardGrids.gameObject:SetActiveEx(false)
        self.TxtBossRewardDone.gameObject:SetActiveEx(true)
        -- self.BtnBossHpRewardGet.gameObject:SetActiveEx(false)
        self.hasHpReward = false
        self.TxtTargetBlood.text = hpRewardData[self.CurBossHpReward].HpPercent
    else
        self.RewardGrids.gameObject:SetActiveEx(true)
        self.TxtBossRewardDone.gameObject:SetActiveEx(false)
        local curHpPrecent = XDataCenter.GuildBossManager.GetCurBossHp() / XDataCenter.GuildBossManager.GetMaxBossHp() * 100
        self.TxtTargetBlood.text = hpRewardData[self.CurBossHpReward + 1].HpPercent
        --可以领下一档
        if curHpPrecent <= hpRewardData[self.CurBossHpReward + 1].HpPercent then
            -- self.BtnBossHpRewardGet.gameObject:SetActiveEx(true)
            self.hasHpReward = true
        --不能领
        else
            -- self.BtnBossHpRewardGet.gameObject:SetActiveEx(false)
            self.hasHpReward = false
        end
        --下一档的奖励Grid
        local rewardList = XRewardManager.GetRewardList(XDataCenter.GuildBossManager.GetHpRewardId(self.CurBossHpReward + 1))
        self.GuildBossHpRewardGrid1 = XUiGridCommon.New(self, self.BossHpRewardGrid1Obj)
        self.GuildBossHpRewardGrid1:Refresh(rewardList[1])
        self.GuildBossHpRewardGrid2 = XUiGridCommon.New(self, self.BossHpRewardGrid2Obj)
        self.GuildBossHpRewardGrid2:Refresh(rewardList[2])
    end
    self.BtnBossHpRewardGet:ShowReddot(self.hasHpReward)
end

function XUiGuildBossStage:OnBtnBossHpRewardGetClick()
    if self.hasHpReward then
        XDataCenter.GuildBossManager.GuildBossHpBoxRequest(self.CurBossHpReward + 1, function() self:XUiGuildBossHpReward() end)
    else
        self:PlayAnimation("PanelHpRewardEnable", self.HpAnimationCB)
        self.PanelHpReward:Show()
    end
end

function XUiGuildBossStage:ResetToNormal(cb)
    self:ChangeMode(self.WindowMode.Normal, cb)
    if self.ChildName then
        self:CloseChildUi(self.ChildName)
    end
    --清除所有选中效果
    for i = 1, #self.Levels do
        self.Levels[i].ImgSelect.gameObject:SetActiveEx(false)
    end
    self.ImgBossSelect.gameObject:SetActiveEx(false)
end

function XUiGuildBossStage:OnBtnBackClick()
    if self.CurWindowMode == self.WindowMode.LevelDetail then
        self:ResetToNormal()
    elseif self.CurWindowMode == self.WindowMode.Order then
        self:ChangeMode(self.WindowMode.Normal)
    else
        self:Close()
    end
end

function XUiGuildBossStage:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiGuildBossStage:OnBtnDiffClick()
    XLuaUiManager.Open("UiGuildBossDiff")
end

function XUiGuildBossStage:OnBtnSkillClick()
    XLuaUiManager.Open("UiGuildBossSkill")
end

function XUiGuildBossStage:OnBtnDetailClick()
    XLuaUiManager.Open("UiGuildBossDetail")
end

--点击关卡回调
function XUiGuildBossStage:OnStageLevelClick(data, btnStage)
    self.CurStageData = data
    XDataCenter.GuildBossManager.SetCurSelectStageType(self.CurStageData.Type)
    if self.CurWindowMode == self.WindowMode.Normal or self.CurWindowMode == self.WindowMode.LevelDetail then
        XDataCenter.GuildBossManager.GuildBossStageRequest(data.StageId, function() self:OpenStageDetail(data) end)
    --指挥模式下点击关卡设置优先度
    elseif self.CurWindowMode == self.WindowMode.Order then
        local curOrderPos = XDataCenter.GuildBossManager.GetStageDataPos(data)
        local allLevelData = XDataCenter.GuildBossManager.GetLevelData()
        if data.Type == GuildBossLevelType.Low then
            if self.OrderData[curOrderPos] == 0 then
                self.OrderData[curOrderPos] = self.ToSetLowNum
                btnStage:SetOrder(self.ToSetLowNum)
                self.ToSetLowNum = self.ToSetLowNum + 1
            else
                self.ToSetLowNum = self.OrderData[curOrderPos]
                for i = 1, #self.OrderData do
                    if allLevelData[i].Type == GuildBossLevelType.Low then
                        if self.OrderData[i] >= self.ToSetLowNum then
                            self.OrderData[i] = 0
                        end
                        self:GetLevelByStageId(allLevelData[i].StageId):SetOrder(self.OrderData[i])
                    end
                end
            end
        elseif data.Type == GuildBossLevelType.High then
            if self.OrderData[curOrderPos] == 0 then
                self.OrderData[curOrderPos] = self.ToSetHighNum
                btnStage:SetOrder(self.ToSetHighNum)
                self.ToSetHighNum = self.ToSetHighNum + 1
            else
                self.ToSetHighNum = self.OrderData[curOrderPos]
                for i = 1, #self.OrderData do
                    if allLevelData[i].Type == GuildBossLevelType.High then
                        if self.OrderData[i] >= self.ToSetHighNum then
                            self.OrderData[i] = 0
                        end
                        self:GetLevelByStageId(allLevelData[i].StageId):SetOrder(self.OrderData[i])
                    end
                end
            end
        end
    end
end

function XUiGuildBossStage:OpenStageDetail(data)
    --选中效果
    self.ImgBossSelect.gameObject:SetActiveEx(false)
    if self.CurSelectLevelData ~= nil then
        local curLevel = self:GetLevelByStageId(self.CurSelectLevelData.StageId)
        if curLevel then
            curLevel.ImgSelect.gameObject:SetActiveEx(false)
        end
    end
    self:GetLevelByStageId(data.StageId).ImgSelect.gameObject:SetActiveEx(true)

    self.CurSelectLevelData = data
    self:ChangeMode(self.WindowMode.LevelDetail)
    --如果是boss关卡
    if data.Type == GuildBossLevelType.Boss then
        XLuaUiManager.Open("UiGuildBossMainLevelInfo", self)
        self.ChildName = "UiGuildBossMainLevelInfo"
    else
        --普通关卡有两种情况，如果某个区打过关卡A，选中关卡A和非关卡A打开页面不同
        --如果是低浓度区
        if data.Type == GuildBossLevelType.Low then
            local lowLevelInfo = XDataCenter.GuildBossManager.GetLowLevelInfo()
            if lowLevelInfo ~= nil then
                if lowLevelInfo.StageId == data.StageId then
                    self:OpenOneChildUi("UiGuildBossCurSubLevelInfo", self)
                    self.ChildName = "UiGuildBossCurSubLevelInfo"
                else
                    self:OpenOneChildUi("UiGuildBossOtherSubLevelInfo", self)
                    self.ChildName = "UiGuildBossOtherSubLevelInfo"
                end
            else
                self:OpenOneChildUi("UiGuildBossCurSubLevelInfo", self)
                self.ChildName = "UiGuildBossCurSubLevelInfo"
            end
        --如果是重灾区
        elseif data.Type == GuildBossLevelType.High then
            local highLevelInfo = XDataCenter.GuildBossManager.GetHighLevelInfo()
            if highLevelInfo ~= nil then
                if highLevelInfo.StageId == data.StageId then
                    self:OpenOneChildUi("UiGuildBossCurSubLevelInfo", self)
                    self.ChildName = "UiGuildBossCurSubLevelInfo"
                else
                    self:OpenOneChildUi("UiGuildBossOtherSubLevelInfo", self)
                    self.ChildName = "UiGuildBossOtherSubLevelInfo"
                end
            else
                self:OpenOneChildUi("UiGuildBossCurSubLevelInfo", self)
                self.ChildName = "UiGuildBossCurSubLevelInfo"
            end
        end
    end
end

function XUiGuildBossStage:GetLevelByStageId(stageId)
    for i = 1, #self.Levels do
        if self.Levels[i].Data.StageId == stageId then
            return self.Levels[i]
        end
    end
    return nil
end

--点击中间的boss关卡
function XUiGuildBossStage:OnBtnBossClick()
    if self.CurWindowMode == self.WindowMode.Order then
        return
    end
    --选中效果
    
    self.ImgBossSelect.gameObject:SetActiveEx(true)
    if self.CurSelectLevelData ~= nil then
        local curLevel = self:GetLevelByStageId(self.CurSelectLevelData.StageId)
        if curLevel then
            curLevel.ImgSelect.gameObject:SetActiveEx(false)
        end
    end
    
    self.CurSelectLevelData = XDataCenter.GuildBossManager.GetBossLevelInfo()
    self.CurStageData = self.CurSelectLevelData
    XDataCenter.GuildBossManager.SetCurSelectStageType(self.CurStageData.Type)
    XDataCenter.GuildBossManager.GuildBossStageRequest(self.CurSelectLevelData.StageId, function()
        self:OpenOneChildUi("UiGuildBossMainLevelInfo", self)
        self.ChildName = "UiGuildBossMainLevelInfo"
        self:ChangeMode(self.WindowMode.LevelDetail) 
    end)
end

--详情模式下点击空白出退出
function XUiGuildBossStage:OnBtnExitDetailClick()
    if self.CurWindowMode == self.WindowMode.LevelDetail then
        self:ResetToNormal()
    end
end

--确认发布战术布局
function XUiGuildBossStage:OnBtnConfirmClick()
    if self.CurWindowMode == self.WindowMode.Order then
        --判断是否设置完全
        for key, value in pairs(self.OrderData) do
            if value == 0 then
                XUiManager.TipError(CS.XTextManager.GetText("GuildBossLayoutError"))
                return
            end
        end
        --保存设置并退出布局模式
        local orderStr = ""
        for i = 1, #self.OrderData do
            orderStr = orderStr .. tostring(self.OrderData[i])
        end
        XDataCenter.GuildBossManager.GuildBossSetOrderRequest(orderStr, self:ChangeMode(self.WindowMode.Normal))
    end
end

--点击布局按钮，开始布局模式
function XUiGuildBossStage:OnBtnLayoutClick()
    --判断模式
    if self.CurWindowMode == self.WindowMode.Normal then
        --判断权限
        local curRank = XDataCenter.GuildManager.GetCurRankLevel()
        if curRank == XGuildConfig.GuildRankLevel.CoLeader or curRank == XGuildConfig.GuildRankLevel.Leader then
            --切换模式
            self:ChangeMode(self.WindowMode.Order)
        else
            local leaderStr = XDataCenter.GuildManager.GetRankNameByLevel(XGuildConfig.GuildRankLevel.Leader)
            local coleaderStr = XDataCenter.GuildManager.GetRankNameByLevel(XGuildConfig.GuildRankLevel.CoLeader)
            XUiManager.TipError(CS.XTextManager.GetText("GuildBossLayoutRankLevelError", leaderStr, coleaderStr))
        end
    end
end

--切换模式：普通模式/战术布局
function XUiGuildBossStage:ChangeMode(mode, cb)
    --退出布局的时候
    if self.CurWindowMode == self.WindowMode.Order and mode == self.WindowMode.Normal then
        self:PlayAnimation("AniConfirmLayoutDisable", cb)
        --清除布局标签
        for i = 1, #self.Levels do
            self.Levels[i]:HideOrder()
        end
        self.BtnExitDetail.gameObject:SetActiveEx(false)
        self:UpdateAllOrderMark()
    --进入布局的时候
    elseif self.CurWindowMode == self.WindowMode.Normal and mode == self.WindowMode.Order then
        self:PlayAnimation("AniConfirmLayoutEnable", cb)
        self.OrderData = {}
        for i = 1, XDataCenter.GuildBossManager.GetStageCount() do
            table.insert(self.OrderData, i, 0)
        end
        self.ToSetLowNum = 1
        self.ToSetHighNum = 1
        self.BtnExitDetail.gameObject:SetActiveEx(false)
    --从普通状态进入关卡详情
    elseif self.CurWindowMode == self.WindowMode.Normal and mode == self.WindowMode.LevelDetail then
        self:PlayAnimation("AniMainStageEnable", cb)
        self.BtnExitDetail.gameObject:SetActiveEx(true)
    --退出关卡详情到普通状态
    elseif self.CurWindowMode == self.WindowMode.LevelDetail and mode == self.WindowMode.Normal then
        self:PlayAnimation("AniMainStageDisable", cb)
        self.BtnExitDetail.gameObject:SetActiveEx(false)
    end
    self.CurWindowMode = mode
end

--设置优先标签
function XUiGuildBossStage:UpdateAllOrderMark()
    self:UpdateOrderMark(GuildBossLevelType.Low)
    self:UpdateOrderMark(GuildBossLevelType.High)
end

function XUiGuildBossStage:UpdateOrderMark(type)
    self.LevelData = XDataCenter.GuildBossManager.GetLevelData()
    local minLevel = nil
    for i = 1, #self.LevelData do
        if self.LevelData[i].Type == type then
            local levelComponent = self:GetLevelByStageId(self.LevelData[i].StageId)
            levelComponent:SetOrderMark(false)
            if self.LevelData[i].BuffNeed < 100 and self.LevelData[i].Order ~= 0 then
                if minLevel == nil then
                    minLevel = levelComponent
                else
                    if minLevel.Data.Order > self.LevelData[i].Order then
                        minLevel = levelComponent
                    end
                end
            end
        end
    end
    if minLevel ~= nil then
        minLevel:SetOrderMark(true)
    end
end

function XUiGuildBossStage:PlayBossAnimation()
    --本次战斗造成的伤害
    local damage = XDataCenter.GuildBossManager.GetCurFightBossHp()
    local contribute = XDataCenter.GuildBossManager.GetCurFightContribute()
    
    if XDataCenter.GuildBossManager.IsNeedUpdateStageInfo() then
        XDataCenter.GuildBossManager.SetNeedUpdateStageInfo(false)
        XDataCenter.GuildBossManager.GuildBossActivityRequest(function() self:UpdatePage(damage) end, true)
        self:ResetToNormal(function() 
            if damage > 0 then
                self.TxtBossDamage.text = damage
                self.TxtContribute.text = CS.XTextManager.GetText("GuildBossContribute", contribute)
                self.PanelBattleInfo.gameObject:SetActiveEx(true)
                local bossHpAnimTime = CS.XGame.ClientConfig:GetFloat("GuildBossHpAnimTime")
                local bossHpEffectTime = CS.XGame.ClientConfig:GetFloat("GuildBossHpEffectTime")

                self.CurStageObj = self:GetLevelByStageId(self.CurStageData.StageId)
                if self.CurStageData.Type == GuildBossLevelType.Boss then
                    self.PanelBossHpEffect.gameObject:SetActiveEx(false)
                    self.PanelBossHpEffect.gameObject:SetActiveEx(true)
                    self.PanelBossStageEffect.gameObject:SetActiveEx(false)
                    self.PanelBossStageEffect.gameObject:SetActiveEx(true)
                else
                    self.CurStageObj.PaneStagelEffect.gameObject:SetActiveEx(false)
                    self.CurStageObj.PaneStagelEffect.gameObject:SetActiveEx(true)
                    self.PanelBossHpEffect.gameObject:SetActiveEx(false)
                    self.PanelBossHpEffect.gameObject:SetActiveEx(true)
                end
                self.AnimTimer = XScheduleManager.ScheduleOnce(function() 
                    --刷新数据
                    self.CurStageData = XDataCenter.GuildBossManager.GetLevelDataByStageId(self.CurStageData.StageId)
                    if self.CurStageData.BuffNeed >= 100 then
                        local activityId = XSaveTool.GetData("GuildBossStageSkill" .. self.CurStageData.StageId .. XPlayer.Id)
                        if not activityId or activityId ~= XDataCenter.GuildBossManager.GetActivityId() then
                            XSaveTool.SaveData("GuildBossStageSkill" .. self.CurStageData.StageId .. XPlayer.Id, XDataCenter.GuildBossManager.GetActivityId())
                            self.CurStageObj.PaneStagelSkillEffect.gameObject:SetActiveEx(false)
                            self.CurStageObj.PaneStagelSkillEffect.gameObject:SetActiveEx(true)
                        end
                    end
                    self.AnimTimer2 = XUiHelper.Tween(bossHpAnimTime, function(f) self:UpdateBossHp(math.floor(damage * (1 - f))) end,
                    function()
                        self.PanelBossHpEffect.gameObject:SetActiveEx(false)
                        if self.CurStageObj then
                            self.CurStageObj.PaneStagelEffect.gameObject:SetActiveEx(false)
                            self.CurStageObj.PaneStagelSkillEffect.gameObject:SetActiveEx(false)
                        end
                        self.PanelBossStageEffect.gameObject:SetActiveEx(false)
                        self.PanelBattleInfo.gameObject:SetActiveEx(false)
                    end)
                end, math.floor(bossHpEffectTime * 1000))
                XDataCenter.GuildBossManager.SetCurFightBossHp(0)
            end
        end)
    end
end

function XUiGuildBossStage:UpdateCurSelectLevelData()
    self.LevelData = XDataCenter.GuildBossManager.GetLevelData()
    for i = 1, #LevelData do
        if self.CurSelectLevelData.StageId == self.LevelData[i].StageId then
            self.CurSelectLevelData = self.LevelData[i]
        end
    end
end
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
    self.BtnSelectStyle.CallBack = function() self:OnBtnSelectStyle() end
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
    self.Effect.gameObject:SetActiveEx(self.IsShowEffect) -- 刷新特效
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
    self.ImgBossHp.fillAmount = bossCurHp / bossMaxHp
    self.TxtBossCurHp.text = XUiHelper.GetLargeIntNumText(bossCurHp)
    self.PanelHpInfo.gameObject:SetActiveEx(bossCurHp > 0)
    self.PanelFinish.gameObject:SetActiveEx(bossCurHp == 0)
    self.Effect.gameObject:SetActiveEx(bossCurHp > 0)
    self.IsShowEffect = bossCurHp > 0
    self.TxtBossHpNum.text = leftHpNum
    self.TxtBossLv.text = " Lv." .. XDataCenter.GuildBossManager.GetCurBossLevel()
    self.TxtBossHp.text = XUiHelper.GetLargeIntNumText(bossMaxHp)
    -- boss头像 nzwjV3
    local bossInfo = XDataCenter.GuildBossManager.GetBossLevelInfo()
    local bossHeadIcon = XGuildBossConfig.GetBossStageInfo(bossInfo.StageId).BossHead
    self.ImgBossHead:SetRawImage(bossHeadIcon)
end

--如果damage>0则需要播放boss扣血动画
function XUiGuildBossStage:UpdatePage(damage)
    -- 刷新数据前再请求一次服务器
    XDataCenter.GuildBossManager.GuildBossInfoRequest(function() 
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
                self.Levels[i].TxtOrderGreen.transform.eulerAngles = self.VectorZero
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
        self:UiGuildBossHpReward()
        self:UpdateAllOrderMark()
    end)
end

--更新左边累计分数奖励及总分
function XUiGuildBossStage:UpdatePanelReward()
    local rewardData = XGuildBossConfig.ScoreRewards()
    local lastScore = 0 -- 用于控制每段的进度条长度
    for i = 1, #rewardData do
        local data = rewardData[i]
        --if XFunctionManager.CheckInTimeByTimeId(data.TimeId) then -- nzwjV3 适配版本更新周一切换奖励。逻辑为展示在 timeId 时间内的奖励物品
        if self.Rewards[i] == nil then
            self.Rewards[i] = XUiGuildBossRewardItem.New(self.Instantiate(self.BtnReward.gameObject), self)
        end
        self.Rewards[i].Transform:SetParent(self.PanelRewardBtn.transform)
        self.Rewards[i]:Init(data, lastScore) 
        lastScore = data.Score
        self.Rewards[i].Transform.localScale = self.VectorOne
        self.Rewards[i].Transform.position = self.BtnReward.transform.position
        --self.Rewards[i].RectTransform.anchoredPosition = self.Vector2(self.Rewards[i].RectTransform.anchoredPosition.x, 100 * i)
        self.Rewards[i].Transform.localEulerAngles = self.VectorZero
        self.Rewards[i].GameObject:SetActiveEx(true)
        --end
    end
    self.PanelRewardLayout:SetDirty()
    self.BtnDetail:SetName(XUiHelper.GetLargeIntNumText(XDataCenter.GuildBossManager.GetMyTotalScore()))
end

function XUiGuildBossStage:OnBtnRewardClick(rewardData)
    XDataCenter.GuildBossManager.GuildBossScoreBoxRequest(rewardData.Id, function() 
        self:UpdatePanelReward() 
    end)
end

--更新右上boss血量阶段奖励
function XUiGuildBossStage:UiGuildBossHpReward()
    
    --奖励数据
    local hpRewardData = XGuildBossConfig.HpRewards()
    local receiveAll = XDataCenter.GuildBossManager.IsHpRewardAllReceived()
    --全部领完
    if receiveAll then
        --当前领到第几阶段
        local curBossHpReward = XDataCenter.GuildBossManager.GetMaxBossHpGot()
        self.RewardGrids.gameObject:SetActiveEx(false)
        self.TxtBossRewardDone.gameObject:SetActiveEx(true)
        -- self.BtnBossHpRewardGet.gameObject:SetActiveEx(false)
        self.hasHpReward = false
        self.TxtTargetBlood.text = hpRewardData[curBossHpReward].HpPercent
    else
        self.HpRewardId = XDataCenter.GuildBossManager.GetMinReceivedId()
        self.RewardGrids.gameObject:SetActiveEx(true)
        self.TxtBossRewardDone.gameObject:SetActiveEx(false)
        local curHpPrecent = XDataCenter.GuildBossManager.GetCurBossHp() / XDataCenter.GuildBossManager.GetMaxBossHp() * 100
        self.TxtTargetBlood.text = hpRewardData[self.HpRewardId].HpPercent
        --可以领下一档
        if curHpPrecent <= hpRewardData[self.HpRewardId].HpPercent then
            -- self.BtnBossHpRewardGet.gameObject:SetActiveEx(true)
            self.hasHpReward = true
        --不能领
        else
            -- self.BtnBossHpRewardGet.gameObject:SetActiveEx(false)
            self.hasHpReward = false
        end
        --下一档的奖励Grid
        local rewardList = XRewardManager.GetRewardList(XDataCenter.GuildBossManager.GetHpRewardId(self.HpRewardId))
        self.GuildBossHpRewardGrid1 = XUiGridCommon.New(self, self.BossHpRewardGrid1Obj)
        self.GuildBossHpRewardGrid1:Refresh(rewardList[1])
        self.GuildBossHpRewardGrid2 = XUiGridCommon.New(self, self.BossHpRewardGrid2Obj)
        self.GuildBossHpRewardGrid2:Refresh(rewardList[2])
    end
    self.BtnBossHpRewardGet:ShowReddot(self.hasHpReward)
end

function XUiGuildBossStage:OnBtnBossHpRewardGetClick()
    if self.hasHpReward then
        XDataCenter.GuildBossManager.GuildBossHpBoxRequest(self.HpRewardId, function() self:UiGuildBossHpReward() end)
    else
        self:PlayAnimation("PanelHpRewardEnable", self.HpAnimationCB)
        self.PanelHpReward:Show()
        self.Effect.gameObject:SetActiveEx(false)
    end
end

function XUiGuildBossStage:ResetToNormal(cb, ...)
    self:ChangeMode(self.WindowMode.Normal, cb, ...)
    if self.ChildName then
        self.Effect.gameObject:SetActiveEx(self.IsShowEffect)
        self:CloseChildUi(self.ChildName)
    end
    self:ClearStageSelect()
    self.ImgBossSelect.gameObject:SetActiveEx(false)
    self.BossMask.gameObject:SetActiveEx(false)
end

--清除关卡boss外所有选中效果
function XUiGuildBossStage:ClearStageSelect()
    for i = 1, #self.Levels do
        self.Levels[i].ImgSelect.gameObject:SetActiveEx(false)
        self.Levels[i].MaskPos.gameObject:SetActiveEx(false)
    end
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
    self.BossMask.gameObject:SetActiveEx(false)
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
                btnStage.MaskPos.gameObject:SetActiveEx(true)
                self.ToSetLowNum = self.ToSetLowNum + 1
            else
                self.ToSetLowNum = self.OrderData[curOrderPos]
                for i = 1, #self.OrderData do
                    if allLevelData[i].Type == GuildBossLevelType.Low then
                        if self.OrderData[i] >= self.ToSetLowNum then
                            self.OrderData[i] = 0
                        end
                        self:GetLevelByStageId(allLevelData[i].StageId):SetOrder(self.OrderData[i])
                        self:GetLevelByStageId(allLevelData[i].StageId).MaskPos.gameObject:SetActiveEx(self.OrderData[i] > 0)
                    end
                end
            end
        elseif data.Type == GuildBossLevelType.High then
            if self.OrderData[curOrderPos] == 0 then
                self.OrderData[curOrderPos] = self.ToSetHighNum
                btnStage:SetOrder(self.ToSetHighNum)
                btnStage.MaskPos.gameObject:SetActiveEx(true)
                self.ToSetHighNum = self.ToSetHighNum + 1
            else
                self.ToSetHighNum = self.OrderData[curOrderPos]
                for i = 1, #self.OrderData do
                    if allLevelData[i].Type == GuildBossLevelType.High then
                        if self.OrderData[i] >= self.ToSetHighNum then
                            self.OrderData[i] = 0
                        end
                        self:GetLevelByStageId(allLevelData[i].StageId):SetOrder(self.OrderData[i])
                        self:GetLevelByStageId(allLevelData[i].StageId).MaskPos.gameObject:SetActiveEx(self.OrderData[i] > 0)
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
            curLevel.MaskPos.gameObject:SetActiveEx(false)
        end
    end
    self:GetLevelByStageId(data.StageId).ImgSelect.gameObject:SetActiveEx(true)
    self:GetLevelByStageId(data.StageId).MaskPos.gameObject:SetActiveEx(true)

    self.CurSelectLevelData = data
    local isPlayAnim = true -- 判断是否播放打开detail的动画，锁定的stage不播
    if data.Type ~= GuildBossLevelType.Boss then
        if data.Type == GuildBossLevelType.Low then
            local lowLevelInfo = XDataCenter.GuildBossManager.GetLowLevelInfo()
            if (lowLevelInfo ~= nil and lowLevelInfo.StageId ~= data.StageId) then
                isPlayAnim = false
            end
        elseif data.Type == GuildBossLevelType.High then
            local highLevelInfo = XDataCenter.GuildBossManager.GetHighLevelInfo()
            if  (highLevelInfo ~= nil and highLevelInfo.StageId ~= data.StageId) then
                isPlayAnim = false
            end
        end
    end

    self:ChangeMode(self.WindowMode.LevelDetail, nil, isPlayAnim)
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
                    self.Effect.gameObject:SetActiveEx(false)
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
                    self.Effect.gameObject:SetActiveEx(false)
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
    self.BossMask.gameObject:SetActiveEx(true)
    self:ClearStageSelect() -- 选中boss要清除所有其他关卡的选中效果
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
        self:ChangeMode(self.WindowMode.LevelDetail, nil, true) 
    end)
end

--详情模式下点击空白出退出
function XUiGuildBossStage:OnBtnExitDetailClick()
    if self.CurWindowMode == self.WindowMode.LevelDetail then
        self:ResetToNormal(nil, self.HasPlayDetailAnim)
    end
end

--风格选择
function XUiGuildBossStage:OnBtnSelectStyle()
    -- 向服务器请求风格信息 再打开
    XDataCenter.GuildBossManager.GuildBossStyleInfoRequest(function ()
        XLuaUiManager.Open("UiGuildBossSelectStyle")
    end)
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
function XUiGuildBossStage:ChangeMode(mode, cb, ...)
    local args = {...}
    --退出布局的时候
    if self.CurWindowMode == self.WindowMode.Order and mode == self.WindowMode.Normal then
        self:PlayAnimation("AniConfirmLayoutDisable", cb)
        --清除布局标签
        for i = 1, #self.Levels do
            self.Levels[i]:HideOrder()
            self.Levels[i].MaskPos.gameObject:SetActiveEx(false)
        end
        self.MainView:GetComponent("CanvasGroup").blocksRaycasts = true
        self:UpdateAllOrderMark()
    --进入布局的时候
    elseif self.CurWindowMode == self.WindowMode.Normal and mode == self.WindowMode.Order then
        self:PlayAnimation("AniConfirmLayoutEnable", cb)
        self.OrderData = {}
        for i = 1, XDataCenter.GuildBossManager.GetStageCount() do
            table.insert(self.OrderData, i, 0)
        end
        -- 进入布局时先清除所有标签
        self.LevelData = XDataCenter.GuildBossManager.GetLevelData() -- nzwjV3，不使用优先级标签，改为顺序标签
        for _, v in pairs(self.LevelData) do
            local levelComponent = self:GetLevelByStageId(v.StageId)
            if levelComponent then
                levelComponent:SetOrderOutSide(false)
            end
        end
        self.MainView:GetComponent("CanvasGroup").blocksRaycasts = false
        self.ToSetLowNum = 1
        self.ToSetHighNum = 1
    --从普通状态进入关卡详情
    elseif self.CurWindowMode == self.WindowMode.Normal and mode == self.WindowMode.LevelDetail then
        if args[1] then
            self:PlayAnimation("AniMainStageEnable", cb)
            self.HasPlayDetailAnim = true
        end
    --退出关卡详情到普通状态
    elseif self.CurWindowMode == self.WindowMode.LevelDetail and mode == self.WindowMode.Normal then
        if args[1] then    -- 锁定的stage不播放动画
            self:PlayAnimation("AniMainStageDisable", cb)
            self.HasPlayDetailAnim = false
        end
    end
    self.BtnExitDetail.gameObject:SetActiveEx(mode == self.WindowMode.LevelDetail)
    self.CurWindowMode = mode
end

--获得序号标签
function XUiGuildBossStage:GetStageOrderShow(type, stageId)
    if self[type] and self[type].OrderShowList then
        for order, value in pairs(self[type].OrderShowList) do
            if value.LevelData.StageId == stageId then
                return order
            end
        end
    end
end

--设置序号标签
function XUiGuildBossStage:UpdateAllOrderMark()
    self:UpdateOrderMark(GuildBossLevelType.Low)
    self:UpdateOrderMark(GuildBossLevelType.High)
end

function XUiGuildBossStage:UpdateOrderMark(type) 
    self.LevelData = XDataCenter.GuildBossManager.GetLevelData() -- nzwjV3，不使用优先级标签，改为顺序标签
    local orderList = {}
    for _, v in pairs(self.LevelData) do
        if v.Type == type then
            local order = v.Order
            local isBreakStage = v.CurEffectCount >= v.TotalEffectCount -- 触发次数
            if not isBreakStage and order and order > 0 then
                table.insert(orderList, {Order = order, LevelData = v})
            end
        end
    end
    table.sort(orderList, function (a,b)
        return a.Order < b.Order
    end)

    for i = 1, #orderList do
        local levelComponent = self:GetLevelByStageId(orderList[i].LevelData.StageId)
        levelComponent:SetOrderOutSide(i)
    end

    if not self[type] then
        self[type] = {}
    end
    self[type].OrderShowList = orderList
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
                    if self.CurStageData.CurEffectCount >= self.CurStageData.TotalEffectCount then
                        local activityId = XSaveTool.GetData("GuildBossStageSkill" .. self.CurStageData.StageId .. XPlayer.Id)
                        if self.CurStageObj and (not activityId or activityId ~= XDataCenter.GuildBossManager.GetActivityId()) then
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
        end, true)
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
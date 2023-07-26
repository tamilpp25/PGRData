local AUTO_REQ_ACTIVITY_DATA_INTERVAL = 2 * 60 * 1000 --界面打开后自动请求最新活动数据时间间隔(ms)
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local XUiAreaWarBoss = XLuaUiManager.Register(XLuaUi, "UiAreaWarBoss")

function XUiAreaWarBoss:OnAwake()
    self.UiType = XAreaWarConfigs.WorldBossUiType.Normal
end

function XUiAreaWarBoss:OnStart(blockId, closeCb)
    self.BlockId = blockId
    self.CloseCb = closeCb
    self.RewardGrids = {}

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(
    {
        XDataCenter.ItemManager.ItemId.AreaWarCoin,
        XDataCenter.ItemManager.ItemId.AreaWarActionPoint
    },
    handler(self, self.UpdateAssets),
    self.AssetActivityPanel
    )

    self.GridCommon.gameObject:SetActiveEx(false)
    self.PanelTime = self.Transform:FindTransform("PanelTime")

    self:AutoAddListener()
    self:InitView()
    self:InitReqActivityDataTimer()
end

function XUiAreaWarBoss:OnEnable()
    if self.IsEnd then
        return
    end
    if XDataCenter.AreaWarManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end

    self:UpdateAssets()
    self:UpdateView()
end

function XUiAreaWarBoss:OnDisable()
    self:DisposeTimer()
end

function XUiAreaWarBoss:OnDestroy()
    self:DisposeReqActivityDataTimer()
    if self.CloseCb then
        self.CloseCb(self.BlockId)
    end
end

function XUiAreaWarBoss:OnGetEvents()
    return {
        XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE,
        XEventId.EVENT_AREA_WAR_SELF_BLOCK_PURIFICATION_CHANGE,
        XEventId.EVENT_AREA_WAR_ACTIVITY_END
    }
end

function XUiAreaWarBoss:OnNotify(evt, ...)
    if self.IsEnd then
        return
    end

    local args = { ... }
    if
    evt == XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE or
    evt == XEventId.EVENT_AREA_WAR_SELF_BLOCK_PURIFICATION_CHANGE
    then
        self:UpdateView()
    elseif evt == XEventId.EVENT_AREA_WAR_ACTIVITY_END then
        if XDataCenter.AreaWarManager.OnActivityEnd() then
            self.IsEnd = true
            return
        end
    end
end

function XUiAreaWarBoss:AutoAddListener()
    self:BindHelpBtn(self.BtnHelp, "UiAreaWarBoss")
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
    self.BtnList.CallBack = function()
        self:OnClickBtnList()
    end
    self.BtnFight.CallBack = function()
        self:OnClickBtnFight()
    end
end

function XUiAreaWarBoss:InitView()
    local uiType = self.UiType

    --标题不是文字，是图片
    self.RImgTitle:SetRawImage(XAreaWarConfigs.GetWorldBossUiTitleIcon(uiType))

    --左右两边头像，名称
    local headNames = XAreaWarConfigs.GetWorldBossUiHeadName(uiType)
    local headIcons = XAreaWarConfigs.GetWorldBossUiHeadIcon(uiType)
    self.ImgLeft:SetSprite(headIcons[1])
    self.ImgRight:SetSprite(headIcons[2])
    self.TxtLeft.text = headNames[1]
    self.TxtRight.text = headNames[2]

    --怪物模型
    local root = self.UiModelGo.transform
    local modelIdDic = XAreaWarConfigs.GetWorldBossUiModelIdDic(self.UiType)
    for index, modelId in pairs(modelIdDic) do
        local panelModel = root:FindTransform("PanelModelCase" .. index)
        if not panelModel then
            XLog.Error("XUiAreaWarBoss:InitView error:模型挂点找不到: ", "PanelModelCase" .. index)
            goto CONTINUE
        end

        local effect = root:FindTransform("ImgEffectHuanren" .. index)
        if not effect then
            XLog.Error("XUiAreaWarBoss:InitView error:换人特效节点找不到: ", "ImgEffectHuanren" .. index)
            goto CONTINUE
        end
        effect.gameObject:SetActiveEx(false)

        local roleModel = XUiPanelRoleModel.New(panelModel, self.Name, nil, true, nil, true)
        roleModel:UpdateRoleModel(
        modelId,
        panelModel,
        XModelManager.MODEL_UINAME.XUiAreaWarBoss,
        function(model)
            effect.gameObject:SetActiveEx(true)
        end,
        nil
        )

        :: CONTINUE ::
    end
end

function XUiAreaWarBoss:UpdateAssets()
    self.AssetActivityPanel:Refresh(
    {
        XDataCenter.ItemManager.ItemId.AreaWarCoin,
        XDataCenter.ItemManager.ItemId.AreaWarActionPoint
    },
    {
        XDataCenter.ItemManager.ItemId.AreaWarActionPoint
    }
    )
end

function XUiAreaWarBoss:UpdateView()
    local blockId = self.BlockId
    local block = XDataCenter.AreaWarManager.GetBlock(blockId)

    local isOpen = XDataCenter.AreaWarManager.IsBlockWorldBossOpen(blockId)
    local isFinished = XDataCenter.AreaWarManager.IsBlockWorldBossFinish(blockId) --已攻破
    local isRepeatChallengeTime = XDataCenter.AreaWarManager.IsRepeatChallengeTime()
    local isClear = XDataCenter.AreaWarManager.IsBlockClear(blockId)
    local isFighting = (not isFinished and isOpen) or (isRepeatChallengeTime and isClear) --战斗中
    local isUnOpen = not isFinished and not isOpen --未开启
    
    self.PanelDefeat.gameObject:SetActiveEx(isFinished)
    self.PanelLock.gameObject:SetActiveEx(isUnOpen)
    self.Hint.gameObject:SetActiveEx(not isFinished and isOpen)
    self.TxtUnOpen.gameObject:SetActiveEx(isUnOpen)
    self.TxtEnd.gameObject:SetActiveEx(isFinished and not isRepeatChallengeTime)
    self.PanelTime.gameObject:SetActiveEx(false)

    --已攻破
    if isFinished then
        self.TxtPerson.text = block:GetFightCount()
        self.TxtDmg.text = block:GetSelfPurification()
        self.ImgFillAmount.fillAmount = 1
    else
        if not isOpen then
            --未开放
            local notOpenTips = CsXTextManagerGetText("AreaWarWorldBossUiTextNotOpen")
            self.TxtPerson.text = notOpenTips
            self.TxtDmg.text = notOpenTips
            self.ImgFillAmount.fillAmount = 0
        else
            --战斗中
            self.TxtPerson.text = block:GetFightCount()
            self.TxtDmg.text = block:GetSelfPurification()

            --进度条
            local progress = block:GetProgress()
            self.ImgFillAmount.fillAmount = progress
            self.TxtPercent.text = math.floor(progress * 100) .. "%"

            --这个小戳戳要跟着百分比进度条移动
            local width = self.ImgFillAmount.transform:GetComponent("RectTransform").rect.width
            local tf = self.Hint.transform
            tf.anchoredPosition = CS.UnityEngine.Vector2(width * progress, tf.anchoredPosition.y)

            --剩余时间
            self:UpdateLeftTime()
        end
    end

    --local showFight = isFinished or isOpen or isRepeatChallengeTime --显示作战按钮
    local showFight = isFighting --显示作战按钮
    self.PanelOpen.gameObject:SetActiveEx(showFight)
    self.PanelUnopen.gameObject:SetActiveEx(not showFight)
    self.BtnFight:SetDisable(not isFighting, isFighting)

    if showFight then
        --消耗行动点
        local costCount = XAreaWarConfigs.GetBlockActionPoint(blockId)
        self.TxtCost.text = costCount

        local icon = XDataCenter.AreaWarManager.GetActionPointItemIcon()
        self.RImgCost:SetRawImage(icon)
    else
        local worldBossOpenTime = block:GetWorldBossOpenTime()
        local validTime = XTool.IsNumberValid(worldBossOpenTime)
        self.TxtOpenDay.gameObject:SetActiveEx(validTime)
        self.TxtOpenTime.gameObject:SetActiveEx(validTime)
        --解锁与数据更新有时差
        if validTime then
            local openTime = XDataCenter.AreaWarManager.GetBlockWorldBossTime(blockId)
            self.TxtOpenDay.text = XTime.TimestampToGameDateTimeString(openTime, "MM/dd")

            local startHour, endHour = XAreaWarConfigs.GetBlockWorldBossHour(blockId)
            self.TxtOpenTime.text = CsXTextManagerGetText("AreaWarWorldBossOpenHour", startHour, endHour)
        end
    end

    --全服奖励展示
    local rewards = block:GetRewardItems()
    for index, item in ipairs(rewards) do
        local grid = self.RewardGrids[index]
        if not grid then
            local go = index == 1 and self.GridCommon or CSObjectInstantiate(self.GridCommon, self.PanelReward)
            grid = XUiGridCommon.New(self, go)
            self.RewardGrids[index] = grid
        end

        grid:Refresh(item)
        grid:SetReceived(isFinished)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #rewards + 1, #self.RewardGrids do
        self.RewardGrids[index].GameObject:SetActiveEx(false)
    end
end

function XUiAreaWarBoss:UpdateLeftTime()
    local _, endTime = XDataCenter.AreaWarManager.GetBlockWorldBossTime(self.BlockId)
    self.LeftTimeTimer =    self.LeftTimeTimer or
    XScheduleManager.ScheduleForever(
    function()
        if XTool.UObjIsNil(self.TxtLeftTime) then
            return
        end

        local leftTime = endTime - XTime.GetServerNowTimestamp()
        if leftTime < 0 then
            self:UpdateView()
            self:DisposeTimer()
            return
        end

        self.TxtLeftTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.PanelTime.gameObject:SetActiveEx(true)
    end,
    XScheduleManager.SECOND
    )
end

function XUiAreaWarBoss:OnClickBtnList()
    XDataCenter.AreaWarManager.OpenUiWorldBossBlockRank(self.BlockId)
end

function XUiAreaWarBoss:OnClickBtnFight()
    XDataCenter.AreaWarManager.TryEnterFight(self.BlockId)
end

--活动数据刷新定时器
function XUiAreaWarBoss:InitReqActivityDataTimer()
    self.ActivityDataTimer =    self.ActivityDataTimer or
    XScheduleManager.ScheduleForever(
    function()
        XDataCenter.AreaWarManager.AreaWarGetActivityDataRequest()
    end,
    AUTO_REQ_ACTIVITY_DATA_INTERVAL
    )
end

function XUiAreaWarBoss:DisposeReqActivityDataTimer()
    if self.ActivityDataTimer then
        XScheduleManager.UnSchedule(self.ActivityDataTimer)
        self.ActivityDataTimer = nil
    end
end

function XUiAreaWarBoss:DisposeTimer()
    if self.LeftTimeTimer then
        XScheduleManager.UnSchedule(self.LeftTimeTimer)
        self.LeftTimeTimer = nil
    end
end

return XUiAreaWarBoss
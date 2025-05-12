---@class XUiBagOrganizeGame: XLuaUi
---@field _Control XBagOrganizeActivityControl
---@field _GameControl XBagOrganizeActivityGameControl
---@field PanelScoreAnim UnityEngine.Animator
local XUiBagOrganizeGame = XLuaUiManager.Register(XLuaUi, 'UiBagOrganizeGame')

local XUiPanelBagOrganizeMap = require('XUi/XUiBagOrganizeActivity/UiBagOrganizeGame/PanelMap/XUiPanelBagOrganizeMap')
local XUiPanelBagOrganizeGoodsList = require('XUi/XUiBagOrganizeActivity/UiBagOrganizeGame/PanelGoodsList/XUiPanelBagOrganizeGoodsList')
local XUiPanelBagOrganizeBagList = require('XUi/XUiBagOrganizeActivity/UiBagOrganizeGame/PanelBagList/XUiPanelBagOrganizeBagList')
local XUiPanelBagOrganizeOption = require('XUi/XUiBagOrganizeActivity/UiBagOrganizeGame/PanelOperation/XUiPanelBagOrganizeOption')
local XUiPanelBagOrganizeGuide= require('XUi/XUiBagOrganizeActivity/UiBagOrganizeGame/PanelGuide/XUiPanelBagOrganizeGuide')
local XUiPanelBagOrganizeStop = require('XUi/XUiBagOrganizeActivity/UiBagOrganizeGame/XUiPanelBagOrganizeStop')
local XUiComBagOrganizeMapAnim = require('XUi/XUiBagOrganizeActivity/UiBagOrganizeGame/PanelMap/XUiComBagOrganizeMapAnim')


function XUiBagOrganizeGame:OnAwake()
    self.BtnBack.CallBack = function() self:OnClose()  end
    self.BtnMainUi.CallBack = function() self:OnClose(true)  end
    self:BindHelpBtn(self.BtnHelp, "BagOrganize", function() 
        -- 如果开启了限时玩法，关闭后继续游戏
        if self._GameControl:IsTimelimitEnabled() then
            self._GameControl.TimelimitControl:ResumeTimelimit()
        end
    end, function()
        -- 如果开启了限时玩法
        if self._GameControl:IsTimelimitEnabled() then
            self._GameControl.TimelimitControl:PauseTimelimit()
        end
    end)
    self:RegisterClickEvent(self.BtnResetting, self.OnResetEvent)
    self:RegisterClickEvent(self.BtnSubmmit, self.OnSubmmitEvent)
    self:RegisterClickEvent(self.BtnRatingDetail, self.OnRatingDetailBtnClick)
    self:RegisterClickEvent(self.BtnFinish, self.OnForceSubmitEvent)
end

function XUiBagOrganizeGame:OnStart()
    self._StageId = self._Control:GetCurStageId()
    self._GameControl = self._Control:GetGameControl()
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_TOTALSCORE_UPDATE, self.RefreshScore, self)
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_END_GAME, self.Close, self)
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_NEXT_STAGE_GAME, self.RefreshNewStage, self)
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_OPTIONSTATE_CHANGED, self.OnOptionStateChanged, self)
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_TIMELIMIT_RULE_UPDATE, self.OnTimerUpdate, self)
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_NEW_RANDOMEVENT_APPEAR, self.OnNewEventAppear, self)
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_RANDOMEVENT_OUTTIME, self.OnEventOuttime, self)

    self:InitMap()
    self:InitGoods()
    self:InitBags()
    self:InitOption()
    self:InitGuide()
    self:InitStopPanel()
    self:RefreshNewStage()
end

function XUiBagOrganizeGame:OnDestroy()
    self._Control:EndGameRelease()
end

--- 刷新新关卡的游戏界面，用于在当前界面直接更新关卡
function XUiBagOrganizeGame:RefreshNewStage()
    -- 协议请求时增加了遮罩，当打开了玩法界面后需要移除掉
    XLuaUiManager.SetMask(false)
    -- 默认隐藏限时玩法的事件入口
    self.PanelEvent.gameObject:SetActiveEx(false)
    
    self._StageId = self._Control:GetCurStageId()
    self._GameControl:InitGame()
    self._PanelMap:InitMap()
    self._PanelGoodsList:InitGoods(true)
    self._PanelBagList:InitBags()
    self._PanelOption:Close()
    self:RefreshScore()
    self._ResetTimes = 0
    self:RefreshGuideButtonShowState()
    self.BtnResetting:SetButtonState(not self._GameControl:IsCanResetGame() and CS.UiButtonState.Disable or CS.UiButtonState.Normal)

    -- 限时玩法没有重置，只有暂停
    local isTimelimit = self._GameControl:IsTimelimitEnabled()
    self.BtnResetting.gameObject:SetActiveEx(not isTimelimit)
    self.BtnStop.gameObject:SetActiveEx(isTimelimit)
    
    -- 限时玩法需要倒计时，且没有帮助
    self.BtnGuide.gameObject:SetActiveEx(not isTimelimit)
    self.PanelTime.gameObject:SetActiveEx(isTimelimit)

    self.BtnFinish.gameObject:SetActiveEx(false)
    
    -- 限时玩法开局暂停
    if isTimelimit then
        self._PanelStop:Open()
        self.BtnGuide.transform.parent.gameObject:SetActiveEx(false)
    end
end

function XUiBagOrganizeGame:InitMap()
    self._PanelMap = XUiPanelBagOrganizeMap.New(self.GridBlock.transform.parent.gameObject, self, self.GridBlock)
    self._PanelMap:Open()
    
    self.ComAnim = XUiComBagOrganizeMapAnim.New(self.PanelCheckerboard, self)
    self.ComAnim:Open()
end

function XUiBagOrganizeGame:GetBlockGridByIndex(index)
    return self._PanelMap:GetBlockGridByIndex(index)
end

function XUiBagOrganizeGame:InitGoods()
    self._PanelGoodsList = XUiPanelBagOrganizeGoodsList.New(self.ListGoods, self, handler(self, self.RefreshGoodsOption))
    self._PanelGoodsList:Open()
end

function XUiBagOrganizeGame:InitBags()
    self._PanelBagList = XUiPanelBagOrganizeBagList.New(self.PanelBag, self)
    self._PanelBagList:Open()
end

function XUiBagOrganizeGame:InitOption()
    self._PanelOption = XUiPanelBagOrganizeOption.New(self.PanelOption, self)
    self._PanelOption:Open()
end

function XUiBagOrganizeGame:InitGuide()
    self._PanelGuide = XUiPanelBagOrganizeGuide.New(self.PanelTipsnew, self)
    self._PanelGuide:Close()
    self.BtnGuide.CallBack = function() self._PanelGuide:Open() end
    self._GameResetTimesForTipsAppear = self._Control:GetClientConfigNum('GameResetTimesForTipsAppear')
end

function XUiBagOrganizeGame:InitStopPanel()
    self._PanelStop = XUiPanelBagOrganizeStop.New(self.PanelStop, self)
    self._PanelStop:Close()
    self.BtnStop.CallBack = handler(self, self.OpenPuasePanel)
end

function XUiBagOrganizeGame:OnResetEvent()
    if not self._GameControl:IsCanResetGame() or self:GetIsRequestLock() then
        return
    end
    
    local totalScore = self._GameControl:GetPackingTotalScore()
    XMVCA.XBagOrganizeActivity:RequestBagOrganizeSettle(self._StageId, XMVCA.XBagOrganizeActivity.EnumConst.SettleType.Reset, totalScore, function()
        -- 记录埋点
        self._Control:RecordGameData(XMVCA.XBagOrganizeActivity.EnumConst.SettleType.Reset)
        self._GameControl:ResetGame()
        self._GameControl:RefreshValidTotalScore()
        self:RefreshScore()
        -- 广播事件以刷新UI界面
        self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_CANCEL_ADD_GOODS)
        self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_GOODS_SHOW)
        self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_GOODS_LIST)
        self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_GOODS_USING_STATE)
        self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_CLOSE_ITEMOPTION)
        self.BtnResetting:SetButtonState(not self._GameControl:IsCanResetGame() and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
        self._ResetTimes = self._ResetTimes +1
        self:RefreshGuideButtonShowState()
    end)
end

function XUiBagOrganizeGame:OnSubmmitEvent()
    if self._LockSubmit or self:GetIsBtnEventLock() or self._HasAnyInvalidGoods or not self._IsScoreCanPacking then
        return
    end
    
    self:SetRequestLock(true)
    local isSubmit = self._GameControl:TryPacking(function(data, success, totalScore)
        self:SetRequestLock(false)
        if success and data then
            -- 记录埋点
            self._Control:RecordGameData(XMVCA.XBagOrganizeActivity.EnumConst.SettleType.Normal)
            self.ComAnim:PlayAnimationWithMask('UiBagOrganizeImgBox_end', function()
                XLuaUiManager.Open('UiBagOrganizePopupSettlement', self._StageId, totalScore, data)
            end)
        end
    end)

    if not isSubmit then
        -- 没有提交，需要刷新列表及地块显示
        self.ComAnim:PlayAnimationWithMask('UiBagOrganizeImgBox_end', function()
            self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_GOODS_SHOW)
            self._PanelGoodsList:InitGoods()
            self.ComAnim:PlayAnimationWithMask('UiBagOrganizeImgBox_star')
        end)
    end

    self.BtnResetting:SetButtonState(not self._GameControl:IsCanResetGame() and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

--- 强制提交，忽略当前打包的分数，只要有已打包的分数即可提交，用于多背包玩法
function XUiBagOrganizeGame:OnForceSubmitEvent()
    if self._LockSubmit or self:GetIsBtnEventLock() then
        return
    end
    
    -- 当前已提交的分数
    local curPackingScore = self._GameControl:GetPackingTotalScore()

    if XTool.IsNumberValid(curPackingScore) then
        self:SetRequestLock(true)
        
        XMVCA.XBagOrganizeActivity:RequestBagOrganizeSettle(self._StageId, XMVCA.XBagOrganizeActivity.EnumConst.SettleType.Normal, curPackingScore, function(data, success, totalScore)
            if success and data then
                -- 记录埋点
                self._Control:RecordGameData(XMVCA.XBagOrganizeActivity.EnumConst.SettleType.NormalForce)
                XLuaUiManager.OpenWithCallback('UiBagOrganizePopupSettlement', function()
                    self:SetRequestLock(false)
                end, self._StageId, totalScore, data)
            else
                self:SetRequestLock(false)
            end
        end)
    end
end

function XUiBagOrganizeGame:OnRatingDetailBtnClick()
    if self:GetIsBtnEventLock() then
        return
    end
    
    self:SetUiOpenLock(true)
    XLuaUiManager.OpenWithCallback('UiBagOrganizePopupRankDetails', function()
        self:SetUiOpenLock(false)
    end)
end

function XUiBagOrganizeGame:OnRandomEventDetailBtnClick()
    XLuaUiManager.OpenWithCallback('UiBagOrganizePopupEventDetails', function()
        self.PanelEvent.gameObject:SetActiveEx(false)
        self:SetEventAutoPopLock(false)
    end)
end

function XUiBagOrganizeGame:OnClose(isRunMain)
    if self:GetIsBtnEventLock() or self._PanelStop:IsNodeShow() then
        return
    end
    
    self:SetRequestLock(true)    
    -- 如果开启了限时玩法，则需要暂停
    if self._GameControl:IsTimelimitEnabled() then
        self._PanelStop:Open()
    end
    
    XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), self._Control:GetClientConfigText('GameGiveUpTips'), nil, function()
        self:SetRequestLock(false)
    end, function()
        self:GiveUpAndClose(isRunMain)
        self:SetRequestLock(false)
    end)
end

function XUiBagOrganizeGame:GiveUpAndClose(isRunMain)
    local totalScore = self._GameControl:GetPackingTotalScore()
    XMVCA.XBagOrganizeActivity:RequestBagOrganizeSettle(self._StageId, XMVCA.XBagOrganizeActivity.EnumConst.SettleType.GiveUp, totalScore, function()
        -- 记录埋点
        self._Control:RecordGameData(XMVCA.XBagOrganizeActivity.EnumConst.SettleType.GiveUp)
        if isRunMain then
            XLuaUiManager.RunMain()
        else
            self:Close()
        end
    end)
end

function XUiBagOrganizeGame:RefreshGoodsOption(goods)
    if goods then
        self._GameControl:CreateNewGoodsToPrePlace(goods:GetId())
        self._PanelOption:Open()
        self._PanelOption:RefreshNewItem()
    else
        self._PanelOption:DeleteByHand()
    end
end

function XUiBagOrganizeGame:RefreshScore()
    -- 按照实时总分（已打包部分和正在打包部分）进行评级
    local curTotalScore = self._GameControl:GetValidTotalScore()
    
    -- 所有打包均显示当次正在打包的预览分
    local curPackingScore = self._GameControl:GetCurValidScore()
    
    if self._GameControl:IsMultyBagEnabled() then
        -- 多背包玩法需要区分显示已打包的部分和当前正在打包部分的分数
        local validScore = self._GameControl:GetPackingTotalScore()
        self.TxtValidScore.gameObject:SetActiveEx(true)
        self.TxtValidScore.text = XUiHelper.FormatText(self._Control:GetClientConfigText('ValidScoreLabel'), validScore)
        self.TxtPreviewScore.text = XUiHelper.FormatText(self._Control:GetClientConfigText('PreviewScoreLabel'), curPackingScore)

        local iconUrl = self._Control:GetScoreLevelIconByStageIdAndScore(self._StageId, validScore)
        self.RImgRating:SetRawImage(iconUrl)

        if self._LastIconUrl ~= iconUrl and self.PanelScoreAnim then
            self.PanelScoreAnim:Play('GamePanelScore')
        end
        
        self._LastIconUrl = iconUrl
    else
        -- 单背包玩法仅显示当前正在打包的文本，且显示总得分
        self.TxtValidScore.gameObject:SetActiveEx(false)
        self.TxtPreviewScore.text = XUiHelper.FormatText(self._Control:GetClientConfigText('PreviewScoreLabel'), curTotalScore)

        local iconUrl = self._Control:GetScoreLevelIconByStageIdAndScore(self._StageId, curTotalScore)
        self.RImgRating:SetRawImage(iconUrl)

        if self._LastIconUrl ~= iconUrl then
            self:PlayAnimation('PanelScore')
        end
        
        self._LastIconUrl = iconUrl
    end
    
    self._IsScoreCanPacking = curPackingScore > 0
    
    -- 刷新分数的同时还要根据当前星级进度刷新提交按钮的状态
    self._HasAnyInvalidGoods = self._GameControl:IsMultyBagEnabled() and self._GameControl.GoodsControl:CheckAnyPlacedGoodsIsInvalid()
    
    if not self._LockSubmit then
        self.BtnSubmmit:SetButtonState(self._HasAnyInvalidGoods and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
        
        -- 多背包玩法下有已提交的分数时显示结算按钮可忽略当前打包直接按已提交的分数结算
        local isShowFinishBtn =  self._GameControl:IsMultyBagEnabled() and not self._GameControl:IsTimelimitEnabled() and XTool.IsNumberValid(self._GameControl:GetPackingTotalScore())
        self.BtnFinish.gameObject:SetActiveEx(isShowFinishBtn)
    end

    if not self._IsScoreCanPacking then
        self.BtnSubmmit:SetButtonState(CS.UiButtonState.Disable)
    end
end

function XUiBagOrganizeGame:OnTimerUpdate(leftTime, isBegin)
    self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.MINUTE_SECOND)
    self.TxtPeriodTips.text = self._GameControl.TimelimitControl:GetCurPeriodDesc()

    if self.TxtPeriodTitle then
        self.TxtPeriodTitle.text = self._GameControl.TimelimitControl:GetCurPeriodTitle()
    end

    if leftTime <= 0 then
        self:SetRequestLock(true)
        self._GameControl:SubmitHadPackingResult(function(data, success, totalScore)
            if success and data then
                -- 记录埋点
                self._Control:RecordGameData(XMVCA.XBagOrganizeActivity.EnumConst.SettleType.Normal)
                
                -- 保底逻辑
                if XLuaUiManager.IsUiShow('UiBagOrganizePopupRankDetails') then
                    XLog.Error('[BagOrganize]错误地在限时结算时打开了评分详情界面, 执行关闭逻辑...')
                    XLuaUiManager.Remove('UiBagOrganizePopupRankDetails')
                end

                if XLuaUiManager.IsUiShow('UiDialog') then
                    XLog.Error('[BagOrganize]错误地在限时结算时打开了退出确认界面, 执行关闭逻辑...')
                    XLuaUiManager.Remove('UiDialog')
                end
                
                XLuaUiManager.OpenWithCallback('UiBagOrganizePopupSettlement',function()
                    self:SetRequestLock(false)
                end, self._StageId, totalScore, data)
            else
                self:SetRequestLock(false)
            end
        end)
    else
        -- 事件自动弹出
        if not isBegin and not self._GameControl.TimelimitControl:IsPause() and not self:GetIsEventAutoPopLock() and self._GameControl.TimelimitControl:CheckHasRandomEvent() then
            self:SetEventAutoPopLock(true)
            self:PlayAnimation('Phoneshake', handler(self, self.OnRandomEventDetailBtnClick))
        end
    end
end

function XUiBagOrganizeGame:OnOptionStateChanged(isOpen)
    self._HasAnyInvalidGoods = self._GameControl:IsMultyBagEnabled() and self._GameControl.GoodsControl:CheckAnyPlacedGoodsIsInvalid()
    
    if isOpen then
        self.BtnSubmmit:SetButtonState(CS.UiButtonState.Disable)
    elseif self._IsScoreCanPacking and not self._HasAnyInvalidGoods then
        self.BtnSubmmit:SetButtonState(CS.UiButtonState.Normal)
    end

    self.BtnFinish:SetButtonState(isOpen and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    
    self._LockSubmit = isOpen

    
    
    self.BtnResetting:SetButtonState(not self._GameControl:IsCanResetGame() and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

function XUiBagOrganizeGame:RefreshGuideButtonShowState()
    if self._Control:CheckIsShowTips() then
        self.BtnGuide.gameObject:SetActiveEx(true)
    else
        if (XTool.IsNumberValid(self._ResetTimes) and self._ResetTimes >= self._GameResetTimesForTipsAppear) or not XTool.IsNumberValid(self._GameResetTimesForTipsAppear) then
            self.BtnGuide.gameObject:SetActiveEx(true)
            self._Control:SetStageTipsIsShow()
        else
            self.BtnGuide.gameObject:SetActiveEx(false)
        end
    end
end

function XUiBagOrganizeGame:OnNewEventAppear()
    ---@type XTableBagOrganizeEvent
    local cfg = self._GameControl.TimelimitControl:GetCurPeriodRandomEventCfg()

    if cfg then
        self.PanelEvent.gameObject:SetActiveEx(true)
        self.PanelEvent:SetRawImage(cfg.EntranceIcon)
    end
end

function XUiBagOrganizeGame:OnEventOuttime()
    self.PanelEvent.gameObject:SetActiveEx(false)
end

function XUiBagOrganizeGame:OpenPuasePanel()
    -- 如果正在播放事件动画，则不能暂停
    if self:GetIsBtnEventLock() then
        return
    end
    
    self._PanelStop:Open()
end

--region 点击响应拦截相关

--- 设置请求锁定，请求服务端协议间隔期间不可点击响应
function XUiBagOrganizeGame:SetRequestLock(isLock)
    self._IsRequestLock = isLock
    
    self.BtnHelp.enabled = not isLock and not self:GetIsEventAutoPopLock()
end

function XUiBagOrganizeGame:GetIsRequestLock()
    return self._IsRequestLock
end

--- 设置限时关卡随机事件弹窗锁定，完全弹出期间不可进行其他响应操作
function XUiBagOrganizeGame:SetEventAutoPopLock(isLock)
    self._LockEventAutoPop = isLock

    self.BtnHelp.enabled = not isLock and not self:GetIsRequestLock()
end

--- 弹窗锁定，防止新窗口加载间隙的操作
function XUiBagOrganizeGame:SetUiOpenLock(isLock)
    self._IsUiOpenLock = isLock
end

function XUiBagOrganizeGame:GetIsUiOpenLock()
    return self._IsUiOpenLock
end

function XUiBagOrganizeGame:GetIsEventAutoPopLock()
    return self._LockEventAutoPop
end

--- 是否锁定了按钮点击事件
function XUiBagOrganizeGame:GetIsBtnEventLock()
    return self:GetIsRequestLock() or self:GetIsEventAutoPopLock() or self:GetIsUiOpenLock()
end
--endregion

return XUiBagOrganizeGame
---@class XUiGame2048Game: XLuaUi
---@field _Control XGame2048Control
---@field _GameControl XGame2048GameControl
local XUiGame2048Game = XLuaUiManager.Register(XLuaUi, 'UiGame2048Game')
local XUiPanelGame2048BuffList = require('XUi/XUiGame2048/UiGame2048Game/PanelBuffList/XUiPanelGame2048BuffList')
local XUiPanelGame2048ShowCharacter = require('XUi/XUiGame2048/UiGame2048Game/PanelShowCharacter/XUiPanelGame2048ShowCharacter')
local XUiPanelGame2048Map = require('XUi/XUiGame2048/UiGame2048Game/PanelMap/XUiPanelGame2048Map')
local XUiPanelGame2048Score = require('XUi/XUiGame2048/UiGame2048Game/PanelScore/XUiPanelGame2048Score')
local XUiPanelGame2048Fever = require('XUi/XUiGame2048/UiGame2048Game/PanelFever/XUiPanelGame2048Fever')

function XUiGame2048Game:OnAwake()
    self.BtnBack.CallBack = function()
        self:TryExitGame(false, false)
    end
    self.BtnMainUi.CallBack = function()
        self:TryExitGame(true, false)
    end
    
    self.BtnGiveUp.CallBack = handler(self, self.SettleByHand)
    self.BtnHelp.CallBack = handler(self, self.OnBtnHelpClick)
    self._Control:EnterGameInit()
end

function XUiGame2048Game:OnStart(context)
    self._GameControl = self._Control:GetGameControl()
    
    self._BuffList = XUiPanelGame2048BuffList.New(self.ListSkill, self)
    self._BuffList:Open()
    
    self._PanelShowCharacter = XUiPanelGame2048ShowCharacter.New(self.RoleRoot, self)
    self._PanelShowCharacter:Open()
    
    self._PanelMap = XUiPanelGame2048Map.New(self.PanelCheckerboard, self)
    self._PanelMap:Open()
    
    self._PanelScore = XUiPanelGame2048Score.New(self.PanelScore, self)
    self._PanelScore:Open()
    
    self._PanelFever = XUiPanelGame2048Fever.New(self.PanelFever, self)
    self._PanelFever:Open()

    -- 首次进入界面要及时更新样式
    self:InitTheme()
    self._FirstInit = false
    XScheduleManager.ScheduleNextFrame(function()
        self:InitGame(context)
        -- 新进来需要检查下有没之前遗留的buff需要重新处理的
        -- 执行机制逻辑
        self._GameControl:DoBuff(true)
        -- 尝试一次动画播放
        self._GameControl.ActionsControl:StartActionList()
        self._FirstInit = true
    end)
    
    self._GameControl:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_REFRESH_DATA, self.Refresh, self)
    self._GameControl:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_GAMEOVER, self.OnGameOverEvent, self)
    self._GameControl:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_TRY_EXIT_GAME, self.OnEventExitGame, self)

    XMVCA.XGame2048:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_ON_RECORD_LOADED, self.InitGame, self)

end

function XUiGame2048Game:OnEnable()
    if not self._FirstInit then
        self:OnNewGameEnterAnim()
    end 
end

function XUiGame2048Game:OnDestroy()
    if self._FxStepUpShowTimeId then
        XScheduleManager.UnSchedule(self._FxStepUpShowTimeId)
        self._FxStepUpShowTimeId = nil
        self.FxStepUp.gameObject:SetActiveEx(false)
    end

    if self._GameSettlePopTimeId then
        XScheduleManager.UnSchedule(self._GameSettlePopTimeId)
        XLuaUiManager.SetMask(false)
        self._GameSettlePopTimeId = nil
    end
    
    XMVCA.XGame2048:RemoveEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_ON_RECORD_LOADED, self.InitGame, self)
end

function XUiGame2048Game:OnEventExitGame()
    self:TryExitGame(false, false)
end

function XUiGame2048Game:TryExitGame(isRunMain, isOverGame)
    if not self._FirstInit then
        return
    end

    if self._GameControl:GetIsUsingProp() or self._GameControl:GetIsActionPlaying() or self._GameControl:GetIsWaitForNextStep() or self._Control:GetIsWaitForSettle() then
        return
    end

    self:OnExitGame(isRunMain, isOverGame)
end

function XUiGame2048Game:OnExitGame(isRunMain, isOverGame)
    self._Control:ExitGameRelease(isOverGame)

    if isRunMain then
        XLuaUiManager.RunMain()
    else
        self:Close()
    end
end

function XUiGame2048Game:InitTheme()
    --设置棋盘背景
    local curChapterId = self._Control:GetCurChapterId()
    self.BoardImgBg:SetRawImage(self._Control:GetChapterGameBoardBgById(curChapterId))
    self.BoardMaskImgBg:SetRawImage(self._Control:GetChapterGameBoardBgMaskById(curChapterId))
    self.BoardBlockImgBg:SetRawImage(self._Control:GetChapterGameBoardBlocksBgById(curChapterId))
    -- 设置步数颜色
    local stepColor = self._Control:GetChapterStepColorById(curChapterId)
    if not string.IsNilOrEmpty(stepColor) then
        self.TxtStep.color = XUiHelper.Hexcolor2Color(string.gsub(stepColor, '#', ''))
        self.TxtTips.color = XUiHelper.Hexcolor2Color(string.gsub(stepColor, '#', ''))
    end
end

function XUiGame2048Game:InitGame(context)
    if self._FirstInit then
        self:OnNewGameEnterAnim()
    end
    
    self._StageId = self._Control:GetCurStageId()
    self._StageType = self._Control:GetStageTypeById(self._StageId)
    self._GameControl:InitGame(context)
    self._BuffList:InitBuffs()
    self._PanelShowCharacter:InitShowCharacter()
    self._PanelMap:RefreshMap()
    self._PanelScore:InitScore()
    self._PanelFever:OnNewGameInit()
    self:Refresh()
    self.TxtTips.text = self._Control:GetClientConfigText('TxtStepsTips', self._StageType)
    
    self:InitTheme()
    
    -- 主动请求检查引导
    XDataCenter.GuideManager.CheckGuideOpen()

    if self._FxStepUpShowTimeId then
        XScheduleManager.UnSchedule(self._FxStepUpShowTimeId)
        self._FxStepUpShowTimeId = nil
        self.FxStepUp.gameObject:SetActiveEx(false)
    end
end

function XUiGame2048Game:OnNewGameEnterAnim()
    local isSuccessBegin = false

    if CS.XInputManager.CurInputMapID == CS.XInputMapId.Game2048 then
        XDataCenter.InputManagerPc.SetCurInputMap(CS.XInputMapId.System)
    end

    self:PlayAnimationWithMask('Enable', function()
        XDataCenter.InputManagerPc.SetCurInputMap(CS.XInputMapId.Game2048)
    end, function()
        isSuccessBegin = true
    end)

    if not isSuccessBegin then
        XDataCenter.InputManagerPc.SetCurInputMap(CS.XInputMapId.Game2048)
    end
end

function XUiGame2048Game:Refresh()
    local leftSteps = self._GameControl.TurnControl:GetLeftStepsCount()
    
    if self._StageType == XMVCA.XGame2048.EnumConst.StageType.Normal then
        self.TxtStep.text = leftSteps
    elseif self._StageType == XMVCA.XGame2048.EnumConst.StageType.Endless then
        local curSteps = self._GameControl.TurnControl:GetCurStepsCount()
        self.TxtStep.text = curSteps
    end

    if self.FxStepUp and self._LastLeftSteps ~= leftSteps then
        if self._FxStepUpShowTimeId then
            XScheduleManager.UnSchedule(self._FxStepUpShowTimeId)
            self._FxStepUpShowTimeId = nil
        end
        
        self.FxStepUp.gameObject:SetActiveEx(false)
        self._FxStepUpShowTimeId = XScheduleManager.ScheduleNextFrame(function()
            self.FxStepUp.gameObject:SetActiveEx(true)
        end)
    end

    self._LastLeftSteps = leftSteps

    if leftSteps <= 0 then
        self._Control:RequestGame2048Settle(XMVCA.XGame2048.EnumConst.SettleType.StepEmpty, function(res)
            self._GameControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_GAMEOVER, res)
            self._GameControl.BoardShowControl:OnStageEnd()
        end)
    end
    
    
end

function XUiGame2048Game:OnGameOverEvent(res, noResume, popDelay)
    if not noResume then
        self._GameControl:ResumeCurInputMap()
    end

    if self._GameSettlePopTimeId then
        XScheduleManager.UnSchedule(self._GameSettlePopTimeId)
        XLuaUiManager.SetMask(false)
        self._GameSettlePopTimeId = nil
    end
    
    XLuaUiManager.SetMask(true)
    
    local popFunc = function()
        XLuaUiManager.OpenWithCallback("UiGame2048PopupSettlement", function()
            XLuaUiManager.SetMask(false)
        end, res, function(isExit, newStageId)
            if isExit then
                self:OnExitGame(false, true)
            else
                self._Control:RequestGame2048EnterStage(newStageId or self._StageId, function(res)
                    self._Control:SetCurStageId(res.StageContext.StageId)
                    self:InitGame(res.StageContext)
                end)
            end
        end)

        self._GameSettlePopTimeId = nil
    end

    if XTool.IsNumberValid(popDelay) then
        self._GameSettlePopTimeId = XScheduleManager.ScheduleOnce(popFunc, popDelay * XScheduleManager.SECOND)
    else
        popFunc()
    end
end

function XUiGame2048Game:SettleByHand()
    if self._GameControl:GetIsUsingProp() or self._GameControl:GetIsActionPlaying() or self._GameControl:GetIsWaitForNextStep() or self._Control:GetIsWaitForSettle() then
        return
    end
    
    self._GameControl:ResumeCurInputMap()
    XUiManager.DialogTip(CS.XTextManager.GetText("TipTitle"), self._Control:GetClientConfigText('SettleByHandTips'), nil, function()
        XDataCenter.InputManagerPc.SetCurInputMap(CS.XInputMapId.Game2048)
    end, function() 
        self._Control:RequestGame2048Settle(XMVCA.XGame2048.EnumConst.SettleType.ByHand, function(res)
            self:OnGameOverEvent(res, true)
            self._GameControl.BoardShowControl:OnStageEnd()
        end)
    end)
end

function XUiGame2048Game:OnBtnHelpClick()
    if self._GameControl:GetIsUsingProp() or self._GameControl:GetIsActionPlaying() or self._GameControl:GetIsWaitForNextStep() or self._Control:GetIsWaitForSettle() then
        return
    end
    self._GameControl:ResumeCurInputMap()
    XUiManager.ShowHelpTip("Game2048", function()
        XDataCenter.InputManagerPc.SetCurInputMap(CS.XInputMapId.Game2048)
    end)
end

function XUiGame2048Game:SetGiveUpBtnShow(isShow)
    self.BtnGiveUp.gameObject:SetActiveEx(isShow)
end

return XUiGame2048Game
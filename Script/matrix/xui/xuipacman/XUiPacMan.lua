local XUiPacManAnswerOption = require("XUi/XUiPacMan/XUiPacManAnswerOption")

---@class XUiPacMan : XLuaUi
---@field _Control XPacManControl
local XUiPacMan = XLuaUiManager.Register(XLuaUi, "UiPacMan")

function XUiPacMan:Ctor()
    self._PlayedStory = {}
    self._IsWin = false
    self._IsGameOver = false
    self._IsPlayingRecord = false

    ---@type XTable.XTablePacManStory[]
    self._Story = false
    self._StoryIndex = 0
    self._StoryOptionIndex = 1

    self._AnswerOption = {}
    ---@type XUiPacManAnswerOptionData[]
    self._DataAnswerOption = false

    self._Time = 0
end

function XUiPacMan:OnAwake()
    self:BindExitBtns()

    self._Fire = function()
        self:OnClickFire()
    end

    self.BtnTop:AddPointerDownListener(function()
        self:OnClickUp()
    end)
    self.BtnLeft:AddPointerDownListener(function()
        self:OnClickLeft()
    end)
    self.BtnRight:AddPointerDownListener(function()
        self:OnClickRight()
    end)
    self.Btndown:AddPointerDownListener(function()
        self:OnClickDown()
    end)
    self.BtnY:AddPointerDownListener(function()
        self:OnClickFire()
    end)
    self.BtnX:AddPointerDownListener(function()
        self:OnClickFire()
    end)
    self.BtnB:AddPointerDownListener(function()
        self:OnClickFire()
    end)
    self.BtnA:AddPointerDownListener(function()
        self:OnClickFire()
    end)
    --XUiHelper.RegisterClickEvent(self, self.BtnTop, self.OnClickUp)
    --XUiHelper.RegisterClickEvent(self, self.BtnLeft, self.OnClickLeft)
    --XUiHelper.RegisterClickEvent(self, self.BtnRight, self.OnClickRight)
    --XUiHelper.RegisterClickEvent(self, self.Btndown, self.OnClickDown)
    --XUiHelper.RegisterClickEvent(self, self.BtnY, self.OnClickFire)
    --XUiHelper.RegisterClickEvent(self, self.BtnX, self.OnClickFire)
    --XUiHelper.RegisterClickEvent(self, self.BtnB, self.OnClickFire)
    --XUiHelper.RegisterClickEvent(self, self.BtnA, self.OnClickFire)

    XDataCenter.InputManagerPc.SetCurInputMap(CS.XInputMapId.ActivityGame)
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XEnumConst.GAME_PC_KEY.Space, self._Fire)
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XEnumConst.GAME_PC_KEY.Left, handler(self, self.OnClickLeft))
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XEnumConst.GAME_PC_KEY.Right, handler(self, self.OnClickRight))
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XEnumConst.GAME_PC_KEY.Up, handler(self, self.OnClickUp))
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XEnumConst.GAME_PC_KEY.Down, handler(self, self.OnClickDown))

    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XEnumConst.GAME_PC_KEY.Alpha1, self._Fire)
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XEnumConst.GAME_PC_KEY.Alpha2, self._Fire)
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XEnumConst.GAME_PC_KEY.Alpha3, self._Fire)
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XEnumConst.GAME_PC_KEY.Alpha4, self._Fire)

    if XMain.IsZlbDebug then
        XUiHelper.RegisterClickEvent(self, self.BtnA, self.Close)
    end
    self.PanelTalk.gameObject:SetActiveEx(false)
    self.Answer.gameObject:SetActiveEx(false)
end

function XUiPacMan:OnStart(stageId)
    local instance = CS.XFight.Instance
    if instance and instance.IsReplay then
        self._IsPlayingRecord = true
    end

    if not stageId then
        XLog.Error("[XUiPacMan] 没有传stageId:" .. tostring(stageId))
        XScheduleManager.ScheduleNextFrame(function()
            XLuaUiManager.Close("UiPacMan")
        end)
        return
    end
    ---@type XTable.XTablePacManStage
    local stage = self._Control:GetStage(stageId)
    if not stage then
        XLog.Error("[XUiPacMan] stageId找不到对应配置(PacManStage.tab):" .. tostring(stageId))
        XScheduleManager.ScheduleNextFrame(function()
            XLuaUiManager.Close("UiPacMan")
        end)
        return
    end
    local prefab = stage.Prefab
    local time = stage.Time
    self._Time = time
    if XMain.IsZlbDebug then
        self._Time = 99999999999
    end

    --local gameObject = self.UiSceneInfo.Transform:LoadPrefab(prefab, true, true, true)
    local gameObject = self.UiSceneInfo.Transform:LoadPrefab(prefab, true, true)
    ---@type XPacMan.XPacManGameManager
    self._Game = gameObject:GetComponent("XPacManGameManager")

    if XMain.IsZlbDebug then
        self._Game.PacMan.MaxLives = 99
        self._Game.PacMan.Lives = 99
    end

    self._UpdateProgress = function()
        self:UpdateProgress()
    end
    self._ListenPlayStory = function(eventName, params)
        local storyId = tonumber(params[0])
        if storyId then
            self:PlayStory(storyId)
        end
    end
    -- 退出战斗 or 重开，关闭ui
    self._OnFightExit = function()
        self:Close()
    end

    local fight = CS.XFight.Instance
    if fight then
        fight:Pause()
    end
    CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_ON_FIGHT_EXIT, self._OnFightExit)
end

function XUiPacMan:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_PACMAN_STORY_NEXT, self.StoryNext, self)
    CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_PACMAN_UPDATE_PROGRESS, self._UpdateProgress)
    CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_PACMAN_PLAY_STORY, self._ListenPlayStory)

    self._Timer = XScheduleManager.ScheduleForever(function()
        self:Update()
    end, 0)
    self:Update()
    self:UpdateProgress()
end

function XUiPacMan:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PACMAN_STORY_NEXT, self.StoryNext, self)
    CS.XGameEventManager.Instance:RemoveEvent(XEventId.EVENT_PACMAN_UPDATE_PROGRESS, self._UpdateProgress)
    CS.XGameEventManager.Instance:RemoveEvent(XEventId.EVENT_PACMAN_PLAY_STORY, self._ListenPlayStory)

    XScheduleManager.UnSchedule(self._Timer)
    self._Timer = false

end

function XUiPacMan:OnDestroy()
    local CSXInputManager = CS.XInputManager
    local XOperationType = CS.XInputManager.XOperationType
    CSXInputManager.UnregisterOnClick(XOperationType.ActivityGame, self._OnOperation)
    --XDataCenter.InputManagerPc.SetCurInputMap(CS.XInputMapId.Fight)
    XDataCenter.InputManagerPc.ResumeCurInputMap()

    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XEnumConst.GAME_PC_KEY.Space)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XEnumConst.GAME_PC_KEY.Left)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XEnumConst.GAME_PC_KEY.Right)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XEnumConst.GAME_PC_KEY.Up)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XEnumConst.GAME_PC_KEY.Down)

    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XEnumConst.GAME_PC_KEY.Alpha1)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XEnumConst.GAME_PC_KEY.Alpha2)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XEnumConst.GAME_PC_KEY.Alpha3)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XEnumConst.GAME_PC_KEY.Alpha4)

    local prefabComponent = self.UiSceneInfo.Transform:GetComponent("XUiLoadPrefab")
    if prefabComponent then
        CS.UnityEngine.Object.Destroy(prefabComponent)
    end

    local fight = CS.XFight.Instance
    if fight then
        fight:Resume()

        if self._IsWin then
            fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonMiniGameWin, CS.XOperationClickType.KeyDown)
            fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonMiniGameWin, CS.XOperationClickType.KeyUp)
        elseif self._IsGameOver then
            fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonMiniGameFail, CS.XOperationClickType.KeyDown)
            fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonMiniGameFail, CS.XOperationClickType.KeyUp)
        end
    end

    CS.XGameEventManager.Instance:RemoveEvent(XEventId.EVENT_ON_FIGHT_EXIT, self._OnFightExit)
end

function XUiPacMan:Update()
    if self._IsPlayingRecord then
        self:Close()
        XLog.Warning("[XUiPacMan] 回放中，跳过吃豆人小游戏")
        return
    end

    if not self._IsGameOver then
        self._Time = self._Time - CS.UnityEngine.Time.deltaTime
        if self._Time <= 0 then
            self._Time = 0
            self._IsGameOver = true
            self:CallGameOver()
        end
        self.TxtTime.text = XUiHelper.GetTime(self._Time, XUiHelper.TimeFormatType.MINUTE_SECOND)
    end

    if self._Game then
        -- 剧情
        if self._Story then
            if self._StoryIndex > #self._Story then
                XLog.Debug("[XUiPacMan] 剧情播放完毕")
                self:EndStory()
                return
            end
            return
        end

        -- 检测gameOver
        if not self._IsWin then
            local progress = self._Game.Progress
            if progress >= 100 then
                -- 等待播放剧情中
                if self._Game:IsAllStoryPlayed() then
                    self._IsWin = true
                    self:Win()
                end
                return
            end
        end

        if not self._IsGameOver then
            local health = self._Game.PacMan.Lives
            if health == 0 then
                self._IsGameOver = true
                self:CallGameOver()
                return
            end
        end
    end
end

function XUiPacMan:PlayStory(storyId)
    local story = self._Control:GetStory(storyId)
    if not next(story) then
        XLog.Error("[XUiPacMan] 剧情没有对应的配置？：" .. tostring(storyId))
        return false
    end

    if self._PlayedStory[storyId] then
        return false
    end

    -- 暂停游戏
    self._Game.enabled = false
    self._PlayedStory[storyId] = true
    self._StoryIndex = 1
    self._StoryOptionIndex = 1
    self._Story = story
    self.PanelTalk.gameObject:SetActiveEx(true)
    self:UpdateStory()

    return true
end

function XUiPacMan:UpdateStory()
    if not self._Story then
        self:EndStory()
        return
    end
    local story = self._Story[self._StoryIndex]
    if not story then
        self:EndStory()
        return
    end
    self.ImgHeadIcon:SetSprite(story.Image)
    self.TxtTalkName.text = story.TxtTalkName
    self.TxtTalk.text = story.TxtTalk

    local answer = {}
    for i = 1, #story.TxtAnswer do
        ---@class XUiPacManAnswerOptionData
        local data = {
            Text = story.TxtAnswer[i],
            Index = i,
            Selected = i == self._StoryOptionIndex,
        }
        answer[#answer + 1] = data
    end
    self._DataAnswerOption = answer
    self:UpdateAnswer()
end

function XUiPacMan:Win()
    self._Game.enabled = false
    XLog.Debug("[XUiPacMan] 游戏胜利, 等待后关闭")

    local timer = XScheduleManager.ScheduleOnce(function()
        XLuaUiManager.Close("UiPacMan")
    end, 1500)
    self:_AddTimerId(timer)
end

function XUiPacMan:CallGameOver()
    self._Game.enabled = false
    self.GameOver.gameObject:SetActiveEx(true)
    XLog.Debug("[XUiPacMan] 游戏失败, 等待后关闭")

    local timer = XScheduleManager.ScheduleOnce(function()
        XLuaUiManager.Close("UiPacMan")
    end, 2500)
    self:_AddTimerId(timer)
end

function XUiPacMan:StoryNext()
    self._StoryIndex = self._StoryIndex + 1
    self:UpdateStory()
end

function XUiPacMan:EndStory()
    self._Game.enabled = true
    self._Story = false
    self._StoryIndex = 0
    self._StoryOptionIndex = 1
    self._DataAnswerOption = false
    self.PanelTalk.gameObject:SetActiveEx(false)
end

function XUiPacMan:SetStoryOptionIndex(value)
    if not self._DataAnswerOption then
        XLog.Error("[XUiPacMan] 剧情选项不存在，有问题")
        return
    end
    value = XMath.Clamp(value, 1, #self._DataAnswerOption)
    if value == self._StoryOptionIndex then
        return
    end
    local lastOption = self._DataAnswerOption[self._StoryOptionIndex]
    if lastOption then
        lastOption.Selected = false
    end
    self._StoryOptionIndex = value
    local currentOption = self._DataAnswerOption[value]
    if currentOption then
        currentOption.Selected = true
    end
    self:UpdateAnswer()
end

function XUiPacMan:UpdateAnswer()
    XTool.UpdateDynamicItem(self._AnswerOption, self._DataAnswerOption, self.Answer, XUiPacManAnswerOption, self)
end

function XUiPacMan:UpdateProgress()
    local progress = self._Game.Progress
    progress = math.min(progress, 100)
    self.TxtFraction.text = tostring(progress) .. "%"
end

function XUiPacMan:OnClickUp()
    if self._Story then
        self:SetStoryOptionIndex(self._StoryOptionIndex - 1)
        return
    end
    self._Game.PacMan:MoveUp()
end

function XUiPacMan:OnClickDown()
    if self._Story then
        self:SetStoryOptionIndex(self._StoryOptionIndex + 1)
        return
    end
    self._Game.PacMan:MoveDown()
end

function XUiPacMan:OnClickLeft()
    self._Game.PacMan:MoveLeft()
end

function XUiPacMan:OnClickRight()
    self._Game.PacMan:MoveRight()
end

function XUiPacMan:OnClickFire()
    if self._Story then
        self:StoryNext()
        return
    end
    self._Game.PacMan:Fire()
end

return XUiPacMan
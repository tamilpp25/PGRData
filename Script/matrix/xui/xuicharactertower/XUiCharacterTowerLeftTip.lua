---@class XUiCharacterTowerLeftTip : XLuaUi
local XUiCharacterTowerLeftTip = XLuaUiManager.Register(XLuaUi, "UiCharacterTowerLeftTip")

function XUiCharacterTowerLeftTip:OnAwake()
    self:RegisterUiEvents()
end

function XUiCharacterTowerLeftTip:OnStart(chapterId, conditionId, isCloseLastUi)
    self.ChapterId = chapterId
    self.IsCloseLastUi = isCloseLastUi
    ---@type XCharacterTowerChapter
    self.ChapterViewModel = XDataCenter.CharacterTowerManager.GetCharacterTowerChapter(chapterId)
    self.CharacterId = self.ChapterViewModel:GetChapterCharacterId()
    -- 名字
    self.TxtTitle.text = XCharacterConfigs.GetCharacterName(self.CharacterId)
    -- 任务描述
    self.TxtContent.text = XConditionManager.GetConditionDescById(conditionId)
    
    -- 延迟时间
    local delayTime = XUiHelper.GetClientConfig("CharacterTowerLeftTipDelayTime", XUiHelper.ClientConfigType.Int)
    self.Timer = XScheduleManager.ScheduleOnce(function()
        self:Close()
    end, XScheduleManager.SECOND * delayTime)
end

function XUiCharacterTowerLeftTip:OnDestroy()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiCharacterTowerLeftTip:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnAdvance, self.OnBtnAdvanceClick)
end

function XUiCharacterTowerLeftTip:OnBtnAdvanceClick()
    if XTool.IsNumberValid(self.ChapterId) then
        -- 获取角色塔Id
        local id = XFubenCharacterTowerConfigs.GetIdByChapterId(self.ChapterId)
        if not XTool.IsNumberValid(id) then
            return
        end
        -- 是否解锁
        local isUnlock, tips = XDataCenter.CharacterTowerManager.IsUnlock(id)
        if not isUnlock then
            XUiManager.TipError(tips)
            return
        end
        -- 检查章节条件
        local ret, desc = self.ChapterViewModel:CheckChapterCondition()
        if not ret then
            XUiManager.TipError(desc)
            return
        end
        local relationGroupId = self.ChapterViewModel:GetChapterRelationGroupId()
        if self.IsCloseLastUi then
            XLuaUiManager.PopThenOpen("UiCharacterTowerFetter", relationGroupId, self.CharacterId)
        else
            XLuaUiManager.Open("UiCharacterTowerFetter", relationGroupId, self.CharacterId)
        end
        self:Close()
    end
end

return XUiCharacterTowerLeftTip
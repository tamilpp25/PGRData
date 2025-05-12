---@class XUiPanelGame2048Score: XUiNode
---@field _Control XGame2048Control
---@field _GameControl XGame2048GameControl
---@field _StarGridPool XPool
---@field TxtAdd UnityEngine.UI.Text
local XUiPanelGame2048Score = XClass(XUiNode, 'XUiPanelGame2048Score')
local XUiGridGame2048ScoreStar = require('XUi/XUiGame2048/UiGame2048Game/PanelScore/XUiGridGame2048ScoreStar')

function XUiPanelGame2048Score:OnStart()
    self._GameControl = self._Control:GetGameControl()
    self._StarGrids = {}
    self:InitGridStars()

    self._GameControl:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_REFRESH_DATA, self.RefreshStar, self)

    -- 初始化背景样式
    self:InitTheme()
    self:ResetShow()
    
    self._ScoreAddsFadeInTime = self._Control:GetClientConfigNum('ScoreAddsShowTweenTime', 1)
    self._ScoreAddsStayTime = self._Control:GetClientConfigNum('ScoreAddsShowTweenTime', 2)
    self._ScoreAddsFadeOutTime = self._Control:GetClientConfigNum('ScoreAddsShowTweenTime', 3)

    self._ScoreAddsBeginScale = self._Control:GetClientConfigNum('ScoreAddsShowTweenScale', 1)
    self._ScoreAddsCenterScale = self._Control:GetClientConfigNum('ScoreAddsShowTweenScale', 2)
    self._ScoreAddsEndScale = self._Control:GetClientConfigNum('ScoreAddsShowTweenScale', 3)

    self._TotalScoreScorllTweenDelayTime = self._Control:GetClientConfigNum('TotalScoreScorllTweenTime', 1)
    self._TotalScoreScorllTweenTime = self._Control:GetClientConfigNum('TotalScoreScorllTweenTime', 2)
end

function XUiPanelGame2048Score:OnDisable()
    self:UndoScoreAddEffect()
end

function XUiPanelGame2048Score:ResetShow()
    -- 清空文本显示，防止隔帧刷新导致的穿帮
    self.TxtNumScore.text = ''
    self:InitScoreProcess()
end

function XUiPanelGame2048Score:InitScore()
    self:InitScoreProcess()
    
    self._StageId = self._Control:GetCurStageId()
    
    local curScore = self._GameControl.TurnControl:GetCurScore()
    self.TxtNumScore.text = curScore
    
    -- 初始化背景样式
    self:InitTheme()
    
    -- 刷新星级目标
    if not XTool.IsTableEmpty(self._StarGrids) then
        for i, v in pairs(self._StarGrids) do
            v:Close()
        end
    end
    
    local scores = self._Control:GetStageScoreList(self._StageId)
    self._CurStarCount = 0
    if not XTool.IsTableEmpty(scores) then
        for i, v in pairs(scores) do
            local grid = self._StarGrids[i]

            if grid then
                grid:Open()
                grid:SetIsAchieve(curScore >= v)
            end

            if curScore >= v then
                self._CurStarCount = self._CurStarCount + 1
            end
        end
    end
    
    
    -- 初始化进度
    self:FindMaxScore()
    self:RefreshScoreProcess()

    local percent = 0

    -- 只有大于等于1星才显示
    if self._CurStarCount >= 1 then
        percent = self._MaxScore == 0 and 1 or ((curScore - self._CurPeriodBeginScore) / self._CurPeriodMaxScore)
    end
    
    self._CurBar.fillAmount = percent
    self._LastScore = curScore
    self._CurBarEffect.gameObject:SetActiveEx(false)
    
    self.Parent:SetGiveUpBtnShow(self._CurStarCount >= XTool.GetTableCount(scores))
end

function XUiPanelGame2048Score:InitTheme()
    local curChapterId = self._Control:GetCurChapterId()
    local fixedScoreColor = string.gsub(self._Control:GetChapterScoreNumberColorById(curChapterId), '#', '')
    self.TxtNumScore.color = XUiHelper.Hexcolor2Color(fixedScoreColor)

    local fixedLabelColor = string.gsub(self._Control:GetChapterScoreLabelColorById(curChapterId), '#', '')
    self.TxtScoreLabel.color = XUiHelper.Hexcolor2Color(fixedLabelColor)
end

function XUiPanelGame2048Score:RefreshStar()
    local scores = self._Control:GetStageScoreList(self._StageId)
    local curScore = self._GameControl.TurnControl:GetCurScore()
    local starCount = 0
    -- 刷新星星点亮情况
    if not XTool.IsTableEmpty(scores) then
        for i, v in pairs(scores) do
            if self._StarGrids[i] then
                self._StarGrids[i]:SetIsAchieve(curScore >= v)
                starCount = curScore >= v and starCount + 1 or starCount
            end
        end
    end

    self._CurStarCount = starCount
    
    self:RefreshScoreProcess()
    self:FindMaxScore()
    
    local percent = 0
    
    -- 只有大于等于1星才显示
    if self._CurStarCount >= 1 then
        percent = self._MaxScore == 0 and 1 or ((curScore - self._CurPeriodBeginScore) / self._CurPeriodMaxScore)
    end

    if percent > 1 then
        percent = 1
    end
    
    self._CurBar.fillAmount = percent
    
    --刷新进度条高亮位置
    if curScore ~= self._LastScore then
        self._CurBarEffect.transform.anchoredPosition = Vector2(self._CurBar.transform.rect.width * percent, self._CurBarEffect.transform.anchoredPosition.y)
    end
    
    -- 计算分数增量
    local scoreAddsNum = curScore - (self._LastScore or 0)

    if scoreAddsNum ~= 0 then
        self:DoScoreAddEffect(scoreAddsNum)
    else
        self:UndoScoreAddEffect()
        self.TxtNumScore.text = curScore
    end

    self._LastScore = curScore

    self.Parent:SetGiveUpBtnShow(self._CurStarCount >= XTool.GetTableCount(scores))
end

--region 动画特效
function XUiPanelGame2048Score:DoScoreAddEffect(scoreAddsNum)
    self:UndoScoreAddEffect(true)
    
    -- 滚动显示
    local originNum = self._LastScore
    local curNum = string.IsNumeric(self.TxtNumScore.text) and tonumber(self.TxtNumScore.text) or originNum
    local totalScoreScrollSequence = CS.DG.Tweening.DOTween.Sequence()
    
    -- 延迟播放
    if XTool.IsNumberValid(self._TotalScoreScorllTweenDelayTime) then
        totalScoreScrollSequence:AppendInterval(self._TotalScoreScorllTweenDelayTime)
    end

    totalScoreScrollSequence:AppendCallback(function()
        if self.FxScore then
            self.FxScore.gameObject:SetActiveEx(true)
        end
    end)
    
    totalScoreScrollSequence:Append(CS.DG.Tweening.DOTween.To(function()
        return curNum
    end, function(newNum)
        if self and self.TxtNumScore then
            self.TxtNumScore.text = XMath.ToMinInt(newNum)
        end
    end, originNum + scoreAddsNum, self._TotalScoreScorllTweenTime))

    totalScoreScrollSequence:AppendCallback(function()
        if self.FxScore then
            self.FxScore.gameObject:SetActiveEx(false)
        end
    end)
    totalScoreScrollSequence:Play()
    
    --进度条特效
    local scrollFlashSequence = CS.DG.Tweening.DOTween.Sequence()
    self._CurBarEffect.gameObject:SetActiveEx(true)
    scrollFlashSequence:Append(self._CurBarEffect:DOFade(0, 0))
    scrollFlashSequence:Append(self._CurBarEffect:DOFade(1, self._ScoreAddsFadeInTime))
    scrollFlashSequence:Append(self._CurBarEffect:DOFade(0, self._ScoreAddsFadeOutTime))
    scrollFlashSequence:Play()
    
    self._TotalScoreScrollSequence = totalScoreScrollSequence
    self._ScrollFlashSequence = scrollFlashSequence
end

---@param isContinue boolean 表示是否是会继续滚动，会的话就不设置最终值
function XUiPanelGame2048Score:UndoScoreAddEffect(isContinue)
    if self._TotalScoreScrollSequence then
        if self._TotalScoreScrollSequence:IsActive() then
            self._TotalScoreScrollSequence:Kill(true)
            if not isContinue then
                self.TxtNumScore.text = self._GameControl.TurnControl:GetCurScore()
            end

            if self.FxScore then
                self.FxScore.gameObject:SetActiveEx(false)
            end
        end
        self._TotalScoreScrollSequence = nil
    end
    
    if self._ScrollFlashSequence then
        if self._ScrollFlashSequence:IsActive() then
            self._ScrollFlashSequence:Kill(true)
        end
        self._ScrollFlashSequence = nil
        self._CurBarEffect.gameObject:SetActiveEx(false)
    end
end
--endregion

function XUiPanelGame2048Score:InitScoreProcess()
    self.ImgBar1.fillAmount = 0
    self.ImgBar2.fillAmount = 0
    self.ImgBarEffect1.gameObject:SetActiveEx(false)
    self.ImgBarEffect2.gameObject:SetActiveEx(false)

    if self.FxScore then
        self.FxScore.gameObject:SetActiveEx(false)
    end
end

function XUiPanelGame2048Score:RefreshScoreProcess()
    if self._CurStarCount <= 1 then
        -- 小于等于1星时处理第一个进度条
        self.ImgBar2.fillAmount = 0
        self.ImgBarEffect2.gameObject:SetActiveEx(false)

        self._CurBarEffect = self.ImgBarEffect1
        self._CurBar = self.ImgBar1
    elseif self._CurStarCount >= 2 then
        -- 大于2星时处理第二个进度条
        self.ImgBar1.fillAmount = 1
        self.ImgBarEffect1.gameObject:SetActiveEx(false)

        self._CurBarEffect = self.ImgBarEffect2
        self._CurBar = self.ImgBar2
    end
end

function XUiPanelGame2048Score:FindMaxScore()
    local scores = self._Control:GetStageScoreList(self._StageId)
    local curStarScore = scores[self._CurStarCount] or 0
    local nextStarScore = scores[self._CurStarCount + 1] or 0

    -- 当前阶段的实际值
    self._MaxScore = math.max(0, nextStarScore, curStarScore)
    
    if XTool.IsNumberValid(nextStarScore) then
        -- 当前阶段的阶段内增量
        self._CurPeriodMaxScore = nextStarScore - curStarScore
        -- 当前阶段的起始值
        self._CurPeriodBeginScore = curStarScore
    else
        self._CurPeriodMaxScore = curStarScore
        self._CurPeriodBeginScore = 0
    end
end

function XUiPanelGame2048Score:InitGridStars()
    for i = 1, 10 do
        local go = self['GridStar'..i]

        if go then
            local grid = XUiGridGame2048ScoreStar.New(go, self)
            grid:Close()
            table.insert(self._StarGrids, grid)
        else
            break
        end
    end
end

return XUiPanelGame2048Score
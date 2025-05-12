---@class XUiPanelKotodamaMainContinue
---@field _Control XKotodamaActivityControl
local XUiPanelKotodamaMainContinue = XClass(XUiNode, 'XUiPanelKotodamaMainContinue')
local XUiGridKotodamaStage = require('XUi/XUiKotodamaActivity/UiKotodamaMain/XUiGridKotodamaStage')
local XUiGridKotodamaWord = require('XUi/XUiKotodamaActivity/UiKotodamaMain/XUiGridKotodamaWord')
local XUiGridKotodamaBlock = require('XUi/XUiKotodamaActivity/UiKotodamaMain/XUiGridKotodamaBlock')

local BtnGroupIndex = {
    BtnSpeech = 1,
    BtnArtifact = 2,
}

function XUiPanelKotodamaMainContinue:OnStart()
    self.RImgPulao.gameObject:SetActiveEx(true)
    self.RectTransform = self.Transform:GetComponent("RectTransform")
    self.BtnTask.CallBack = function()
        XLuaUiManager.Open('UiKotodamaTask')
    end
    self.BtnSpeech.CallBack = handler(self, self.OnBtnSpeechClickEvent)
    self.BtnMemory.CallBack = function()
        XLuaUiManager.Open('UiKotodamaMemory')
    end
    self.GridChapter1.gameObject:SetActiveEx(false)
    --初始化拖拽事件
    self.PanelClickEventHandler = self.PanelClick.gameObject:AddComponent(typeof(CS.XInteractEventHandler))
    self.PanelClick.gameObject:AddComponent(typeof(CS.XPointerDownHandler))
    self.PanelClickEventHandler:AddListener(CS.XInteractType.PointerDown, function(eventData)
        self:ScrollRectRollBack()
    end)
    self.PanelChapter.onValueChanged:AddListener(handler(self, self.OnChapterListScrollEvent))
    self.StoryUi = {}
    XTool.InitUiObjectByUi(self.StoryUi, self.PanelStory)
    self.StoryUi.BtnResetting.CallBack = handler(self, self.ResetWordSelection)
    self.StoryUi.BtnTongBlack.CallBack = handler(self, self.OnBtnTongBlackClickEvent)
    if self.ArtifactBtn then
        self.ArtifactBtn.CallBack = handler(self, self.OnArtifactBtnClickEvent)
    end
    self.StoryUi.TxtStory1.ButtonListener = handler(self, self.OnSentenceClickEvent)
    self.WordsCtrl = {}
    self.BlockCtrl = {}
    self.StoryUi.GridOption.gameObject:SetActiveEx(false)
    self.StoryUi.GridTxt.gameObject:SetActiveEx(false)
    self:InitStageList()

    self.TaskRedId = self:AddRedPointEvent(self.BtnTask, self.OnTaskRedPointEvent, self, { XRedPointConditions.Types.CONDITION_KOTODAMA_REWARD })
    self.SpeechRedId = self:AddRedPointEvent(self.BtnSpeech, self.OnBtnSpeechRedPointEvent, self, { XRedPointConditions.Types.CONDITION_KOTODAMA_NEW_SPEECH })
    --回忆无蓝点
    self.BtnMemory:ShowReddot(false)

    XEventManager.AddEventListener(XEventId.EVENT_KOTODAMA_AUTO_NEXT_STAGE, self.AutoNextStageEvent, self)
    --关卡滑动窗口的边界值
    self.ScrollLimitY = math.abs(self.ChapterContent.sizeDelta.y / 2 - self.PanelChapter.viewport.rect.height / 2)

    self:StartTimer()
end

function XUiPanelKotodamaMainContinue:OnEnable()
    XRedPointManager.Check(self.TaskRedId)
    XRedPointManager.Check(self.SpeechRedId)

    --新进入时需要等待选关请求，因此蒲牢图片更新通过回调执行
    self:FocusCurStageUI(function()
        self:RefreshPulaoAvatarPosition(self._Control:GetCurStageId(), self._Control:GetCurStageId(), true)
        --检测一次入口
        self._Control:CheckCurStageSpellValid()
        self:RefreshBtnTongBlackState()
        self:RefreshWordBlockSelection(true)
    end)
    
    --监听引导广播
    XEventManager.AddEventListener(XEventId.EVENT_KOTODAMA_GUIDEDISPATCH_DELETESENTENCE, self.OnGuideDeleteSentenceEvent, self)
end

function XUiPanelKotodamaMainContinue:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_KOTODAMA_GUIDEDISPATCH_DELETESENTENCE, self.OnGuideDeleteSentenceEvent, self)
end

function XUiPanelKotodamaMainContinue:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_KOTODAMA_AUTO_NEXT_STAGE, self.AutoNextStageEvent, self)
    XMVCA.XKotodamaActivity:CheckAndSubmitReset()
    self:StopTimer()
end
--region 初始化
function XUiPanelKotodamaMainContinue:InitStageList()
    if XTool.IsTableEmpty(self.StageList) then
        self.StageList = {}
        self.StageMap = {}
        --UI初始化
        local allcfg = XMVCA.XKotodamaActivity:GetAllKotodamaStageCfg()

        for i, v in pairs(allcfg) do
            if self['Chapter' .. v.Order] then
                local cloneObj = CS.UnityEngine.GameObject.Instantiate(self.GridChapter1, self['Chapter' .. v.Order].transform)
                cloneObj.gameObject:SetActiveEx(true)
                local rectTrans = cloneObj:GetComponent(typeof(CS.UnityEngine.RectTransform))
                rectTrans.anchoredPosition = Vector2(0, 0)
                local ctrl = XUiGridKotodamaStage.New(cloneObj, self, v.Id)
                self.StageList[v.Order] = ctrl
                self.StageMap[v.Id] = v.Order
            end
        end
    end
end

--每次换关卡都会被执行
function XUiPanelKotodamaMainContinue:InitWords(key, data)
    if not self.WordsCtrl[key] then
        local clone = CS.UnityEngine.GameObject.Instantiate(self.StoryUi.GridOption, self.StoryUi.PanelOption)
        clone.gameObject:SetActiveEx(false)
        clone.gameObject.name = 'GridOption'..tostring(key)
        self.WordsCtrl[key] = XUiGridKotodamaWord.New(clone, self)
    end
    self.WordsCtrl[key]:Open()
    self.WordsCtrl[key]:Refresh(data)
end

--每次换关卡都执行
function XUiPanelKotodamaMainContinue:InitWordBlock(index, cfg, patternIndex, patternId, wordIndex, wordId, useDefault)
    if not self.BlockCtrl[index] then
        local clone = CS.UnityEngine.GameObject.Instantiate(self.StoryUi.GridTxt, self.StoryUi.GridTxt.transform.parent)
        clone.gameObject:SetActiveEx(false)
        clone.gameObject.name = 'GridTxt'..tostring(index)
        self.BlockCtrl[index] = XUiGridKotodamaBlock.New(clone, self, index)
    end
    self.BlockCtrl[index]:Open()
    self.BlockCtrl[index]:Refresh(cfg, patternIndex, patternId, wordIndex, wordId, useDefault)
end
--endregion

--region 界面更新

function XUiPanelKotodamaMainContinue:RefreshLeftTime()
    local timeId = self._Control:GetActivityTimeId()
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local leftTime = endTime - XTime.GetServerNowTimestamp()
    leftTime = leftTime > 0 and leftTime or 0
    if self.TxtTime and self.TxtTime.gameObject.activeInHierarchy then
        self.TxtTime.text = XUiHelper.FormatText(self._Control:GetClientConfigStringByKey('LeftTime'), XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
    end
    if leftTime <= 0 then
        self:Close()
        XLuaUiManager.RunMain()
    end
end

function XUiPanelKotodamaMainContinue:RefreshStageList()
    --刷新
    for i, v in pairs(self.StageList) do
        v:Refresh()
    end
end

--关卡文本、填词交互部分的内容
function XUiPanelKotodamaMainContinue:RefreshWordPanel(useDefault)
    local curStage = self._Control:GetCurStageId()
    if XTool.IsNumberValid(curStage) then
        local stageCfg = self._Control:GetKotodamaStageCfgById(curStage)
        --刷新基本内容
        self:RefreshBaseContent(curStage)
        --刷新句式
        self:RefreshSentencePattern(stageCfg, useDefault)
        --更新布局
        XScheduleManager.ScheduleNextFrame(function()
            self.StoryUi.TxtStory1.gameObject:SetActiveEx(true)
            CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelDetailLayout)
            CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelStoryLayout)
        end)
        --显示词
        self:RefreshWords()
        --刷新按钮状态
        self:RefreshBtnTongBlackState()
        
        self:RefreshArtifact()
    end
end

function XUiPanelKotodamaMainContinue:RefreshBaseContent(curStage)
    local stageCfg = self._Control:GetKotodamaStageCfgById(curStage)
    self.StoryUi.TxtStory1.gameObject:SetActiveEx(false)
    self.StoryUi.TxtStory2.gameObject:SetActiveEx(false)
    --显示标题
    self.StoryUi.TxtRound.text = XUiHelper.FormatText(self._Control:GetClientConfigStringByKey('StageTitleContent'), stageCfg.StageTitle, stageCfg.StageTitleEx)
end

function XUiPanelKotodamaMainContinue:RefreshSentencePattern(stageCfg, useDefault)
    for i, v in pairs(self.BlockCtrl) do
        v:Close()
    end

    local index = 1
    local content = {}
    
    -- 关卡开头文本需检查是否有插值
    if not XTool.IsTableEmpty(stageCfg.SentenceIds) then
        local params = {}
        for i, v in ipairs(stageCfg.SentenceIds) do
            local sentenceCfg = self._Control:GetSentenceCfgById(v)
            if sentenceCfg then
                local sentenceStr = self._Control:GetSentenceStrBySentenceId(sentenceCfg.Id)
                --关卡详细页的插值句子需要增加点击包围盒
                if sentenceCfg.IsEnableBan then
                    sentenceStr = XUiHelper.FormatText(self._Control:GetClientConfigStringByKey('ClickBoxFormat'), sentenceCfg.Id, sentenceStr)
                end
                --插入前还需检查下是否需要划线富文本
                if self._Control:CheckSentenceIsDeleteInCurStage(sentenceCfg.Id) then
                    sentenceStr = XUiHelper.FormatText(self._Control:GetClientConfigStringByKey('SentenceDeletedFormat'), sentenceStr)
                end
                table.insert(params, sentenceStr)
            end
        end
        table.insert(content, XUiHelper.FormatText(stageCfg.StageContent, table.unpack(params)))
    else
        table.insert(content, stageCfg.StageContent)
    end
    
    table.insert(content, '\n')
    local placeholder = self._Control:GetClientConfigStringByKey('BlockPlaceholder')

    for patternIndex, patternId in pairs(stageCfg.SentencePatterns) do
        local sentenceCfg = self._Control:GetSentencePatternCfgById(patternId)
        local insertTab = {}
        for wordIndex = 1, sentenceCfg.BlockNum do
            local id = 100000 + patternId * 100 + wordIndex
            local cfg = self._Control:GetWordBlockCfgById(id)

            --获取填词数据，如果有则显示词，无则隐藏文本
            local wordData = self._Control:GetSpellData(patternIndex, wordIndex)
            if wordData then
                self:InitWordBlock(index, cfg, patternIndex, patternId, wordIndex, wordData, useDefault)
            else
                self:InitWordBlock(index, cfg, patternIndex, patternId, wordIndex, nil, useDefault)
            end
            index = index + 1
            table.insert(insertTab, string.rep(placeholder, cfg.BlockWidth))
        end

        table.insert(content, XUiHelper.FormatText(sentenceCfg.Content, table.unpack(insertTab)))
        table.insert(content, '\n')
    end
    --去掉最后一个换行
    if content[#content] == '\n' then
        content[#content] = nil
    end
    --显示句式
    self.StoryUi.TxtStory1.text = XUiHelper.ReplaceTextNewLine(table.concat(content))
    --显示衍生文本
    if self._Control:CheckCurStageSpellValid() then
        self.StoryUi.TxtStory2.gameObject:SetActiveEx(true)
        self.StoryUi.TxtStory2.text = XUiHelper.ReplaceTextNewLine(self._Control:GetCurStageSentenceExpandContent())
    end
end

function XUiPanelKotodamaMainContinue:RefreshWords()
    local curStage = self._Control:GetCurStageId()
    --先隐藏所有
    for i, v in pairs(self.WordsCtrl) do
        v:Close()
    end
    --获取所有的词配置
    if XTool.IsNumberValid(curStage) then
        local stageCfg = self._Control:GetKotodamaStageCfgById(curStage)
        local wordIds = {}
        for i, v in pairs(stageCfg.SentencePatterns) do
            local sentenceCfg = self._Control:GetSentencePatternCfgById(v)
            if table.contains(wordIds, sentenceCfg.PhraseId) == false then
                table.insert(wordIds, sentenceCfg.PhraseId)
            end
        end
        local allWordsCfg = self._Control:GetWordGroupConfigByGroupId(wordIds)
        --生成所有词的控制器
        for i, v in ipairs(allWordsCfg) do
            --只显示那些没有被使用的
            if not self._Control:CheckSpellIsUsingInCurStage(v.Id) then
                self:InitWords(i, v)
            end
        end
    end

end

function XUiPanelKotodamaMainContinue:RefreshPulaoAvatarPosition(lastStageId, curStageId, forceJump, cb)
    --判断关卡切换情况
    local jumpStage = self._Control:IsJumpStage(lastStageId, curStageId)
    local ctrl = self.StageList[self.StageMap[curStageId]]
    local lastCtrl = self.StageList[self.StageMap[lastStageId]]
    if lastCtrl then
        lastCtrl:UnSelect()
    end
    self:UnSelectAllRecordStage()
    if jumpStage or forceJump then
        --闪现
        self.RImgPulao.transform.localPosition = ctrl:GetPulaoStandingPosition()
        ctrl:Select()
        if cb then
            cb()
        end
    else
        local moveCb = function()
            ctrl:Select()
            if cb then
                cb()
            end
        end
        --插值平移
        XUiHelper.DoMove(self.RImgPulao.transform, ctrl:GetPulaoStandingPosition(), CS.XGame.ClientConfig:GetFloat('KotodamaActivityStageMoveDuration'), XUiHelper.EaseType.Sin, moveCb)
    end
end

--每次进入关卡或执行填词操作后会刷新一次
function XUiPanelKotodamaMainContinue:RefreshWordBlockSelection(isEnterStage, overrideBeginIndex)
    local curIndex = (self.CurBlockGrid and not isEnterStage) and self.CurBlockGrid:GetIndex() or 1
    if XTool.IsNumberValid(overrideBeginIndex) then
        curIndex = overrideBeginIndex
    end
    local count = #self.BlockCtrl
    local isFindEmptyBlock = false
    for i = 1, count do
        --自增后对溢出作循环处理
        curIndex = (curIndex - 1) % count + 1

        if self.BlockCtrl[curIndex]:IsNodeShow() and self.BlockCtrl[curIndex]:IsFillWord() == false then
            self:SelectWordBlockByIndex(curIndex)
            isFindEmptyBlock = true
            break
        end

        curIndex = curIndex + 1
    end

    if isEnterStage and not isFindEmptyBlock then
        --如果没有选中时，默认选中第一个【无论有没填词】
        self:SelectWordBlockByIndex(1)
    end
end

function XUiPanelKotodamaMainContinue:RefreshBtnTongBlackState()
    self.StoryUi.BtnTongBlack:SetButtonState(self._Control:IsBtnStartValid() and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
end

--刷新神器的显示
function XUiPanelKotodamaMainContinue:RefreshArtifact()
    if self._Control:CheckHasArtifact() and self._Control:CheckHasArtifactCanUsedInCurStage() then
        self.ArtifactBtn.gameObject:SetActiveEx(true)
        self.ArtifactBtn:SetNameByGroup(0, XUiHelper.FormatText(self._Control:GetClientConfigStringByKey('ArtifactBtnDescFormat'), self._Control:GetArtifactFullDesc()))
    else
        self.ArtifactBtn.gameObject:SetActiveEx(false)
    end
end
--endregion

--region 事件处理
function XUiPanelKotodamaMainContinue:SelectBlockGrid(grid)
    if self.CurBlockGrid then
        self.CurBlockGrid:UnSelect()
        self.CurBlockGrid = nil
    end
    self.CurBlockGrid = grid
    self.CurBlockGrid:Select()
end

function XUiPanelKotodamaMainContinue:SelectWordBlockByIndex(index)
    if self.BlockCtrl[index] then
        self:SelectBlockGrid(self.BlockCtrl[index])
    end
end

function XUiPanelKotodamaMainContinue:ResetWordSelection()
    self._Control:ResetWordSelectionLocal()
    self:RefreshWordPanel(true)
    self:RefreshWordBlockSelection(false, 1)
end

function XUiPanelKotodamaMainContinue:FocusCurStageUI(cb)
    local curStage = self._Control:GetCurStageId()
    if not XTool.IsNumberValid(curStage) then
        XMVCA.XKotodamaActivity:KotodamaSpellSentenceRequest(function()
            XMVCA.XKotodamaActivity:SetStageNewState(self._Control:GetFirstKotodamaStageCfg().Id, XEnumConst.KotodamaActivity.LocalNewState.Old)
            self:FocusCurStageUI(cb)
        end, self._Control:GetFirstKotodamaStageCfg().Id, {}, 0)
    else
        local ctrl = self.StageList[self.StageMap[curStage]]
        if ctrl then
            local focusY = CS.XGame.ClientConfig:GetFloat('KotodamaActivityStageFocusY')
            local tarPosY = focusY - ctrl.Transform.parent.localPosition.y
            self.PanelChapter.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
            self._Control:TryToCheckBlockErrorWhileNoData()
            self:PlayScrollViewMoveBack(tarPosY, false)
            self:RefreshStageList()
            self:RefreshWordPanel(true)
        end
        if cb then
            cb()
        end
    end
end

function XUiPanelKotodamaMainContinue:ScrollRectRollBack()
    self.PanelChapter.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
end

function XUiPanelKotodamaMainContinue:PlayScrollViewMoveBack(tarPosY, isElastic)
    local moveDuration = CS.XGame.ClientConfig:GetFloat('KotodamaActivityStageMoveDuration')
    local tarPos = self.ChapterContent.localPosition
    tarPos.y = tarPosY
    --边界修正:第一关和最后一关不再强制居中
    if tarPos.y > self.ScrollLimitY then
        tarPos.y = self.ScrollLimitY
    elseif tarPos.y < -self.ScrollLimitY then
        tarPos.y = -self.ScrollLimitY
    end

    XLuaUiManager.SetMask(true)
    self.LockAutoFixedScrollMoveType = true
    XUiHelper.DoMove(self.ChapterContent, tarPos, moveDuration, XUiHelper.EaseType.Sin, function()
        if isElastic then
            self.PanelChapter.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        else
            self.PanelChapter.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        end
        XLuaUiManager.SetMask(false)
        XScheduleManager.ScheduleNextFrame(function()
            self.LockAutoFixedScrollMoveType = false
        end)
    end)
end

function XUiPanelKotodamaMainContinue:OnTaskRedPointEvent(count)
    self.BtnTask:ShowReddot(count >= 0)
end

function XUiPanelKotodamaMainContinue:OnBtnSpeechRedPointEvent(count)
    self.BtnSpeech:ShowReddot(count >= 0)
end

function XUiPanelKotodamaMainContinue:OnBtnSpeechClickEvent()
    local collects = XMVCA.XKotodamaActivity:GetAllUnLockCollectSentenceIds()
    XLuaUiManager.Open('UiKotodamaSpeech', function()
        XRedPointManager.Check(self.SpeechRedId)
    end)
end

function XUiPanelKotodamaMainContinue:AutoNextStageEvent(lastStageId)
    self:RefreshPulaoAvatarPosition(lastStageId, self._Control:GetCurStageId(), false, function()
        XDataCenter.GuideManager.CheckGuideOpen()
    end)
    self:FocusCurStageUI()
    self:RefreshWordBlockSelection()
    self.Parent:PlayAnimation('QieHuan')
    self:RefreshBtnTongBlackState()
end

function XUiPanelKotodamaMainContinue:OnChapterListScrollEvent(vec2)
    if not self.LockAutoFixedScrollMoveType then
        --只要滚动了，就复原scroll模式
        self.PanelChapter.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
    end
end

--点击进入关卡的事件处理
function XUiPanelKotodamaMainContinue:OnBtnTongBlackClickEvent()
    local complete, hasEmpty, emptyPatternIds = self._Control:CheckCurStageSpellComplete()
    if complete then
        if self._Control:CheckHasBlockError() then
            XUiManager.TipMsg(self._Control:GetClientConfigStringByKey('SpellErrorContent'))
            return
        end
        if hasEmpty then
            for i, v in pairs(emptyPatternIds) do
                self._Control:SetWordSpell(i, v, 1, nil)
            end
        end
        self._Control:KotodamaSpellSentenceDataSubmit(function(success)
            if success then
                XLuaUiManager.Open('UiKotodamaChapterDetail')
            end
        end)
    else
        XUiManager.TipMsg(self._Control:GetClientConfigStringByKey('SpellNotComplete'))
    end
end

function XUiPanelKotodamaMainContinue:RecordStageSelection(stageCtrl, isRecord)
    if self._RecordStageSelectionMap == nil then
        self._RecordStageSelectionMap = {}
    end
    if isRecord then
        self._RecordStageSelectionMap[stageCtrl.Id] = stageCtrl
    else
        self._RecordStageSelectionMap[stageCtrl.Id] = nil
    end
end

function XUiPanelKotodamaMainContinue:UnSelectAllRecordStage()
    if not XTool.IsTableEmpty(self._RecordStageSelectionMap) then
        local ids = {}
        for i, v in pairs(self._RecordStageSelectionMap) do
            table.insert(ids, i)
        end
        for i, v in ipairs(ids) do
            self._RecordStageSelectionMap[v]:UnSelect()
        end
    end
end

function XUiPanelKotodamaMainContinue:StartTimer()
    self:RefreshLeftTime()
    self:StopTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:RefreshLeftTime()
    end, XScheduleManager.SECOND, 0)
end

function XUiPanelKotodamaMainContinue:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiPanelKotodamaMainContinue:OnArtifactBtnClickEvent()
    XLuaUiManager.Open('UiKotodamaSpeech', function()
        XRedPointManager.Check(self.SpeechRedId)
    end, BtnGroupIndex.BtnArtifact)
end

--- 富文本包围盒点击回调
function XUiPanelKotodamaMainContinue:OnSentenceClickEvent(code)
    -- 没有删除类神器不能执行
    if not self._Control:CheckHasArtifact() then
        return
    else
        local artifactData = self._Control:GetArtifactData()
        if self._Control:GetArtifactTypeById(artifactData.ArtifactId) ~= XEnumConst.KotodamaActivity.ArtifactType.DeleteSentence then
            return
        end
    end
    
    if string.IsNilOrEmpty(code) then
        XLog.Error('点击的文本的包围盒标签参数code未指定:'..tostring(code))
    elseif not string.IsNumeric(code) then
        XLog.Error('code指定的内容不是数值:'..tostring(code))
    end
    
    local sentenceId = tonumber(code)
    if XTool.IsNumberValid(sentenceId) then
        -- 对该句子做删除/撤销删除操作
        if self._Control:CheckSentenceIsDeleteInCurStage(sentenceId) then
            -- 撤销删除操作
            self._Control:RemoveSentenceIdFromDeleteList(sentenceId)
            -- 刷新界面
            self:RefreshWordPanel()
            -- 弹窗提示
            XUiManager.TipMsg(self._Control:GetClientConfigStringByKey('CancelSentenceDeleteTips'))
        elseif self._Control:CheckCanDeleteSentence() then
            local content = self._Control:GetClientConfigStringByKey('DeleteSentenceTips')
            XUiManager.TipMsg(content)
            -- 删除
            self._Control:AddSentenceIdIntoDeleteList(sentenceId)
            -- 刷新界面
            self:RefreshWordPanel()
        end

    else
        XLog.Error('code指定的句子Id无效:'..tostring(sentenceId))
    end
end

function XUiPanelKotodamaMainContinue:OnGuideDeleteSentenceEvent(code)
    self:OnSentenceClickEvent(code)
end
--endregion
return XUiPanelKotodamaMainContinue
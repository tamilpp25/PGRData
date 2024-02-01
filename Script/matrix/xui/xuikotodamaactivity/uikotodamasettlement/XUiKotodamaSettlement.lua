local XUiKotodamaSettlement=XLuaUiManager.Register(XLuaUi,'UiKotodamaSettlement')

function XUiKotodamaSettlement:OnAwake()
    self.BtnClose.CallBack=handler(self,self.OnCloseEvent)
    self.BtnTanchuangClose.CallBack=handler(self,self.OnCloseEvent)
    self.BtnTongBlack.CallBack=handler(self,self.OnCloseEvent)
end

function XUiKotodamaSettlement:OnStart(data)
    self.WinData = data
    if not XTool.IsTableEmpty(self.WinData.KotodamaSettleResult) then
        self:Refresh()
    end
    self:SetStageNext()
    
end

function XUiKotodamaSettlement:Refresh()
    local totalStory1={}
    local totalStory2={}
    local totalEnd={}
    local totalSentenTitle={}
    
    local stageCfg=self._Control:GetKotodamaStageCfgById(self.WinData.StageId)
    if stageCfg then
        self.TxtTitle.text = XUiHelper.GetText('KotodamaStageTitleContent',stageCfg.StageTitle,stageCfg.StageTitleEx)
    end

    table.insert(totalStory1,stageCfg.StageContent)

    for i, sentenceId in ipairs(self.WinData.KotodamaSettleResult.Sentences or {}) do
        local cfg=self._Control:GetSentenceCfgById(sentenceId)
        if cfg then
            if cfg.IsCollect==1 then
                table.insert(totalSentenTitle,cfg.Title)
            end
            local words={}
            for i, v in ipairs(cfg.Words) do
                local wordCfg=self._Control:GetWordCfgByWordId(v)
                if wordCfg then
                    table.insert(words,wordCfg.Content)
                end
            end
            local patternCfg=self._Control:GetSentencePatternCfgById(cfg.PatternId)
            if patternCfg then
                --敌我词缀颜色修饰不同
                if patternCfg.Target==XEnumConst.KotodamaActivity.PatternEffectTarget.SELF then
                    for i, v in pairs(words) do
                        words[i]=XUiHelper.GetText('KotodamaSelfTargetWord',v)
                    end
                elseif patternCfg.Target==XEnumConst.KotodamaActivity.PatternEffectTarget.ENEMY then
                    for i, v in pairs(words) do
                        words[i]=XUiHelper.GetText('KotodamaEnemyTargetWord',v)
                    end
                end
                local fixedContent = ''
                if not string.IsNilOrEmpty(patternCfg.Content) then
                    fixedContent = XUiHelper.ReplaceTextNewLine(patternCfg.Content)
                end
                table.insert(totalStory1,XUiHelper.FormatText(fixedContent,table.unpack(words)))
            end
            local fixedExtraContent = ''
            if not string.IsNilOrEmpty(cfg.ExtraContent) then
                fixedExtraContent = XUiHelper.ReplaceTextNewLine(cfg.ExtraContent)
            end
            table.insert(totalStory2,fixedExtraContent)
            table.insert(totalEnd,cfg.EndContent)
        end
    end
    self.TxtStory1.text=table.concat(self:ConnectContent(totalStory1,totalStory2))
    --self.TxtStory2.text=table.concat(totalStory2)
    self.TxtEnd.text=table.concat(totalEnd)
    self.PanelNewSpeech.gameObject:SetActiveEx(true)
    self.Text.text=table.concat(totalSentenTitle)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelStory)
end

function XUiKotodamaSettlement:SetStageNext()
    --获取下一关
    self.curStageId=self._Control:GetCurStageData().StageId
    self.lastStageId=self.curStageId
    local nextStageId=XMVCA.XKotodamaActivity:GetNextStageIdByStageId(self.curStageId)
    if XTool.IsNumberValid(nextStageId) then
        --判断下一关是否解锁，是否是新解锁
        if XMVCA.XKotodamaActivity:CheckStageIsUnLockById(nextStageId) and XMVCA.XKotodamaActivity:CheckStageIsNew(nextStageId) then
            --请求关卡
            --获取选择关的最新通关的选词情况
            local spelldata=self._Control:GetPassStageSpell(nextStageId) or {}
            --将下一关的历史拼词数据覆盖到“当前关”字段
            self._Control:KotodamaCurStageDataRewriteLocal(function()
                XMVCA.XKotodamaActivity:SetStageNewState(nextStageId,XEnumConst.KotodamaActivity.LocalNewState.Old)
                --检测一次入口
                self._Control:CheckCurStageSpellValid()
            end,nextStageId,spelldata)
        end
    end
end

function XUiKotodamaSettlement:OnCloseEvent()
    self.curStageId=self._Control:GetCurStageData().StageId
    local nextStageId=XMVCA.XKotodamaActivity:GetNextStageIdByStageId(self.lastStageId)
    self:Close()
    XEventManager.DispatchEvent(XEventId.EVENT_KOTODAMA_AUTO_NEXT_STAGE,self.lastStageId)
    if not XTool.IsNumberValid(nextStageId) and not XSaveTool.GetData(XMVCA.XKotodamaActivity:GetKotodamaNotFirstAllPassKey()) then
        local activityCfg=XMVCA.XKotodamaActivity:GetCurActivityCfg()
        if activityCfg and XTool.IsNumberValid(activityCfg.EpilogueId) then
            XDataCenter.MovieManager.PlayMovie(activityCfg.EpilogueId,function()
                XSaveTool.SaveData(XMVCA.XKotodamaActivity:GetKotodamaNotFirstAllPassKey(),true)
            end,nil,nil,false)
        else
            XLog.Error('活动缺少终章配置,activityId:'..XMVCA.XKotodamaActivity:GetCurActivityId())
        end
    end
end

function XUiKotodamaSettlement:ConnectContent(story1,story2)
    table.insert(story1,'\n')
    table.insert(story1,table.concat(story2))
    return story1
end
return XUiKotodamaSettlement
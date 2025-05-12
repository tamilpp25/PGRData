---@class XUiKotodamaSettlement
---@field _Control XKotodamaActivityControl
local XUiKotodamaSettlement = XLuaUiManager.Register(XLuaUi, 'UiKotodamaSettlement')

function XUiKotodamaSettlement:OnAwake()
    self.BtnClose.CallBack = handler(self, self.OnCloseEvent)
    self.BtnTanchuangClose.CallBack = handler(self, self.OnCloseEvent)
    self.BtnTongBlack.CallBack = handler(self, self.OnCloseEvent)
end

function XUiKotodamaSettlement:OnStart(data)
    self.WinData = data
    if not XTool.IsTableEmpty(self.WinData.KotodamaSettleResult) then
        self:Refresh()
    end
    self:SetStageNext()

end

function XUiKotodamaSettlement:Refresh()
    local totalStory1 = {}
    local totalStory2 = {}
    local totalEnd = {}
    local totalSentenTitle = {}

    local stageCfg = self._Control:GetKotodamaStageCfgById(self.WinData.StageId)
    if stageCfg then
        self.TxtTitle.text = XUiHelper.FormatText(self._Control:GetClientConfigStringByKey('StageTitleContent'), stageCfg.StageTitle, stageCfg.StageTitleEx)
    end

    -- 关卡开头文本需检查是否有插值
    if not XTool.IsTableEmpty(stageCfg.SentenceIds) then
        local params = {}
        for i, v in ipairs(stageCfg.SentenceIds) do
            local sentenceCfg = self._Control:GetSentenceCfgById(v)
            if sentenceCfg then
                local sentenceStr = self._Control:GetSentenceStrBySentenceId(sentenceCfg.Id)
                --插入前还需检查下是否需要划线富文本
                if self._Control:CheckSentenceIsDeleteInCurStage(sentenceCfg.Id) then
                    sentenceStr = XUiHelper.FormatText(self._Control:GetClientConfigStringByKey('SentenceDeletedFormat'), sentenceStr)
                end
                table.insert(params, sentenceStr)
            end
        end
        table.insert(totalStory1, XUiHelper.FormatText(stageCfg.StageContent, table.unpack(params)))
    else
        table.insert(totalStory1, stageCfg.StageContent)
    end

    for i, sentenceId in ipairs(self.WinData.KotodamaSettleResult.Sentences or {}) do
        local baseContent, extraContent, endContent, collectableTitle = self._Control:GetSentenceStrBySentenceId(sentenceId)

        if not string.IsNilOrEmpty(baseContent) then
            table.insert(totalStory1, baseContent)
        end

        if not string.IsNilOrEmpty(extraContent) then
            table.insert(totalStory2, extraContent)
        end

        if not string.IsNilOrEmpty(endContent) then
            table.insert(totalEnd, endContent)
        end

        if not string.IsNilOrEmpty(collectableTitle) then
            table.insert(totalSentenTitle, collectableTitle)
        end
    end
    self.TxtStory1.text = table.concat(self:ConnectContent(totalStory1, totalStory2))
    --self.TxtStory2.text=table.concat(totalStory2)
    self.TxtEnd.text = table.concat(totalEnd)
    self.PanelNewSpeech.gameObject:SetActiveEx(true)
    self.Text.text = table.concat(totalSentenTitle)
    self:RefreshArtifactGet(stageCfg)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelStory)
end

function XUiKotodamaSettlement:SetStageNext()
    --获取下一关
    self.curStageId = self._Control:GetCurStageData().StageId
    self.lastStageId = self.curStageId
    local nextStageId = XMVCA.XKotodamaActivity:GetNextStageIdByStageId(self.curStageId)
    if XTool.IsNumberValid(nextStageId) then
        --判断下一关是否解锁，是否是新解锁
        if XMVCA.XKotodamaActivity:CheckStageIsUnLockById(nextStageId) and XMVCA.XKotodamaActivity:CheckStageIsNew(nextStageId) then
            --请求关卡
            --获取选择关的最新通关的选词情况
            local spelldata = self._Control:GetPassStageSpell(nextStageId) or {}
            local deleteData = self._Control:GetPassStageDeleteSentences(nextStageId) or 0
            --将下一关的历史拼词数据覆盖到“当前关”字段
            self._Control:KotodamaCurStageDataRewriteLocal(function()
                XMVCA.XKotodamaActivity:SetStageNewState(nextStageId, XEnumConst.KotodamaActivity.LocalNewState.Old)
                --检测一次入口
                self._Control:CheckCurStageSpellValid()
            end, nextStageId, spelldata, deleteData)
        end
    end
end

function XUiKotodamaSettlement:OnCloseEvent()
    self.curStageId = self._Control:GetCurStageData().StageId
    local nextStageId = XMVCA.XKotodamaActivity:GetNextStageIdByStageId(self.lastStageId)
    self:Close()
    XEventManager.DispatchEvent(XEventId.EVENT_KOTODAMA_AUTO_NEXT_STAGE, self.lastStageId)
    if not XTool.IsNumberValid(nextStageId) and not XSaveTool.GetData(XMVCA.XKotodamaActivity:GetKotodamaNotFirstAllPassKey()) then
        local activityCfg = XMVCA.XKotodamaActivity:GetCurActivityCfg()
        if activityCfg and XTool.IsNumberValid(activityCfg.EpilogueId) then
            XDataCenter.MovieManager.PlayMovie(activityCfg.EpilogueId, function()
                XSaveTool.SaveData(XMVCA.XKotodamaActivity:GetKotodamaNotFirstAllPassKey(), true)
            end, nil, nil, false)
        else
            XLog.Error('活动缺少终章配置,activityId:' .. XMVCA.XKotodamaActivity:GetCurActivityId())
        end
    end
end

function XUiKotodamaSettlement:ConnectContent(story1, story2)
    table.insert(story1, '\n')
    table.insert(story1, table.concat(story2))
    return story1
end

---@param stageCfg XTableKotodamaStage
function XUiKotodamaSettlement:RefreshArtifactGet(stageCfg)
    local needShowArtifactGet = self._Control:CheckHasNewArtifact() and XTool.IsNumberValid(stageCfg.UnLockArtifactComposeId)
    self.PanelArtifact.gameObject:SetActiveEx(needShowArtifactGet)

    if needShowArtifactGet then
        self.ArtifactContent.text = XUiHelper.FormatText(self._Control:GetClientConfigStringByKey('ArtifactGetFormat'), self._Control:GetArtifactFullDesc())
    end
end
return XUiKotodamaSettlement
local XUiGridKotodamaMemorySentence = XClass(XUiNode, 'XUiGridKotodamaMemorySentence')

function XUiGridKotodamaMemorySentence:Refresh(data)
    local totalStory1 = {}
    local totalStory2 = {}
    local totalEnd = {}

    local stageCfg = self._Control:GetKotodamaStageCfgById(data.StageId)
    self.TxtTitle.text = stageCfg.StageTitle

    -- 关卡开头文本需检查是否有插值
    if not XTool.IsTableEmpty(stageCfg.SentenceIds) then
        local params = {}
        for i, v in ipairs(stageCfg.SentenceIds) do
            local sentenceCfg = self._Control:GetSentenceCfgById(v)
            if sentenceCfg then
                local sentenceStr = self._Control:GetSentenceStrBySentenceId(sentenceCfg.Id)
                --插入前还需检查下是否需要划线富文本
                if self._Control:CheckSentenceIsDeleteInStageForMemory(data.StageId, sentenceCfg.Id) then
                    sentenceStr = XUiHelper.FormatText(self._Control:GetClientConfigStringByKey('SentenceDeletedFormat'), sentenceStr)
                end
                table.insert(params, sentenceStr)
            end
        end
        table.insert(totalStory1, XUiHelper.FormatText(stageCfg.StageContent, table.unpack(params)))
    else
        table.insert(totalStory1, stageCfg.StageContent)
    end
    
    for i, sentenceId in ipairs(data.CurSentences) do
        local baseContent, extraContent, endContent = self._Control:GetSentenceStrBySentenceId(sentenceId)

        if not string.IsNilOrEmpty(baseContent) then
            table.insert(totalStory1, baseContent)
        end

        if not string.IsNilOrEmpty(extraContent) then
            table.insert(totalStory2, extraContent)
        end

        if not string.IsNilOrEmpty(endContent) then
            table.insert(totalEnd, endContent)
        end
    end
    self.TxtStory1.text = table.concat(self:ConnectContent(totalStory1, totalStory2, totalEnd))
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.RectTrans)
end

function XUiGridKotodamaMemorySentence:ConnectContent(story1, story2, endStory)
    table.insert(story1, '\n')
    table.insert(story1, table.concat(story2))
    table.insert(story1, '\n')
    table.insert(story1, table.concat(endStory))
    return story1
end
return XUiGridKotodamaMemorySentence
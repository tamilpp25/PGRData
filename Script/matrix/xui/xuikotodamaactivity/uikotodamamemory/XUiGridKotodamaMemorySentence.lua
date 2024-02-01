local XUiGridKotodamaMemorySentence=XClass(XUiNode,'XUiGridKotodamaMemorySentence')

function XUiGridKotodamaMemorySentence:Refresh(data)
    local totalStory1={}
    local totalStory2={}
    local totalEnd={}
    
    local stageCfg=self._Control:GetKotodamaStageCfgById(data.StageId)
    self.TxtTitle.text=stageCfg.StageTitle
    table.insert(totalStory1,stageCfg.StageContent)

    for i, sentenceId in ipairs(data.CurSentences) do
        local cfg=self._Control:GetSentenceCfgById(sentenceId)
        if cfg then
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
            local fixedExtra = ''
            local fixedEnd = ''
            if not string.IsNilOrEmpty(cfg.ExtraContent) then
                fixedExtra = XUiHelper.ReplaceTextNewLine(cfg.ExtraContent)
            end
            if not string.IsNilOrEmpty(cfg.EndContent) then
                fixedEnd = XUiHelper.ReplaceTextNewLine(cfg.EndContent)
            end
            table.insert(totalStory2,fixedExtra)
            table.insert(totalEnd,fixedEnd)
        end
    end
    self.TxtStory1.text=table.concat(self:ConnectContent(totalStory1,totalStory2,totalEnd))
    --self.TxtStory2.text=table.concat(totalStory2)
    --self.TxtEnd.text=table.concat(totalEnd)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.RectTrans)
end

function XUiGridKotodamaMemorySentence:ConnectContent(story1,story2,endStory)
    table.insert(story1,'\n')
    table.insert(story1,table.concat(story2))
    table.insert(story1,'\n')
    table.insert(story1,table.concat(endStory))
    return story1
end
return XUiGridKotodamaMemorySentence
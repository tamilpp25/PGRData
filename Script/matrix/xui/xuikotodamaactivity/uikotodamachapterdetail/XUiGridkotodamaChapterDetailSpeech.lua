---@class XUiGridKotodamaChapterDetailSpeech
---@field _Control XKotodamaActivityControl
local XUiGridKotodamaChapterDetailSpeech = XClass(XUiNode, 'XUiGridKotodamaChapterDetailSpeech')

function XUiGridKotodamaChapterDetailSpeech:Refresh(sentenceId, visible)
    local sentenceCfg = self._Control:GetSentenceCfgById(sentenceId)
    --self.TxtSpeech.text=sentenceCfg.Title
    local multyText = {}
    local fightEventIds = {}
    
    local needDelete = false
    
    if sentenceCfg.IsEnableBan and self._Control:CheckSentenceIsDeleteInCurStage(sentenceId) then
        if not XTool.IsTableEmpty(sentenceCfg.BanFightEventIds) then
            fightEventIds = sentenceCfg.BanFightEventIds
        elseif not visible then --正常来说如果没有ban的buff，这个不会显示，但现在用删除线来表示，所以要显示ban之前的buff
            needDelete = true
            fightEventIds = sentenceCfg.FightEventIds
        end
    else
        fightEventIds = sentenceCfg.FightEventIds
    end
    
    for i, v in pairs(fightEventIds) do
        if XTool.IsNumberValid(v) then
            table.insert(multyText, XRoomSingleManager.GetEvenDesc(v))
        end
    end
    
    self.TxtSpeech.gameObject:SetActiveEx(true)
    local fixedTitle = ''
    if not string.IsNilOrEmpty(sentenceCfg.TitleFormat) and not string.IsNilOrEmpty(sentenceCfg.Title) then
        fixedTitle = XUiHelper.FormatText(sentenceCfg.TitleFormat, sentenceCfg.Title)
    end
    fixedTitle = XUiHelper.FormatText(self._Control:GetClientConfigStringByKey('ChapterDetailSpeech'), fixedTitle, table.concat(multyText))
    
    --判断是否需要加删除线
    if needDelete then
        fixedTitle = XUiHelper.FormatText(self._Control:GetClientConfigStringByKey('SentenceDeletedFormat'), fixedTitle)
    end
    
    self.TxtSpeech.text = XUiHelper.ReplaceTextNewLine(fixedTitle)
    --self.TxtBuff.text=table.concat(multyText)
end

function XUiGridKotodamaChapterDetailSpeech:SetTextVisible(isVisible)
    if not isVisible then
        self.TxtSpeech.text = self._Control:GetClientConfigStringByKey('EmptySpeech')
    else
        self.TxtSpeech.text = ''
    end
    --self.TxtSpeech.gameObject:SetActiveEx(isVisible)
end
return XUiGridKotodamaChapterDetailSpeech
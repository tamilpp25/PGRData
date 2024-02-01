local XUiGridKotodamaChapterDetailSpeech=XClass(XUiNode,'XUiGridKotodamaChapterDetailSpeech')

function XUiGridKotodamaChapterDetailSpeech:Refresh(sentenceId)
    local sentenceCfg=self._Control:GetSentenceCfgById(sentenceId)
    --self.TxtSpeech.text=sentenceCfg.Title
    local multyText={}
    for i, v in pairs(sentenceCfg.FightEventIds) do
        if XTool.IsNumberValid(v) then
            table.insert(multyText,XRoomSingleManager.GetEvenDesc(v))
        end
    end
    self.TxtSpeech.gameObject:SetActiveEx(true)
    local fixedTitle = ''
    if not string.IsNilOrEmpty(sentenceCfg.TitleFormat) and not string.IsNilOrEmpty(sentenceCfg.Title) then
        fixedTitle = XUiHelper.FormatText(sentenceCfg.TitleFormat,sentenceCfg.Title)
    end
    self.TxtSpeech.text=XUiHelper.GetText('KotodamaChapterDetailSpeech',fixedTitle,table.concat(multyText))
    --self.TxtBuff.text=table.concat(multyText)
end

function XUiGridKotodamaChapterDetailSpeech:SetTextVisible(isVisible)
    if not isVisible then
        self.TxtSpeech.text = XUiHelper.GetText('KotodamaEmptySpeech')
    else
        self.TxtSpeech.text = ''
    end
    --self.TxtSpeech.gameObject:SetActiveEx(isVisible)
end
return XUiGridKotodamaChapterDetailSpeech
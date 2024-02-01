local XUiGridKotodamaSpeech=XClass(XUiNode,'XUiGridKotodamaSpeech')

function XUiGridKotodamaSpeech:Refresh(sentenceId)
    local cfg=self._Control:GetSentenceCfgById(sentenceId)
    if cfg then
        self.TxtSpeech.text=cfg.Title
        local multyText={}
        for i, v in pairs(cfg.FightEventIds) do
            table.insert(multyText,XRoomSingleManager.GetEvenDesc(v))
        end
        self.TxtBuff.text=table.concat(multyText)
    end
    
    --红点
    if self.ImgNew then
        self.ImgNew.gameObject:SetActiveEx(XMVCA.XKotodamaActivity:CheckSpeechIsNew(sentenceId))
    end
end

return XUiGridKotodamaSpeech
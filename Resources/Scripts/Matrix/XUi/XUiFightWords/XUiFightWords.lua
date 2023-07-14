local XUiFightWords = XLuaUiManager.Register(XLuaUi, "UiFightWords")

function XUiFightWords:OnAwake(id)
    self.WordsId = id
    self.PlayNextWordCb = function(content) self:PlayNextWord(content) end
    self:AddListeners()
end

function XUiFightWords:OnEnable()
    self:ResetState()
    self:RunWords()
end

function XUiFightWords:OnDisable()
end

function XUiFightWords:OnDestroy()
    -- self.TxtWordsTypeWriter:Stop()
    self:RemoveListeners()
end

function XUiFightWords:AddListeners()
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_WORDS_NEXT, self.PlayNextWordCb)
end

function XUiFightWords:RemoveListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_WORDS_NEXT, self.PlayNextWordCb)
end

function XUiFightWords:ResetState()
    self.TxtWords.text = ""
    -- self.TxtWordsTypeWriter:Stop()
end

function XUiFightWords:RunWords()
    if not self.WordsId then
        return
    end
    XDataCenter.FightWordsManager.Run(self.WordsId)
end

function XUiFightWords:PlayNextWord(content)
	if content == nil or content == '' then
		return
	end
	self.TxtWords.text = string.gsub(content,"\\n","\n")
end

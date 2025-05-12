---@class XUiGridKotodamaBlock:XUiNode
---@field _Control XKotodamaActivityControl
local XUiGridKotodamaBlock = XClass(XUiNode, 'XUiGridKotodamaBlock')

function XUiGridKotodamaBlock:OnStart(index)
    self.index = index
    self.RectTrans = self.GameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
    self.BtnClick.CallBack = function()
        self.Parent:SelectBlockGrid(self)
    end
    self.CancelSelect.CallBack = handler(self, self.OnCancelSelectEvent)
end

function XUiGridKotodamaBlock:Refresh(cfg, patternIndex, patternId, wordIndex, wordId, useDefault)
    self.Id = cfg.Id
    self.patternId = patternId
    self.wordIndex = wordIndex
    self.patternIndex = patternIndex
    self.RectTrans.anchoredPosition = Vector2(cfg.AnchoredX, cfg.AnchoredY)

    if not XTool.IsNumberValid(wordId) and useDefault then
        --尝试查找默认词
        wordId = self._Control:GetDefaultWordByPatternIdAndWordIndex(patternId, wordIndex)
        if XTool.IsNumberValid(wordId) then
            self._Control:SetAndCheckWordSpell(patternIndex, patternId, wordIndex, wordId, function()
                self.Parent:RefreshWordPanel()
                --刷新自己的正确状态
                self.ErrorTag.gameObject:SetActiveEx(self._Control:GetBlockErrorState(patternIndex, wordIndex))
            end)
        end
    end

    if XTool.IsNumberValid(patternId) and XTool.IsNumberValid(wordId) then
        if self._Control:CheckWordIsUnLock(wordId) then
            self:SetWord(patternId, wordId)
        else
            self._Control:SetWordSpell(self.patternIndex, self.patternId, self.wordIndex, nil)
            self:ClearWord()
        end
    else
        self:ClearWord()
    end
    --刷新自己的正确状态
    self.ErrorTag.gameObject:SetActiveEx(self._Control:GetBlockErrorState(patternIndex, wordIndex))

    --设置UI宽度
    local id = 100000 + patternId * 100 + wordIndex
    local cfg = self._Control:GetWordBlockCfgById(id)
    if cfg then
        self.RectTrans.sizeDelta = Vector2(cfg.UIWidth, self.RectTrans.sizeDelta.y)
    end
end

function XUiGridKotodamaBlock:SetWord(patternId, wordId)
    local target = self._Control:GetPatternTargetByPatternId(patternId)
    local wordCfg = self._Control:GetWordCfgByWordId(wordId)
    if wordCfg then
        local isEnemy = target == XEnumConst.KotodamaActivity.PatternEffectTarget.ENEMY
        local isSelf = target == XEnumConst.KotodamaActivity.PatternEffectTarget.SELF
        self.PanelEnemy.gameObject:SetActiveEx(isEnemy)
        self.PanelWe.gameObject:SetActiveEx(isSelf)
        self.ImgEnemyBg.gameObject:SetActiveEx(false)
        self.ImgWeBg.gameObject:SetActiveEx(false)
        if isSelf then
            self.WeText.text = wordCfg.Content
        elseif isEnemy then
            self.EnemyText.text = wordCfg.Content
        end
        self._isFillWord = true
        self.CancelSelect.gameObject:SetActiveEx(true)
    end
end

function XUiGridKotodamaBlock:ClearWord()
    local target = self._Control:GetPatternTargetByPatternId(self.patternId)
    self.PanelEnemy.gameObject:SetActiveEx(false)
    self.PanelWe.gameObject:SetActiveEx(false)

    self.ImgEnemyBg.gameObject:SetActiveEx(target == XEnumConst.KotodamaActivity.PatternEffectTarget.ENEMY)
    self.ImgWeBg.gameObject:SetActiveEx(target == XEnumConst.KotodamaActivity.PatternEffectTarget.SELF)
    self._isFillWord = false
    self.CancelSelect.gameObject:SetActiveEx(false)
end

function XUiGridKotodamaBlock:Select()
    self.BtnClick:SetButtonState(CS.UiButtonState.Select)
end

function XUiGridKotodamaBlock:UnSelect()
    self.BtnClick:SetButtonState(CS.UiButtonState.Normal)
end

function XUiGridKotodamaBlock:IsFillWord()
    return self._isFillWord
end

function XUiGridKotodamaBlock:GetIndex()
    return self.index
end

function XUiGridKotodamaBlock:OnCancelSelectEvent()
    if self:IsFillWord() then
        self._Control:SetWordSpell(self.patternIndex, self.patternId, self.wordIndex, nil)
        self:ClearWord()
        self._Control:CheckPatternSpellErrorLocal()
        self.Parent:RefreshWordPanel()
    end
end
return XUiGridKotodamaBlock
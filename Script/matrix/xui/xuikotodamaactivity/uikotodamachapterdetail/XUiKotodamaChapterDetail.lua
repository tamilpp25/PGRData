---@class XUiKotodamaChapterDetail
---@field _Control XKotodamaActivityControl
local XUiKotodamaChapterDetail = XLuaUiManager.Register(XLuaUi, 'UiKotodamaChapterDetail')
local XUiGridKotodamaChapterDetailMonster = require('XUi/XUiKotodamaActivity/UiKotodamaChapterDetail/XUiGridKotodamaChapterDetailMonster')
local XUiGridkotodamaChapterDetailSpeech = require('XUi/XUiKotodamaActivity/UiKotodamaChapterDetail/XUiGridkotodamaChapterDetailSpeech')

local MonsterSpeechMax = 3
local SelfSpeechMax = 1

function XUiKotodamaChapterDetail:OnAwake()
    self.BtnClose.CallBack = function()
        self:Close()
    end
    self.BtnTanchuangClose.CallBack = function()
        self:Close()
    end
    self.BtnTongBlack.CallBack = function()
        XLuaUiManager.Open('UiBattleRoleRoom', self._Control:GetCurStageId(), XMVCA.XKotodamaActivity:LoadTeamLocal(), require('XUi/XUiKotodamaActivity/XUiKotodamaActivityBattleRoomProxy'))
    end
    self.GridMonster.gameObject:SetActiveEx(false)
    self.MonsterGridList = {}
    self:InitSpeechGrids()
end

function XUiKotodamaChapterDetail:OnStart()
    self.curStageId = self._Control:GetCurStageId()
    if XTool.IsNumberValid(self.curStageId) == false then
        return
    end
    self:RefreshPanel()
end

--region 初始化
function XUiKotodamaChapterDetail:InitSpeechGrids()
    self.MonsterGridSpeechCtrlList = {}
    for i = 1, 10 do
        if self['PanelBoss'..i] then
            local ctrl = XUiGridkotodamaChapterDetailSpeech.New(self['PanelBoss'..i], self)
            table.insert(self.MonsterGridSpeechCtrlList, ctrl)
            ctrl:Close()
        end
    end
    
    self.PulaoGridSpeechCtrl = XUiGridkotodamaChapterDetailSpeech.New(self.PanelPulao, self)
end

function XUiKotodamaChapterDetail:GetMonsterSpeechCtrl(index)
    if self.MonsterGridSpeechCtrlList[index] then
        return self.MonsterGridSpeechCtrlList[index]
    elseif self['PanelBoss'..index] then
        self.MonsterGridSpeechCtrlList[index] = XUiGridkotodamaChapterDetailSpeech.New(self['PanelBoss'..index], self)
        return self.MonsterGridSpeechCtrlList[index]
    else
        return false
    end
end
--endregion

--region 界面刷新
function XUiKotodamaChapterDetail:RefreshPanel()
    local cfg = self._Control:GetKotodamaStageCfgById(self.curStageId)
    --标题
    self.TxtTiTle.text = XUiHelper.FormatText(self._Control:GetClientConfigStringByKey('StageTitleContent'), cfg.StageTitle, cfg.StageTitleEx)
    self:RefreshMonsterGrids()
    self:RefreshSpeechGrids()
end

function XUiKotodamaChapterDetail:RefreshMonsterGrids()
    --回收所有
    for i, v in pairs(self.MonsterGridList) do
        v:Close()
    end
    local cfg = self._Control:GetKotodamaStageCfgById(self.curStageId)
    for i, v in ipairs(cfg.ShowMonsterIcon) do
        if self.MonsterGridList[i] == nil then
            local clone = CS.UnityEngine.GameObject.Instantiate(self.GridMonster, self.GridMonster.transform.parent)
            clone.gameObject:SetActiveEx(false)
            self.MonsterGridList[i] = XUiGridKotodamaChapterDetailMonster.New(clone, self)
        end
        self.MonsterGridList[i]:Open()
        self.MonsterGridList[i]:Refresh(v, cfg.ShowMonsterName[i])
    end
end

function XUiKotodamaChapterDetail:RefreshSpeechGrids()
    for i, v in pairs(self.MonsterGridSpeechCtrlList) do
        v:Close()
    end
    if self.MonsterGridSpeechCtrlList[1] then
        self.MonsterGridSpeechCtrlList[1]:Open()
        self.MonsterGridSpeechCtrlList[1]:SetTextVisible(false)
    end
    
    self.PulaoGridSpeechCtrl:SetTextVisible(false)
    local curStageData = self._Control:GetCurStageData()
    if curStageData then
        local monsterSpeechCount = 0
        local selfSpeechCount = 0
        -- 拼词句子的效果
        if not XTool.IsTableEmpty(curStageData.SpellSentences) then
            for i, v in ipairs(curStageData.SpellSentences) do
                local target = self._Control:GetPatternTargetByPatternId(v.PatternId)
                --找到该句式拼词对应的句子
                local sentenceId = self._Control:GetSentenceIdByPatternIdAndWords(v.PatternId, v.SelectWords)

                if self:CheckSpeechIsVisible(sentenceId) then
                    if target == XEnumConst.KotodamaActivity.PatternEffectTarget.ENEMY and monsterSpeechCount < MonsterSpeechMax then
                        monsterSpeechCount = monsterSpeechCount + 1
                        local speechCtrl = self:GetMonsterSpeechCtrl(monsterSpeechCount)
                        if speechCtrl then
                            speechCtrl:Open()
                            speechCtrl:Refresh(sentenceId)
                        end
                    elseif target == XEnumConst.KotodamaActivity.PatternEffectTarget.SELF and selfSpeechCount < SelfSpeechMax then
                        selfSpeechCount = selfSpeechCount + 1
                        self.PulaoGridSpeechCtrl:Refresh(sentenceId)
                    end
                end
            end
        end
        -- 插入句子的效果
        local stageCfg = self._Control:GetKotodamaStageCfgById(curStageData.StageId)
        if stageCfg and not XTool.IsTableEmpty(stageCfg.SentenceIds) then
            for i, v in ipairs(stageCfg.SentenceIds) do
                ---@type XTableKotodamaSentence
                local sentenceCfg = self._Control:GetSentenceCfgById(v)
                local target = self._Control:GetPatternTargetByPatternId(sentenceCfg.PatternId)
                local isSentenceVisible = self:CheckSpeechIsVisible(sentenceCfg.Id)
                if target == XEnumConst.KotodamaActivity.PatternEffectTarget.ENEMY and monsterSpeechCount < MonsterSpeechMax then
                    monsterSpeechCount = monsterSpeechCount + 1
                    local speechCtrl = self:GetMonsterSpeechCtrl(monsterSpeechCount)
                    if speechCtrl then
                        speechCtrl:Open()
                        speechCtrl:Refresh(sentenceCfg.Id, isSentenceVisible)
                    end
                elseif target == XEnumConst.KotodamaActivity.PatternEffectTarget.SELF and selfSpeechCount < SelfSpeechMax then
                    selfSpeechCount = selfSpeechCount + 1
                    self.PulaoGridSpeechCtrl:Refresh(sentenceCfg.Id, isSentenceVisible)
                end
            end
        end
    end
end

--endregion
function XUiKotodamaChapterDetail:CheckSpeechIsVisible(sentenceId)
    ---@type XTableKotodamaSentence
    local sentenceCfg = self._Control:GetSentenceCfgById(sentenceId)
   
    if sentenceCfg.IsEnableBan and self._Control:CheckSentenceIsDeleteInCurStage(sentenceId) then
        return not XTool.IsTableEmpty(sentenceCfg.BanFightEventIds)
    elseif XTool.IsNumberValid(sentenceCfg.IsVisible) then
        return true
    else
        return false
    end
end

return XUiKotodamaChapterDetail
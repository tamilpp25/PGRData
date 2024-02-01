local XUiKotodamaChapterDetail=XLuaUiManager.Register(XLuaUi,'UiKotodamaChapterDetail')
local XUiGridKotodamaChapterDetailMonster=require('XUi/XUiKotodamaActivity/UiKotodamaChapterDetail/XUiGridKotodamaChapterDetailMonster')
local XUiGridkotodamaChapterDetailSpeech=require('XUi/XUiKotodamaActivity/UiKotodamaChapterDetail/XUiGridkotodamaChapterDetailSpeech')

local MonsterSpeechMax=1
local SelfSpeechMax=1

function XUiKotodamaChapterDetail:OnAwake()
    self.BtnClose.CallBack=function() self:Close() end
    self.BtnTanchuangClose.CallBack=function() self:Close() end
    self.BtnTongBlack.CallBack=function()
        XLuaUiManager.Open('UiBattleRoleRoom',self._Control:GetCurStageId(),XMVCA.XKotodamaActivity:LoadTeamLocal(),require('XUi/XUiKotodamaActivity/XUiKotodamaActivityBattleRoomProxy'))
    end
    self.GridMonster.gameObject:SetActiveEx(false)
    self.MonsterGridList={}
    self:InitSpeechGrids()
end

function XUiKotodamaChapterDetail:OnStart()
    self.curStageId=self._Control:GetCurStageId()
    if XTool.IsNumberValid(self.curStageId)==false then return end
    self:RefreshPanel()
end

--region 初始化
function XUiKotodamaChapterDetail:InitSpeechGrids()
    self.MonsterGridSpeechCtrl=XUiGridkotodamaChapterDetailSpeech.New(self.PanelBoss,self)
    self.PulaoGridSpeechCtrl=XUiGridkotodamaChapterDetailSpeech.New(self.PanelPulao,self)
end
--endregion

--region 界面刷新
function XUiKotodamaChapterDetail:RefreshPanel()
    local cfg=self._Control:GetKotodamaStageCfgById(self.curStageId)
    --标题
    self.TxtTiTle.text = XUiHelper.GetText('KotodamaStageTitleContent',cfg.StageTitle,cfg.StageTitleEx)
    self:RefreshMonsterGrids()
    self:RefreshSpeechGrids()
end

function XUiKotodamaChapterDetail:RefreshMonsterGrids()
    --回收所有
    for i, v in pairs(self.MonsterGridList) do
        v:Close()
    end
    local cfg=self._Control:GetKotodamaStageCfgById(self.curStageId)
    for i, v in ipairs(cfg.ShowMonsterIcon) do
        if self.MonsterGridList[i]==nil then
            local clone=CS.UnityEngine.GameObject.Instantiate(self.GridMonster,self.GridMonster.transform.parent)
            clone.gameObject:SetActiveEx(false)
            self.MonsterGridList[i]=XUiGridKotodamaChapterDetailMonster.New(clone,self)
        end
        self.MonsterGridList[i]:Open()
        self.MonsterGridList[i]:Refresh(v,cfg.ShowMonsterName[i])
    end
end

function XUiKotodamaChapterDetail:RefreshSpeechGrids()
    self.MonsterGridSpeechCtrl:SetTextVisible(false)
    self.PulaoGridSpeechCtrl:SetTextVisible(false)
    local curStageData=self._Control:GetCurStageData()
    if curStageData then
        local monsterSpeechCount=0
        local selfSpeechCount=0
        for i, v in ipairs(curStageData.SpellSentences or {}) do
            local target=self._Control:GetPatternTargetByPatternId(v.PatternId)
            --找到该句式拼词对应的句子
            local sentenceId=self._Control:GetSentenceIdByPatternIdAndWords(v.PatternId,v.SelectWords)
            
            if target==XEnumConst.KotodamaActivity.PatternEffectTarget.ENEMY and monsterSpeechCount< MonsterSpeechMax then
                monsterSpeechCount=monsterSpeechCount+1
                self.MonsterGridSpeechCtrl:Refresh(sentenceId)
            elseif target==XEnumConst.KotodamaActivity.PatternEffectTarget.SELF and selfSpeechCount<SelfSpeechMax then
                selfSpeechCount=selfSpeechCount+1
                self.PulaoGridSpeechCtrl:Refresh(sentenceId)
            end
        end
    end
end
--endregion

return XUiKotodamaChapterDetail
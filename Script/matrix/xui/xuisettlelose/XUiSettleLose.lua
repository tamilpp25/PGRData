local XUiSettleLose = XLuaUiManager.Register(XLuaUi, "UiSettleLose")

local GridLoseTip = require("XUi/XUiSettleLose/XUiGridLoseTip")
local XUiStageSettleSound = require("XUi/XUiSettleWin/XUiStageSettleSound")

function XUiSettleLose:OnAwake()
    self:InitAutoScript()
    self.GridLoseTip.gameObject:SetActiveEx(false)
end

function XUiSettleLose:OnStart()
    local beginData = XDataCenter.FubenManager.GetFightBeginData()
    if not beginData then
        self.TxtPeople.text = ""
        self.TxtStageName.text = ""
        self.BtnRestart.gameObject:SetActiveEx(false)
        self.BtnTongRed.gameObject:SetActiveEx(false)
        self:SetTips(0)
        return
    end
    local count = 0
    for _, v in pairs(beginData.CharList) do
        if v ~= 0 then
            count = count + 1
        end
    end
    self.TxtPeople.text = CS.XTextManager.GetText("BattleLoseActorNum", count)

    local stageId = beginData.StageId
    self.StageId = stageId

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    self.TxtStageName.text = stageCfg.Name

    local type = XMVCA.XFuben:GetStageType(stageId)
    local showBtnRestart = type == XDataCenter.FubenManager.StageType.BabelTower or type == XDataCenter.FubenManager.StageType.PracticeBoss
    self.BtnRestart.gameObject:SetActiveEx(showBtnRestart)
    self.BtnTongRed.gameObject:SetActiveEx(type == XDataCenter.FubenManager.StageType.BabelTower)
    self:SetTips(stageCfg.SettleLoseTipId)
    ---@type XUiStageSettleSound
    self.UiStageSettleSound = XUiStageSettleSound.New(self, self.StageId, false)
end

function XUiSettleLose:OnEnable()
    XDataCenter.FunctionEventManager.UnLockFunctionEvent()
    
    local IsSkipSettleLose = XFubenConfigs.CheckStepIsSkip(self.StageId, XFubenConfigs.StepSkipType.SettleLose)
    if IsSkipSettleLose then
        XScheduleManager.ScheduleOnce(function()
                self.GameObject:SetActiveEx(false)
                self:Close()
            end, 0)
    end
    if self.UiStageSettleSound then
        self.UiStageSettleSound:PlaySettleSound()
    end
end

function XUiSettleLose:OnDestroy()
    XDataCenter.AntiAddictionManager.EndFightAction()
    XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_FINISH_LOSEUI_CLOSE)
    if self.UiStageSettleSound then
        self.UiStageSettleSound:StopSettleSound()
        self.UiStageSettleSound = nil
    end
end

---
--- 根据"settleLoseTipId"来生成提示
function XUiSettleLose:SetTips(settleLoseTipId)
    if not self.HadSetTip then
        local tipDescList = XFubenConfigs.GetTipDescList(settleLoseTipId)
        if tipDescList == nil then
            XLog.Error("XUiSettleLose:SetTips函数错误，tipDescList为空")
            return
        end
        local skipIdList = XFubenConfigs.GetSkipIdList(settleLoseTipId)
        if tipDescList == nil then
            XLog.Error("XUiSettleLose:SetTips函数错误，skipIdList为空")
            return
        end

        for i, desc in ipairs(tipDescList) do
            local obj = CS.UnityEngine.Object.Instantiate(self.GridLoseTip)
            obj.transform:SetParent(self.PanelTips.transform, false)
            obj.gameObject:SetActiveEx(true)
            GridLoseTip.New(obj, self, { ["TipDesc"] = desc, ["SkipId"] = skipIdList[i] })
        end
        self.HadSetTip = true
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiSettleLose:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiSettleLose:AutoInitUi()
    self.BtnLose = self.Transform:Find("SafeAreaContentPane/PanelLose/BtnLose"):GetComponent("Button")
end

function XUiSettleLose:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiSettleLose:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then
        return
    end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiSettleLose:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XLuaAudioManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiSettleLose:AutoAddListener()
    self.AutoCreateListeners = {}
    self:RegisterClickEvent(self.BtnLose, self.OnBtnLoseClick)
    self.BtnRestart.CallBack = function() self:OnClickBtnRestart() end
    self:RegisterClickEvent(self.BtnTongRed, self.OnBtnTongRed)
end
-- auto
function XUiSettleLose:OnBtnLoseClick()
    --CS.XAudioManager.RemoveCueSheet(CS.XAudioManager.BATTLE_MUSIC_CUE_SHEET_ID)
    --XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Music, CS.XAudioManager.MAIN_BGM)
    if XMVCA.XArena:CheckRunMainWhenFightOver() then
        return
    end

    local beginData = XDataCenter.FubenManager.GetFightBeginData()
    if not beginData then
        self:Close()
        return
    end
    if XDataCenter.ArenaOnlineManager.JudgeGotoMainWhenFightOver(beginData.StageId) then
        return
    end
    --- 囚笼没有TimeId， 战斗内换期需要退出后踢回主界面
    if XMVCA.XFubenBossSingle:CheckAcitvityEnd(self.StageId) then
        local data = XMVCA.XFubenBossSingle:GetBossSingleData()

        XLuaUiManager.RunMain()
        data:SetIsNeedReset(false)
        return
    end
    
    -- 据点挑战检查是否跳章节了，跳章节要打开对应章节的副本界面
    if XDataCenter.BfrtManager.CheckIsBfrtStage(self.StageId) then
        local bfrtChapterId = XDataCenter.BfrtManager.GetChapterIdByStageId(self.StageId)
        if bfrtChapterId ~= 0 then
            if XDataCenter.BfrtManager.CheckSkipChapterByStageId(self.StageId) then
                XDataCenter.BfrtManager.SetHandEnterFightChapterId(0)
                XLuaUiManager.Remove("UiFubenMainLineChapter")
                XLuaUiManager.PopThenOpen("UiFubenMainLineChapter", XDataCenter.BfrtManager.GetChapterCfg(bfrtChapterId), nil, true)
            else
                self:Close()
            end

            return
        end
    end

    if XMVCA.XArena:CheckIsArenaStage(self.StageId) then
        XMVCA.XArena:SetIsRefreshMainPage(true)
    end
    
    self:Close()
end

function XUiSettleLose:OnClickBtnRestart()
    self:Close()

    local type = XMVCA.XFuben:GetStageType(self.StageId)
    if type == XDataCenter.FubenManager.StageType.BabelTower then
        if XLuaUiManager.IsUiLoad("UiBabelTowerSelectDiffcult") then
            XLuaUiManager.Remove("UiBabelTowerSelectDiffcult")
        end

        local curStageId, curTeamId, curStageGuideId, teamList, challengeBuffList, supportBuffList, captainPos, curStageLevel, firstFightPos = XDataCenter.FubenBabelTowerManager.GetCurStageInfo()
        XDataCenter.FubenBabelTowerManager.SelectBabelTowerStage(curStageId, curStageGuideId, teamList, challengeBuffList, supportBuffList, function()
            XDataCenter.FubenManager.EnterBabelTowerFight(curStageId, teamList, captainPos, firstFightPos)
        end, curStageLevel, curTeamId)
    elseif type == XDataCenter.FubenManager.StageType.PracticeBoss then
        local beginPreData = XDataCenter.FubenManager.GetFightBeginClientPreData()
        XDataCenter.FubenManager.EnterPracticeBoss(beginPreData[1],beginPreData[2],beginPreData[3])
    end
end

function XUiSettleLose:OnBtnTongRed()
    --打点
    local dict = {}
    dict["button_id"] = 1
    dict["stage_id"] = self.StageId
    CS.XRecord.Record(dict, "200005", "CombatFailure")

    --- 囚笼没有TimeId， 战斗内换期需要退出后踢回主界面
    if XMVCA.XFubenBossSingle:CheckAcitvityEnd(self.StageId) then
        local data = XMVCA.XFubenBossSingle:GetBossSingleData()

        XLuaUiManager.RunMain()
        data:SetIsNeedReset(false)
    else
        self:Close()
    end
end 
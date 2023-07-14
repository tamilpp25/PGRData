local XUiSettleLose = XLuaUiManager.Register(XLuaUi, "UiSettleLose")

local GridLoseTip = require("XUi/XUiSettleLose/XUiGridLoseTip")

function XUiSettleLose:OnAwake()
    self:InitAutoScript()
    self.GridLoseTip.gameObject:SetActiveEx(false)
end

function XUiSettleLose:OnStart()
    local beginData = XDataCenter.FubenManager.GetFightBeginData()
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

    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local type = stageInfo.Type
    local showBtnRestart = type == XDataCenter.FubenManager.StageType.BabelTower or type == XDataCenter.FubenManager.StageType.PracticeBoss
    self.BtnRestart.gameObject:SetActiveEx(showBtnRestart)
    self.BtnTongRed.gameObject:SetActiveEx(stageInfo.Type == XDataCenter.FubenManager.StageType.BabelTower)
    self:SetTips(stageCfg.SettleLoseTipId)
    CS.XInputManager.SetCurOperationType(CS.XOperationType.System)
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
end

function XUiSettleLose:OnDestroy()
    XDataCenter.AntiAddictionManager.EndFightAction()
    XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_FINISH_LOSEUI_CLOSE)
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
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
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
    --CS.XAudioManager.PlayMusic(CS.XAudioManager.MAIN_BGM)
    if XDataCenter.ArenaManager.JudgeGotoMainWhenFightOver() then
        return
    end

    local beginData = XDataCenter.FubenManager.GetFightBeginData()
    if XDataCenter.ArenaOnlineManager.JudgeGotoMainWhenFightOver(beginData.StageId) then
        return
    end
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    if stageInfo.Type == XDataCenter.FubenManager.StageType.Expedition and XDataCenter.ExpeditionManager.GetIfBackMain() then
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionOnClose"))
        return
    end
    self:Close()
end

function XUiSettleLose:OnClickBtnRestart()
    self:Close()

    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    if stageInfo.Type == XDataCenter.FubenManager.StageType.BabelTower then
        if XLuaUiManager.IsUiLoad("UiBabelTowerSelectDiffcult") then
            XLuaUiManager.Remove("UiBabelTowerSelectDiffcult")
        end

        local curStageId, curTeamId, curStageGuideId, teamList, challengeBuffList, supportBuffList, captainPos, curStageLevel, firstFightPos = XDataCenter.FubenBabelTowerManager.GetCurStageInfo()
        XDataCenter.FubenBabelTowerManager.SelectBabelTowerStage(curStageId, curStageGuideId, teamList, challengeBuffList, supportBuffList, function()
            XDataCenter.FubenManager.EnterBabelTowerFight(curStageId, teamList, captainPos, firstFightPos)
        end, curStageLevel, curTeamId)
    elseif stageInfo.Type == XDataCenter.FubenManager.StageType.PracticeBoss then
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

    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    if stageInfo.Type == XDataCenter.FubenManager.StageType.BabelTower then
        -- 点击降低难度后不需要打开选择难度页签
        XDataCenter.FubenBabelTowerManager.SetNeedShowUiDifficult(false)
    end
    self:Close()
end 
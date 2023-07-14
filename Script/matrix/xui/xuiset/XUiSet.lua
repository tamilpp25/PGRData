local XUiInstructionMonster = require("XUi/XUiSet/XUiInstructionMonster")
local XUiCombatTask = require("XUi/XUiSet/XUiCombatTask")
local XUiInstruction = require("XUi/XUiSet/XUiInstruction")

local XUiPanelGraphicsSetPc = require("XUi/XUiSet/XUiPanelGraphicsSetPc")
local XUiPanelAccountSetPc = require("XUi/XUiSet/XUiPanelAccountSetPc")
local XUiPanelOtherSetPc = require("XUi/XUiSet/XUiPanelOtherSetPc")
local XUiPanelFightSetPc = require("XUi/XUiSet/XUiPanelFightSetPc")

local XUiSet = XLuaUiManager.Register(XLuaUi, "UiSet")

local PANEL_INDEX = {
    CombatTask = 1,
    Instruction = 2,
    Sound = 3,
    Graphics = 4,
    Fight = 5,
    Push = 6,
    Account = 7,
    Other = 8,
    Download = 9,
    SpecialTrain = 10,
}

local CLICK_INTERVAL = 0.3          -- 点击间隔
local MULTI_CLICK_COUNT_LIMIT = 5    -- 最大点击数

function XUiSet:OnAwake()
    XTool.InitUiObject(self)
    self.BtnRestart.CallBack = function() self:OnBtnRestart() end
    self.BtnDefault.CallBack = function() self:OnBtnDefaultClick() end
    self.BtnSave.CallBack = function() self:OnBtnSaveClick() end
    self.BtnRetreat.CallBack = function() self:OnBtnRetreat() end
    self.BtnInfoTip.CallBack = function() self:OnBtnInfoTip() end
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end

    local multiClickHelper = require("XUi/XUiCommon/XUiMultClickHelper").New(self, CLICK_INTERVAL, MULTI_CLICK_COUNT_LIMIT)
    self.MultiClickHelper = multiClickHelper
    self.LastOperationType = CS.XInputManager.CurOperationType
end

function XUiSet:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FIGHT_FINISH then
        self:Close()
    elseif self.CurShowIndex == PANEL_INDEX.Fight and evt == CS.XEventId.EVENT_CUSTOM_UI_SCHEME_CHANGED then
        -- 由于C#派发的事件无法触发红点系统绑定的监听，因此需要作出转换
        XEventManager.DispatchEvent(XEventId.EVENT_CUSTOM_UI_SCHEME_CHANGED)
    elseif evt == XEventId.EVENT_SETTING_KEYBOARD_KEY_CHANGED then
        if self.SubPanels[PANEL_INDEX.Fight] then
            self.SubPanels[PANEL_INDEX.Fight]:RefreshGridList(..., true)
        end
    end
end

function XUiSet:OnGetEvents()
    return { XEventId.EVENT_FIGHT_FINISH, CS.XEventId.EVENT_CUSTOM_UI_SCHEME_CHANGED, XEventId.EVENT_SETTING_KEYBOARD_KEY_CHANGED }
end

function XUiSet:OnStart(isFight, panelIndex)
    self.IsFight = isFight

    local stageType
    local beginData = XDataCenter.FubenManager.GetFightBeginData()
    if beginData and beginData.StageId then
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(beginData.StageId)
        if stageInfo then
            stageType = stageInfo.Type
        end
    end

    --区分战斗中设置和主页面设置内容
    if self.IsFight then
        self.BtnMainUi.gameObject:SetActiveEx(false)
        self.PanelAsset.gameObject:SetActiveEx(false)
        self.BtnGraphics.gameObject:SetActiveEx(false)
        self.BtnInfoTip.gameObject:SetActiveEx(false)
        self.BtnCombatTask.gameObject:SetActiveEx(CS.XFight.IsCombatTaskActivate)
        self.BtnDownload.gameObject:SetActiveEx(false)
        self.BtnInstruction.gameObject:SetActiveEx(stageType ~= XDataCenter.FubenManager.StageType.Maverick)
        self.BtnAccount.gameObject:SetActiveEx(false)
        if XFubenConfigs.HasStageGamePlayDesc(stageType) then
            self.BtnSpecialTrain.gameObject:SetActiveEx(true)
            self.BtnSpecialTrain:SetNameByGroup(0, XFubenConfigs.GetStageGamePlayTitle(stageType))
            self.BtnInstruction.gameObject:SetActiveEx(false)
        else
            self.BtnSpecialTrain.gameObject:SetActiveEx(false)
        end
    else
        self.BtnMainUi.gameObject:SetActiveEx(true)
        self.PanelAsset.gameObject:SetActiveEx(true)
        self.BtnGraphics.gameObject:SetActiveEx(true)
        self.BtnInstruction.gameObject:SetActiveEx(false)
        self.BtnRetreat.gameObject:SetActiveEx(false)
        self.BtnInfoTip.gameObject:SetActiveEx(true)
        self.BtnCombatTask.gameObject:SetActiveEx(false)
        self.BtnDownload.gameObject:SetActiveEx(CS.XInfo.IsDlcBuild and XDataCenter.DlcManager.HasDlcList())
        self.BtnSpecialTrain.gameObject:SetActiveEx(false)
        self.BtnAccount.gameObject:SetActiveEx(true)
    end

    if self.IsFight then
        if CS.XFight.IsRunning then
            CS.XFight.Instance:Pause()
            XDataCenter.FightWordsManager.Pause()
        end
        -- int index = CS.XFight.GetClientRole().Npc.Index;
        -- Portraits[index].Select();
        -- XUiAnimationManager.PlayUi(Ui, ANIM_BEGIN, null, null);
        -- TxtScheme.text = XCustomUi.Instance.SchemeName;
    end

    self.IsStartAnimCommon = true
    self.IsStartAnimOther = true
    self.SubPanels = {}
    if not self.IsFight then
        self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    end
    local tabGroup = {
        [PANEL_INDEX.CombatTask] = self.BtnCombatTask,
        [PANEL_INDEX.Instruction] = self.BtnInstruction,
        [PANEL_INDEX.Sound] = self.BtnVoice,
        [PANEL_INDEX.Graphics] = self.BtnGraphics,
        [PANEL_INDEX.Fight] = self.BtnFight,
        [PANEL_INDEX.Push] = self.BtnPush,
        [PANEL_INDEX.Other] = self.BtnOther,
        [PANEL_INDEX.Download] = self.BtnDownload,
        [PANEL_INDEX.SpecialTrain] = self.BtnSpecialTrain,
        [PANEL_INDEX.Account] = self.BtnAccount
    }
    self.PanelTabToggles:Init(tabGroup, function(index) self:SwitchSubPanel(index) end)
    local defaultIndex
    if self.IsFight then
        if CS.XFight.IsCombatTaskActivate then
            defaultIndex = panelIndex or PANEL_INDEX.CombatTask
        elseif stageType == XDataCenter.FubenManager.StageType.Maverick then
            defaultIndex = panelIndex or PANEL_INDEX.Sound
        elseif XFubenConfigs.HasStageGamePlayDesc(stageType) then
            defaultIndex = panelIndex or PANEL_INDEX.SpecialTrain
        else
            defaultIndex = panelIndex or PANEL_INDEX.Instruction
        end
    else
        defaultIndex = panelIndex or PANEL_INDEX.Sound
    end
    self.PanelTabToggles:SelectIndex(defaultIndex)
    self.TipTitle = CS.XTextManager.GetText("TipTitle")
    self.TipContent = CS.XTextManager.GetText("SettingCheckSave")

    XRedPointManager.AddRedPointEvent(self.BtnFight, self.OnCheckFightSetNews, self, { XRedPointConditions.Types.CONDITION_MAIN_SET })
    CS.XInputManager.SetCurOperationType(CS.XOperationType.System)
    CS.XPc.XCursorHelper.ForceResponse = true
end

--战斗页签红点（自定义按键冲突）
function XUiSet:OnCheckFightSetNews(count)
    self.BtnFight:ShowReddot(count >= 0)
end

function XUiSet:OnDestroy()
    if self.SubPanels[PANEL_INDEX.Fight] then
        self.SubPanels[PANEL_INDEX.Fight]:OnDestroy()
    end

    if self.Timer ~= nil then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end

    if self.MultiClickHelper then
        self.MultiClickHelper:OnDestroy()
    end

    --子panel中如果有event事件，不清除会有问题
    --每次打开Account，都会重新生成子panel
    if self.SubPanels[PANEL_INDEX.Account] then
        self.SubPanels[PANEL_INDEX.Account]:OnDestroy()
    end

    CS.XInputManager.SetCurOperationType(self.LastOperationType)
    CS.XPc.XCursorHelper.ForceResponse = false
end

function XUiSet:OnDisable()
    if self.CurShowIndex and self.SubPanels[self.CurShowIndex] then
        self.SubPanels[self.CurShowIndex]:HidePanel()
    end
    if self.IsFight then
        if CS.XFight.IsRunning then
            CS.XFight.Instance:Resume()
            XDataCenter.FightWordsManager.Resume()
        end
    end

    if self.Timer ~= nil then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end

    if self.MultiClickHelper then
        self.MultiClickHelper:OnDisable()
    end
end

function XUiSet:OnEnable()
    if self.MultiClickHelper then
        self.MultiClickHelper:OnEnable()
    end
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
    self.Timer = XScheduleManager.ScheduleForever(function()
        if self.MultiClickHelper then
            local dt = CS.UnityEngine.Time.deltaTime
            self.MultiClickHelper:Update(dt)
        end
    end, 0)

    if self.CurShowIndex and self.SubPanels[self.CurShowIndex] then
        self.SubPanels[self.CurShowIndex]:ShowPanel()
    end
end

function XUiSet:OnBtnSaveClick()
    self:Save()
    XUiManager.TipText("SettingSave")
end

function XUiSet:OnBtnRetreat()
    local title = CS.XTextManager.GetText("TipTitle")
    local content = CS.XTextManager.GetText("FightExitMsg")
    local confirmCb = function()
        if CS.XFight.IsRunning then
            CS.XFight.Instance.AutoExitFight = true
            CS.XFight.Instance:Exit(true)
        end
        self:Close()
    end
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, confirmCb)
end

function XUiSet:OnBtnRestart()
    local restartData = self:GetReStartData()
    if not restartData.IsCanRestart then
        XUiManager.TipErrorWithKey("TheatreNotRestartTips")
        return
    end
    local title = CS.XTextManager.GetText("TipTitle")
    local content = CS.XTextManager.GetText("FightRestartMsg")
    local cb = function()
        self:Close()
        XLuaUiManager.Open("UiLoading", LoadingType.Fight)
    end
    local confirmCb = function()
        if CS.XFight.IsRunning then
            CS.XFight.Instance:Restart(cb)
            XDataCenter.FightWordsManager.Stop(true)
        end
    end
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, confirmCb)
end

function XUiSet:OnBtnDefaultClick()
    self.SubPanels[self.SelectedIndex]:ResetToDefault()
end

function XUiSet:OnBtnBackClick()
    self:CheckSave(function()
        self:Close()
    end)
end

function XUiSet:OnBtnMainUiClick()
    self:CheckSave(function()
        XLuaUiManager.RunMain()
    end)
end

function XUiSet:OnBtnInfoTip()
    self.MultiClickHelper:Click()
end

function XUiSet:OnBtnUserAgreement()
    XUiManager.OpenPopWebview(CS.XGame.ClientConfig:GetString("UserAgreementUrl"))
end

function XUiSet:OnBtnPrivacyPolicy()
    XUiManager.OpenPopWebview(CS.XGame.ClientConfig:GetString("PrivacyPolicyUrl"))
end

--多点回调
function XUiSet:OnMultClick(clickTimes)
    if clickTimes >= MULTI_CLICK_COUNT_LIMIT then
        local content = CS.XInfo.Identifier
        XUiManager.UiFubenDialogTip("信息提示", content);
    end
end

function XUiSet:InitSubPanel(index)
    if index == PANEL_INDEX.CombatTask then
        if self.PanelCombatTaskObj == nil then
            self.PanelCombatTaskObj = self.PanelCombatTask:LoadPrefab(XUiConfigs.GetComponentUrl("UiSetCombatTask"))
        end
        self.SubPanels[PANEL_INDEX.CombatTask] = XUiCombatTask.New(self.PanelCombatTaskObj)
    elseif index == PANEL_INDEX.Instruction then

        --口袋妖怪怪物类型战中设置特殊处理
        local role = CS.XFight.GetActivateClientRole()
        local isMonsterFight = role and role.RoleData.CustomNpc ~= nil
        if isMonsterFight then

            local monsterUi = self.PanelInstruction:LoadPrefab(XUiConfigs.GetComponentUrl("UiSetPanelInstructionMonster"))
            self.SubPanels[PANEL_INDEX.Instruction] = XUiInstructionMonster.New(monsterUi)

        else

            if self.PanelInstructionObj == nil then
                self.PanelInstructionObj = self.PanelInstruction:LoadPrefab(XUiConfigs.GetComponentUrl("UiSetPanelInstruction"))
            end
            self.SubPanels[PANEL_INDEX.Instruction] = XUiInstruction.New(self.PanelInstructionObj)

        end

    elseif index == PANEL_INDEX.Sound then
        if self.PanelVoiceSetObj == nil then
            self.PanelVoiceSetObj = self.PanelVoiceSet:LoadPrefab(XUiConfigs.GetComponentUrl("UiSetPanelVoiceSet"))
        end
        self.SubPanels[PANEL_INDEX.Sound] = XUiPanelVoiceSet.New(self.PanelVoiceSetObj, self)
    elseif index == PANEL_INDEX.Graphics then
        if self.PanelGraphicsSetObj == nil then
            if XDataCenter.UiPcManager.IsPc() then
                self.PanelGraphicsSetObj = self.PanelGraphicsSet:LoadPrefab(XUiConfigs.GetComponentUrl("UiSetPanelGraphicsSetPC"))
            else
                self.PanelGraphicsSetObj = self.PanelGraphicsSet:LoadPrefab(XUiConfigs.GetComponentUrl("UiSetPanelGraphicsSet"))
            end
        end
        if XDataCenter.UiPcManager.IsPc() then
            self.SubPanels[PANEL_INDEX.Graphics] = XUiPanelGraphicsSetPc.New(self.PanelGraphicsSetObj, self)
        else
            self.SubPanels[PANEL_INDEX.Graphics] = XUiPanelGraphicsSet.New(self.PanelGraphicsSetObj, self)
        end
    elseif index == PANEL_INDEX.Fight then
        if self.PanelFightSetObj == nil then
            -- if XDataCenter.UiPcManager.IsPc() then
                self.PanelFightSetObj = self.PanelFightSet:LoadPrefab(XUiConfigs.GetComponentUrl("UiSetPanelFightSetPC"))
            -- else
                -- self.PanelFightSetObj = self.PanelFightSet:LoadPrefab(XUiConfigs.GetComponentUrl("UiSetPanelFightSet"))
            -- end
        end
        -- if XDataCenter.UiPcManager.IsPc() then
            self.SubPanels[PANEL_INDEX.Fight] = XUiPanelFightSetPc.New(self.PanelFightSetObj, self)
        -- else
        --     self.SubPanels[PANEL_INDEX.Fight] = XUiPanelFightSet.New(self.PanelFightSetObj, self)
        -- end
    elseif index == PANEL_INDEX.Push then
        if self.PanelPushSetObj == nil then
            self.PanelPushSetObj = self.PanelPushSet:LoadPrefab(XUiConfigs.GetComponentUrl("UiSetPanelPushSet"))
        end
        self.SubPanels[PANEL_INDEX.Push] = XUiPanelPushSet.New(self.PanelPushSetObj, self)
    elseif index == PANEL_INDEX.Other then
        if self.PanelOtherObj == nil then
            if XDataCenter.UiPcManager.IsPc() then
                self.PanelOtherObj = self.PanelOther:LoadPrefab(XUiConfigs.GetComponentUrl("UiSetPanelOtherPC"))
            else
                self.PanelOtherObj = self.PanelOther:LoadPrefab(XUiConfigs.GetComponentUrl("UiSetPanelOther"))
            end
        end
        if XDataCenter.UiPcManager.IsPc() then
            self.SubPanels[PANEL_INDEX.Other] = XUiPanelOtherSetPc.New(self.PanelOtherObj, self)
        else
            self.SubPanels[PANEL_INDEX.Other] = XUiPanelOtherSet.New(self.PanelOtherObj, self)
        end
    elseif index == PANEL_INDEX.Download then
        if self.PanelDownloadObj == nil then
            self.PanelDownloadObj = self.PanelDownload:LoadPrefab(XUiConfigs.GetComponentUrl("UiSetPanelDownload"))
        end
        local XUiPanelDownloadSet = require("XUi/XUiSet/XUiPanelDownloadSet")
        self.SubPanels[PANEL_INDEX.Download] = XUiPanelDownloadSet.New(self.PanelDownloadObj, self)
    elseif index == PANEL_INDEX.SpecialTrain then
        if self.PanelSpecialTrainObj == nil then
            self.PanelSpecialTrainObj = self.PanelSpecialTrain:LoadPrefab(XUiConfigs.GetComponentUrl("PanelSpecialTrain"))
        end
        local XUiPanelSpecialTrain = require("XUi/XUiSet/XUiPanelSpecialTrain")
        self.SubPanels[PANEL_INDEX.SpecialTrain] = XUiPanelSpecialTrain.New(self.PanelSpecialTrainObj, self)
    elseif index == PANEL_INDEX.Account then
        if self.PanelAccountObj == nil then
            if XDataCenter.UiPcManager.IsPc() then
                self.PanelAccountObj = self.PanelAccountSet:LoadPrefab(XUiConfigs.GetComponentUrl("UiSetPanelAccountPC"))
            else
                self.PanelAccountObj = self.PanelAccountSet:LoadPrefab(XUiConfigs.GetComponentUrl("UiSetPanelAccount"))
            end
        end
        if XDataCenter.UiPcManager.IsPc() then
            self.SubPanels[PANEL_INDEX.Account] = XUiPanelAccountSetPc.New(self.PanelAccountObj, self)
        else
            self.SubPanels[PANEL_INDEX.Account] = XUiPanelAccountSet.New(self.PanelAccountObj, self)
        end
    end
end

function XUiSet:SwitchSubPanel(index)

    if not self.SubPanels[index] then
        self:InitSubPanel(index)
    end

    self:CheckSave(function()
        self:ShowSubPanel(index)
    end)
    self:PlayAnimation("AnimQieHuanEnable")
end

function XUiSet:ShowSubPanel(index)
    if index == PANEL_INDEX.Instruction or index == PANEL_INDEX.CombatTask or index == PANEL_INDEX.Download or index == PANEL_INDEX.Account then
        self.BtnSave.gameObject:SetActiveEx(false)
        self.BtnDefault.gameObject:SetActiveEx(false)
    elseif index ~= PANEL_INDEX.SpecialTrain then -- 特殊显示玩法, 不由此控制按钮, 否则按钮显示异常
        self.BtnSave.gameObject:SetActive(true)
        self.BtnDefault.gameObject:SetActive(true)
        if self.IsStartAnimCommon then
            self.IsStartAnimCommon = false
            self.BtnDefaultAnmation:EnableAnim(XUiButtonState.Normal)
            self.BtnSaveAnmation:EnableAnim(XUiButtonState.Normal)
        end
    end

    self.SelectedIndex = index
    for i, panel in pairs(self.SubPanels) do
        if (i == index) then
            self.CurShowIndex = index
            panel:ShowPanel()
        else
            panel:HidePanel()
        end
    end
    self.BtnRetreat.gameObject:SetActiveEx(self.IsFight)

    local restartData = self:GetReStartData()
    local showRestartIndex = (index == PANEL_INDEX.Instruction) or (index == PANEL_INDEX.CombatTask)
    self.BtnRestart:SetNameByGroup(0, restartData.BtnName)
    self.BtnRestart.gameObject:SetActiveEx(showRestartIndex and CS.XFight.Restartable and not CS.XFight.AlreadySettled)

    if index == PANEL_INDEX.SpecialTrain then
        local stageType = XDataCenter.FubenManager.GetCurrentStageType()
        local btnVisible = XFubenConfigs.GetStageGamePlayBtnVisible(stageType)
        self:SetBtnVisibleByCfg(self.BtnDefault, btnVisible.BtnDefault)
        self:SetBtnVisibleByCfg(self.BtnRetreat, btnVisible.BtnRetreat)
        self:SetBtnVisibleByCfg(self.BtnRestart, btnVisible.BtnRestart)
        self:SetBtnVisibleByCfg(self.BtnSave, btnVisible.BtnSave)
        if btnVisible.BtnRestart == 1 and not CS.XFight.Restartable then
            XLog.Warning("[XUiSet] StageGamePlayDesc配置显示了\"重新开始\"，但关卡表没配置可重新开始，请检查")
        end
    end
end

function XUiSet:Save()
    self.SubPanels[self.SelectedIndex]:SaveChange()
end

function XUiSet:Cancel()
    self.SubPanels[self.SelectedIndex]:CancelChange()
end

function XUiSet:CheckUnSaveData()
    if self.SelectedIndex and self.SubPanels[self.SelectedIndex]:CheckDataIsChange() then
        return true
    else
        return false
    end
end

function XUiSet:UpdateSpecialScreenOff()
    if self.SafeAreaContentPane then
        self.SafeAreaContentPane:UpdateSpecialScreenOff()
    end
end

function XUiSet:CheckSave(cb)
    local isUnSave = self:CheckUnSaveData()
    if isUnSave then
        local cancelCb = function()
            self:Cancel()
            if cb then cb() end
        end
        local confirmCb = function()
            self:Save()
            if cb then cb() end
        end
        self:TipDialog(cancelCb, confirmCb)
    else
        if cb then cb() end
    end
end

function XUiSet:TipDialog(cancelCb, confirmCb)
    XLuaUiManager.Open("UiDialog", self.TipTitle, self.TipContent, XUiManager.DialogType.Normal, cancelCb, confirmCb)
end

-- 获取重开数据
function XUiSet:GetReStartData()
    local result = {
        BtnName = XUiHelper.GetText("CommonRestartBtnName"),
        IsCanRestart = true,
        NotRestartTips = ""
    }
    if not CS.XFight.IsRunning then return result end
    local stageId = CS.XFight.Instance.FightData.StageId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    if stageInfo == nil then return result end
    if stageInfo.Type == XDataCenter.FubenManager.StageType.Theatre then
        local playableCount = XDataCenter.TheatreManager.GetCurrentAdventureManager():GetPlayableCount()
        result.BtnName = XUiHelper.GetText("TheatreRestartBtnName", playableCount)
        result.IsCanRestart = playableCount > 0
        result.NotRestartTips = XUiHelper.GetText("TheatreNotRestartTips")
    end
    return result
end

function XUiSet:SetBtnVisibleByCfg(btn, value)
    btn.gameObject:SetActiveEx(value == 1)
end
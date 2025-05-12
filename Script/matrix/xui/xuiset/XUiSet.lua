local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiInstructionMonster = require("XUi/XUiSet/XUiInstructionMonster")
local XUiInstruction = require("XUi/XUiSet/XUiInstruction")
local XUiInstructionLink = require("XUi/XUiSet/XUiInstructionLink")
local XUiInstructionMechanism = require('XUi/XUiSet/XUiInstructionMechanism')
local XUiPanelGraphicsSetPc = require("XUi/XUiSet/XUiPanelGraphicsSetPc")
local XUiPanelOtherSetPc = require("XUi/XUiSet/XUiPanelOtherSetPc")
local XUiPanelFightSetPc = require("XUi/XUiSet/XUiPanelFightSetPc")
local XUiPanelAudioSet = require("XUi/XUiSet/XUiPanelAudioSet")
local XUiPanelPushSet = require("XUi/XUiSet/XUiPanelPushSet")
local XUiPanelOtherSet = require("XUi/XUiSet/XUiPanelOtherSet")
local XUiPanelGraphicsSet = require("XUi/XUiSet/XUiPanelGraphicsSet")

---@class XUiSet:XLuaUi
local XUiSet = XLuaUiManager.Register(XLuaUi, "UiSet")

local PANEL_INDEX = {
    Instruction = 1,
    Sound = 2,
    Graphics = 3,
    Fight = 4,
    Push = 5,
    Other = 6,
    Download = 7,
    SpecialTrain = 8,
    DlcHunt = 9,
    GeneralSkill = 10,
    FpsGame = 11,
}
local CLICK_INTERVAL = 0.3          -- 点击间隔
local MULTI_CLICK_COUNT_LIMIT = 5    -- 最大点击数
local DisableInstructionStageType = {
    [XDataCenter.FubenManager.StageType.Maverick] = true,
    [XDataCenter.FubenManager.StageType.Maverick2] = true,
    [XDataCenter.FubenManager.StageType.BrillientWalk] = true,
    [XEnumConst.FuBen.StageType.TaikoMaster] = true,
    [XEnumConst.FuBen.StageType.FpsGame] = true,
    [XEnumConst.FuBen.StageType.FavorabilityStory] = true,
}
--检查是否需要显示角色说明面板
local function CheckInstructionEnable(stageType)
    if CS.XFightInterface.IsDLC then
        return false
    end

    -- 主线2的提示按钮
    local stageId = CS.XFight.Instance.FightData.StageId
    local agency = XMVCA:GetAgency(ModuleId.XMainLine2)
    if agency:IsStageExit(stageId) then
        return agency:IsShowFightInstruction(stageId)
    end

    if stageType == XMVCA.XFuben.StageType.StageMemory then
        if XMVCA.XStageMemory:IsDisableInstruction(stageId) then
            return false
        end
    end

    local DisableInstruction = DisableInstructionStageType[stageType] or false
    return not DisableInstruction
end

local function CheckGeneralSkillEnable()
    if CS.XFightInterface.IsDLC then
        return false
    end
    
    for i, v in pairs(CS.XFight.Instance.FightData.EventIds) do
        for id, generalSkillCfg in pairs(XMVCA.XCharacter:GetModelCharacterGeneralSkill()) do
            if generalSkillCfg.FightEventId ==  v then
                return true
            end
        end
    end
    return false
end

function XUiSet:OnAwake()
    XTool.InitUiObject(self)
    self.BtnRestart.CallBack = function() self:OnBtnRestart() end
    self.BtnDefault.CallBack = function() self:OnBtnDefaultClick() end
    self.BtnSave.CallBack = function() self:OnBtnSaveClick() end
    self.BtnRetreat.CallBack = function() self:OnBtnRetreat() end
    self.BtnInfoTip.CallBack = function() self:OnBtnInfoTip() end
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end

    local multiClickHelper = require("XUi/XUiCommon/XUiMultClickHelper").New(self, CLICK_INTERVAL, MULTI_CLICK_COUNT_LIMIT)
    self.MultiClickHelper = multiClickHelper
    CS.XInputManager.SetCurInputMap(CS.XInputMapId.System)
end

function XUiSet:OnStart(isFight, panelIndex, secondIndex)
    self.IsFight = isFight
    self.SecondIndex = secondIndex

    local stageType
    local beginData = XDataCenter.FubenManager.GetFightBeginData()
    if beginData and beginData.StageId then
        stageType = XMVCA.XFuben:GetStageType(beginData.StageId)
    end

    --区分战斗中设置和主页面设置内容
    self:InitLeftTagPanel(self.IsFight, stageType)

    if self.IsFight then
        if CS.XFight.IsRunning then
            CS.XFight.Instance:Pause()
            XDataCenter.FightWordsManager.Pause()
            self:AddRecordStr("点击暂停")
        end
        -- int index = CS.XFight.GetClientRole().Npc.Index;
        -- Portraits[index].Select();
        -- XUiAnimationManager.PlayUi(Ui, ANIM_BEGIN, null, null);
        if CS.StatusSyncFight.XFightClient.FightInstance then
            CS.StatusSyncFight.XFightClient.FightInstance:OnPauseForClient()
        end
    end

    self.IsStartAnimCommon = true
    self.IsStartAnimOther = true
    self.SubPanels = {}
    if not self.IsFight then
        self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    end
    self:InitPanelAsset(self.IsFight)
    local defaultIndex
    if self.IsFight then
        if XFightUtil.IsDlcOnline() then
            defaultIndex = panelIndex or PANEL_INDEX.DlcHunt
        elseif not CheckInstructionEnable(stageType) then
            defaultIndex = panelIndex or PANEL_INDEX.Sound
        elseif XFubenConfigs.HasStageGamePlayDesc(stageType) then
            defaultIndex = panelIndex or PANEL_INDEX.SpecialTrain
        elseif stageType == XEnumConst.FuBen.StageType.FpsGame then
            defaultIndex = panelIndex or PANEL_INDEX.FpsGame
        else
            defaultIndex = panelIndex or PANEL_INDEX.Instruction
        end
    else
        defaultIndex = panelIndex or PANEL_INDEX.Sound
    end
    self.PanelTabToggles:SelectIndex(defaultIndex)
    self.TipTitle = CS.XTextManager.GetText("TipTitle")
    self.TipContent = CS.XTextManager.GetText("SettingCheckSave")

    self:AddRedPointEvent(self.BtnFight, self.OnCheckFightSetNews, self, { XRedPointConditions.Types.CONDITION_MAIN_SET })
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
        self.SubPanels[self.CurShowIndex]:Open()
    end
    CS.XJoystickLSHelper.ForceResponse = true
end

function XUiSet:OnDisable()
    if self.CurShowIndex and self.SubPanels[self.CurShowIndex] then
        self.SubPanels[self.CurShowIndex]:Close()
    end
    if self.IsFight then
        if CS.XFight.IsRunning then
            CS.XFight.Instance:Resume()
            XDataCenter.FightWordsManager.Resume()
        end
        if CS.StatusSyncFight.XFightClient.FightInstance then
            CS.StatusSyncFight.XFightClient.FightInstance:OnResumeForClient()
        end
    end

    if self.Timer ~= nil then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end

    if self.MultiClickHelper then
        self.MultiClickHelper:OnDisable()
    end
    CS.XJoystickLSHelper.ForceResponse = false
end

function XUiSet:OnDestroy()
    if self.Timer ~= nil then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end

    if self.MultiClickHelper then
        self.MultiClickHelper:OnDestroy()
    end
    CS.XInputManager.SetCurInputMap(CS.XInputManager.BeforeInputMapID)
end

function XUiSet:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FIGHT_FINISH then
        self.Super.Close(self)
    elseif self.CurShowIndex == PANEL_INDEX.Fight and evt == CS.XEventId.EVENT_CUSTOM_UI_SCHEME_CHANGED then
        -- 由于C#派发的事件无法触发红点系统绑定的监听，因此需要作出转换
        XEventManager.DispatchEvent(XEventId.EVENT_CUSTOM_UI_SCHEME_CHANGED)
    elseif evt == XEventId.EVENT_SETTING_KEYBOARD_KEY_CHANGED then
        if self.SubPanels[PANEL_INDEX.Fight] then
            self.SubPanels[PANEL_INDEX.Fight]:RefreshGridList(..., true)
        end
    elseif evt == CS.XEventId.EVENT_VIDEO_PLAYER_STATUS_PLAYEND then
        if self.SelectedIndex == PANEL_INDEX.FpsGame then
            ---@type XUiPanelFpsGameSet
            local fps = self.SubPanels[PANEL_INDEX.FpsGame]
            if fps then
                fps:OnVideoPlayEnd()
            end
        end
    end
end

function XUiSet:OnGetEvents()
    return { XEventId.EVENT_FIGHT_FINISH, CS.XEventId.EVENT_CUSTOM_UI_SCHEME_CHANGED, XEventId.EVENT_SETTING_KEYBOARD_KEY_CHANGED, CS.XEventId.EVENT_VIDEO_PLAYER_STATUS_PLAYEND }
end

--region Data
function XUiSet:GetRetreatTitleAndContent()
    local title = CS.XTextManager.GetText("TipTitle")
    local content = CS.XTextManager.GetText("FightExitMsg")
    if CS.XFightInterface.IsDLC then
        return title, content
    end
    local stageId = CS.XFight.Instance.FightData.StageId
    local stageType = XMVCA.XFuben:GetStageType(stageId)
    if stageType == nil then
        return title, content
    end

    local fightReboot = CS.XFight.Instance.FightReboot
    -- 肉鸽2.0兼容不可重开
    if stageType == XDataCenter.FubenManager.StageType.BiancaTheatre and fightReboot.Available then
        local itemId = fightReboot.RebootItemId
        local itemName = XItemConfigs.GetItemNameById(itemId)
        local count = XDataCenter.ItemManager.GetCount(itemId)
        title = XBiancaTheatreConfigs.GetClientConfig("RetreatTitle")
        content = string.format(XBiancaTheatreConfigs.GetClientConfig("RetreatDesc"), itemName, count, itemName)
    end

    return title, content
end

function XUiSet:GetReStartTitleAndContent()
    local title = CS.XTextManager.GetText("TipTitle")
    local content = CS.XTextManager.GetText("FightRestartMsg")
    local stageId = CS.XFight.Instance.FightData.StageId
    local stageType = XMVCA.XFuben:GetStageType(stageId)
    if stageType == nil then
        return title, content
    end

    local fightReboot = CS.XFight.Instance.FightReboot
    -- 肉鸽2.0兼容不可重开
    if stageType == XDataCenter.FubenManager.StageType.BiancaTheatre and fightReboot.Available then
        local itemId = fightReboot.RebootItemId
        local itemName = XItemConfigs.GetItemNameById(itemId)
        local consumeCount = fightReboot.ConsumeCount
        local count = XDataCenter.ItemManager.GetCount(itemId)
        title = XBiancaTheatreConfigs.GetClientConfig("RebootTitle")
        content = string.format(XBiancaTheatreConfigs.GetClientConfig("RebootDesc"), itemName, count, itemName, consumeCount)
        -- 肉鸽3.0兼容不可重开
    elseif stageType == XDataCenter.FubenManager.StageType.Theatre3 and fightReboot.Available then
        ---@type XTheatre3Agency
        local agency = XMVCA:GetAgency(ModuleId.XTheatre3)
        local itemId = XEnumConst.THEATRE3.Theatre3InnerCoin
        local count = XDataCenter.ItemManager.GetCount(itemId)
        local itemName = XDataCenter.ItemManager.GetItemName(itemId)
        local consumeCount = agency:GetRebootCost(CS.XFight.Instance.FightData.RebootId)
        title = XBiancaTheatreConfigs.GetClientConfig("RebootTitle")
        content = string.format(XBiancaTheatreConfigs.GetClientConfig("RebootDesc"), itemName, count, itemName, consumeCount)
    elseif stageType == XDataCenter.FubenManager.StageType.Theatre4 and fightReboot.Available then
        -- 肉鸽4.0兼容不可重开
        ---@type XTheatre4Agency
        local agency = XMVCA:GetAgency(ModuleId.XTheatre4)
        local count = agency:GetGoldCount()
        local itemName = agency:GetGoldName()
        local consumeCount = agency:GetFubenRestartCostById(CS.XFight.Instance.FightData.RebootId)
        title = XBiancaTheatreConfigs.GetClientConfig("RebootTitle")
        content = string.format(XBiancaTheatreConfigs.GetClientConfig("RebootDesc"), itemName, count, itemName, consumeCount)
    end

    return title, content
end

-- 获取重开数据
function XUiSet:GetReStartData()
    local result = {
        BtnName = XUiHelper.GetText("CommonRestartBtnName"),
        IsCanRestart = true,
        NotRestartTips = "",
        RestartTipsDescKey = nil,
    }
    if not CS.XFight.IsRunning then return result end
    local stageId = CS.XFight.Instance.FightData.StageId
    local stageType = XMVCA.XFuben:GetStageType(stageId)
    if stageType == nil then return result end

    local fightReboot = CS.XFight.Instance.FightReboot
    if stageType == XDataCenter.FubenManager.StageType.Theatre then
        local currentAdventureManager =  XDataCenter.TheatreManager.GetCurrentAdventureManager()
        if currentAdventureManager then
            local playableCount = currentAdventureManager:GetPlayableCount()
            result.BtnName = XUiHelper.GetText("TheatreRestartBtnName", playableCount)
            result.IsCanRestart = playableCount > 0
            result.NotRestartTips = XUiHelper.GetText("TheatreNotRestartTips")
        end
    elseif stageType == XDataCenter.FubenManager.StageType.BiancaTheatre then
        -- 肉鸽2.0兼容不可重开
        if fightReboot.Available then
            local itemId = fightReboot.RebootItemId
            local itemName = XItemConfigs.GetItemNameById(itemId)
            local consumeCount = fightReboot.ConsumeCount
            local count = XDataCenter.ItemManager.GetCount(itemId)
            result.BtnName = string.format("%s(%d/%d)", itemName, consumeCount, count)
            result.IsCanRestart = count >= consumeCount
            result.RestartTipsDescKey = "BiancaTheatreRestartTipsDesc"
        else
            result.IsCanRestart = false
        end
    elseif stageType == XDataCenter.FubenManager.StageType.Theatre3 then
        -- 肉鸽3.0兼容不可重开
        if fightReboot.Available then
            ---@type XTheatre3Agency
            local agency = XMVCA:GetAgency(ModuleId.XTheatre3)
            local itemId = XEnumConst.THEATRE3.Theatre3InnerCoin
            local count = XDataCenter.ItemManager.GetCount(itemId)
            local itemName = XDataCenter.ItemManager.GetItemName(itemId)
            local consumeCount = agency:GetRebootCost(CS.XFight.Instance.FightData.RebootId)
            result.BtnName = string.format("%s(%d/%d)", itemName, consumeCount, count)
            result.IsCanRestart = count >= consumeCount
            result.RestartTipsDescKey = "Theatre3RestartTipsDesc"
        else
            result.IsCanRestart = false
        end
    elseif stageType == XDataCenter.FubenManager.StageType.Theatre4 then
        -- 肉鸽4.0兼容不可重开
        if fightReboot.Available then
            ---@type XTheatre4Agency
            local agency = XMVCA:GetAgency(ModuleId.XTheatre4)
            local count = agency:GetGoldCount()
            local itemName = agency:GetRestartGoldName()
            local consumeCount = agency:GetFubenRestartCostById(CS.XFight.Instance.FightData.RebootId)
            result.BtnName = string.format("%s(%d/%d)", itemName, consumeCount, count)
            result.IsCanRestart = count >= consumeCount
            result.RestartTipsDescKey = "Theatre4RestartTipsDesc"
        else
            result.IsCanRestart = false
        end
    end
    return result
end

function XUiSet:UpdateSpecialScreenOff()
    if self.SafeAreaContentPane then
        self.SafeAreaContentPane:UpdateSpecialScreenOff()
    end
end

function XUiSet:Save()
    self.SubPanels[self.SelectedIndex]:SaveChange()
end

function XUiSet:Cancel()
    self.SubPanels[self.SelectedIndex]:CancelChange()
end
--endregion

--region Checker
function XUiSet:CheckUnSaveData()
    if self.SelectedIndex and self.SubPanels[self.SelectedIndex].CheckDataIsChange and self.SubPanels[self.SelectedIndex]:CheckDataIsChange() then
        return true
    else
        return false
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
--endregion

--region Ui - PanelAsset
function XUiSet:InitPanelAsset(isFight)
    if not isFight then
        self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    end
end
--endregion

--region Ui - LeftTagPanel
function XUiSet:InitLeftTagPanel(isFight, stageType)
    local tabGroup = {
        [PANEL_INDEX.Instruction] = self.BtnInstruction,
        [PANEL_INDEX.Sound] = self.BtnVoice,
        [PANEL_INDEX.Graphics] = self.BtnGraphics,
        [PANEL_INDEX.Fight] = self.BtnFight,
        [PANEL_INDEX.Push] = self.BtnPush,
        [PANEL_INDEX.Other] = self.BtnOther,
        [PANEL_INDEX.Download] = self.BtnDownload,
        [PANEL_INDEX.SpecialTrain] = self.BtnSpecialTrain,
        [PANEL_INDEX.DlcHunt] = self.BtnDlcHunt,
        [PANEL_INDEX.GeneralSkill] = self.BtnGeneralSkill,
        [PANEL_INDEX.FpsGame] = self.BtnFpsGame,
    }
    self.PanelTabToggles:Init(tabGroup, function(index)
        self:SwitchSubPanel(index)
    end)
    if isFight then
        self.BtnMainUi.gameObject:SetActiveEx(false)
        self.PanelAsset.gameObject:SetActiveEx(false)
        self.BtnGraphics.gameObject:SetActiveEx(false)
        self.BtnInfoTip.gameObject:SetActiveEx(false)
        self.BtnDownload.gameObject:SetActiveEx(false)
        self.BtnInstruction.gameObject:SetActiveEx(CheckInstructionEnable(stageType))
        self.BtnGeneralSkill.gameObject:SetActiveEx(CheckGeneralSkillEnable())
        if XFubenConfigs.HasStageGamePlayDesc(stageType) then
            self.BtnSpecialTrain.gameObject:SetActiveEx(true)
            self.BtnSpecialTrain:SetNameByGroup(0, XFubenConfigs.GetStageGamePlayTitle(stageType))
            self.BtnInstruction.gameObject:SetActiveEx(false)
        else
            self.BtnSpecialTrain.gameObject:SetActiveEx(false)
        end
        if XFightUtil.IsDlcOnline() then
            self.BtnDlcHunt.gameObject:SetActiveEx(true)
        else
            self.BtnDlcHunt.gameObject:SetActiveEx(false)
        end
        self.BtnFpsGame.gameObject:SetActiveEx(stageType == XEnumConst.FuBen.StageType.FpsGame)
    else
        self.BtnDlcHunt.gameObject:SetActiveEx(false)
        self.BtnMainUi.gameObject:SetActiveEx(true)
        self.PanelAsset.gameObject:SetActiveEx(true)
        self.BtnGraphics.gameObject:SetActiveEx(true)
        self.BtnInstruction.gameObject:SetActiveEx(false)
        self.BtnRetreat.gameObject:SetActiveEx(false)
        self.BtnInfoTip.gameObject:SetActiveEx(true)
        self.BtnDownload.gameObject:SetActiveEx(false)
        self.BtnSpecialTrain.gameObject:SetActiveEx(false)
        self.BtnGeneralSkill.gameObject:SetActiveEx(false)
        self.BtnFpsGame.gameObject:SetActiveEx(false)
        self:FpsGameSpecialShow()
    end
end
--endregion

--region Ui - SubPanel
function XUiSet:InitSubPanel(index)
    if index == PANEL_INDEX.Instruction then
        -- 主线2的关卡
        local stageId = CS.XFight.Instance.FightData.StageId
        local isMainLine2Stage = XMVCA:GetAgency(ModuleId.XMainLine2):IsStageExit(stageId)

        --口袋妖怪怪物类型战中设置特殊处理
        local role = CS.XFight.GetActivateClientRole()
        local isMonsterFight = role and role.RoleData.CustomNpc ~= nil
        
        local isLinkCraftActivityStage = XDataCenter.FubenManager.GetStageType(stageId) == XDataCenter.FubenManager.StageType.LinkCraftActivity
        local isMechanismActivityStage = XDataCenter.FubenManager.GetStageType(stageId) == XDataCenter.FubenManager.StageType.MechanismActivity
        if isMainLine2Stage then
            local isShowIntruction = XMVCA:GetAgency(ModuleId.XMainLine2):IsShowFightInstruction(stageId)
            if isShowIntruction then
                local btnName = XUiHelper.GetText("TipTitle")
                self.BtnInstruction:SetNameByGroup(0, btnName)
                local XUiInstructionMainLine = require("XUi/XUiSet/XUiInstructionMainLine")
                local prefabPath = XUiConfigs.GetComponentUrl("PanelInstructionMainLine")
                local prefab = self.PanelInstruction:LoadPrefab(prefabPath)
                self.SubPanels[PANEL_INDEX.Instruction] = XUiInstructionMainLine.New(prefab, self)
            end

        elseif isMonsterFight then
            local monsterUi = self.PanelInstruction:LoadPrefab(XUiConfigs.GetComponentUrl("UiSetPanelInstructionMonster"))
            self.SubPanels[PANEL_INDEX.Instruction] = XUiInstructionMonster.New(monsterUi, self)
        elseif isLinkCraftActivityStage then
            if self.PanelInstructionObj == nil then
                self.PanelInstructionObj = self.PanelInstruction:LoadPrefab(XUiConfigs.GetComponentUrl("PanelInstructionLink"))
            end
            self.SubPanels[PANEL_INDEX.Instruction] = XUiInstructionLink.New(self.PanelInstructionObj, self)
        elseif isMechanismActivityStage then
            if self.PanelInstructionObj == nil then
                self.PanelInstructionObj = self.PanelInstruction:LoadPrefab(XUiConfigs.GetComponentUrl("UiMechanismInstruction"))
            end
            self.SubPanels[PANEL_INDEX.Instruction] = XUiInstructionMechanism.New(self.PanelInstructionObj, self)
        else

            if self.PanelInstructionObj == nil then
                self.PanelInstructionObj = self.PanelInstruction:LoadPrefab(XUiConfigs.GetComponentUrl("UiSetPanelInstruction"))
            end
            self.SubPanels[PANEL_INDEX.Instruction] = XUiInstruction.New(self.PanelInstructionObj, self)

        end

    elseif index == PANEL_INDEX.Sound then
        if self.PanelVoiceSetObj == nil then
            self.PanelVoiceSetObj = self.PanelVoiceSet:LoadPrefab(XUiConfigs.GetComponentUrl("UiSetPanelVoiceSet"))
        end
        self.SubPanels[PANEL_INDEX.Sound] = XUiPanelAudioSet.New(self.PanelVoiceSetObj, self)
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
        --2.3版本键位直接用PC端预制和代码，有部分内容区分
        if self.PanelFightSetObj == nil then
            self.PanelFightSetObj = self.PanelFightSet:LoadPrefab(XUiConfigs.GetComponentUrl("UiSetPanelFightSetPC"))
        end
        self.SubPanels[PANEL_INDEX.Fight] = XUiPanelFightSetPc.New(self.PanelFightSetObj, self, self.SecondIndex)
        self.SecondIndex = nil
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

    elseif index == PANEL_INDEX.DlcHunt then
        if self.PanelDlcHuntObj == nil then
            self.PanelDlcHuntObj = self.PanelDlcHunt:LoadPrefab(XUiConfigs.GetComponentUrl("PanelDlcBoss"))
        end
        local XUiPanelDlcBoss = require("XUi/XUiSet/XUiPanelDlcBoss")
        self.SubPanels[PANEL_INDEX.DlcHunt] = XUiPanelDlcBoss.New(self.PanelDlcHuntObj, self)
    elseif index == PANEL_INDEX.GeneralSkill then
        if self.PanelGeneralSkillObj == nil then
            self.PanelGeneralSkillObj = self.PanelGeneralSkill:LoadPrefab(XUiConfigs.GetComponentUrl('PanelGeneralSkill'))
        end 
        local XUiPanelGeneralSkillInSet = require('XUi/XUiSet/XUiPanelGeneralSkillInSet')
        self.SubPanels[PANEL_INDEX.GeneralSkill] = XUiPanelGeneralSkillInSet.New(self.PanelGeneralSkillObj, self)
    elseif index == PANEL_INDEX.FpsGame then
        if not self.PanelFpsGameObj then
            self.PanelFpsGameObj = self.PanelFpsGame:LoadPrefab(XUiConfigs.GetComponentUrl('PanelFpsGame'))
        end
        self.SubPanels[PANEL_INDEX.FpsGame] = require("XUi/XUiSet/XUiPanelFpsGameSet").New(self.PanelFpsGameObj, self, self._IsHideFpsGameSetting)
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
    if index == PANEL_INDEX.Fight and self.SubPanels[PANEL_INDEX.Fight] and self.SubPanels[PANEL_INDEX.Fight]:IsPageTypeTouch() then
        self.BtnDefault.gameObject:SetActiveEx(false)
    elseif index == PANEL_INDEX.Instruction
            --or index == PANEL_INDEX.Download
            or index == PANEL_INDEX.DlcHunt
            or index == PANEL_INDEX.GeneralSkill
            or index == PANEL_INDEX.FpsGame
    then
        self.BtnSave.gameObject:SetActiveEx(false)
        self.BtnDefault.gameObject:SetActiveEx(false)
    elseif index ~= PANEL_INDEX.SpecialTrain then
        -- 特殊显示玩法, 不由此控制按钮, 否则按钮显示异常
        self.BtnSave.gameObject:SetActive(true)
        self.BtnDefault.gameObject:SetActive(true)
        if self.IsStartAnimCommon then
            self.IsStartAnimCommon = false
            self.BtnDefaultAnmation:EnableAnim(XUiButtonState.Normal)
            self.BtnSaveAnmation:EnableAnim(XUiButtonState.Normal)
        else
            -- 由于动画未播放完毕，就被setActive(false)，导致透明度错误
            XUiHelper.ResetBtnAlpha(self.BtnSave)
            XUiHelper.ResetBtnAlpha(self.BtnDefault)
        end
    end

    self.SelectedIndex = index
    for i, panel in pairs(self.SubPanels) do
        if (i == index) then
            self.CurShowIndex = index
            panel:Open()
        else
            panel:Close()
        end
    end
    self.BtnRetreat.gameObject:SetActiveEx(self.IsFight)

    local restartData = self:GetReStartData()
    local showRestartIndex = index == PANEL_INDEX.Instruction
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

function XUiSet:SetBtnVisibleByCfg(btn, value)
    btn.gameObject:SetActiveEx(value == 1)
end

function XUiSet:JumpToFightSetting()
    self.PanelTabToggles:SelectIndex(PANEL_INDEX.Fight)
end
--endregion

--region Ui - Tip
function XUiSet:TipDialog(cancelCb, confirmCb)
    XLuaUiManager.Open("UiDialog", self.TipTitle, self.TipContent, XUiManager.DialogType.Normal, cancelCb, confirmCb)
end
--endregion

--region Ui - BtnListener
function XUiSet:OnBtnRestart()
    local restartData = self:GetReStartData()
    if not restartData.IsCanRestart then
        XUiManager.TipErrorWithKey(restartData.RestartTipsDescKey or "TheatreNotRestartTips")
        return
    end
    local title, content = self:GetReStartTitleAndContent()
    local cb = function()
        self.Super.Close(self)
        XLuaUiManager.Open("UiLoading", LoadingType.Fight)
    end
    local confirmCb = function()
        if CS.XFight.IsRunning then
            self:AddRecordStr("重开")
            self:CsRecord(XSetConfigs.RecordOperationType.ReStart)
            CS.XFight.Instance:Restart(cb)
            XDataCenter.FightWordsManager.Stop(true)
        end
    end
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, confirmCb)
end

function XUiSet:OnBtnDefaultClick()
    self.SubPanels[self.SelectedIndex]:ResetToDefault()
end

function XUiSet:OnBtnSaveClick()
    self:Save()
    XUiManager.TipText("SettingSave")
end

function XUiSet:OnBtnRetreat()
    local title, content = self:GetRetreatTitleAndContent()
    local confirmCb = function()
        self:CsRecord(XSetConfigs.RecordOperationType.Retreat)
        XMVCA.XDlcRoom:RecordFightQuit(3)
        CS.XFightInterface.Exit(true)
        self.Super.Close(self)
    end
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, confirmCb)
end

function XUiSet:OnBtnInfoTip()
    self.MultiClickHelper:Click()
end

function XUiSet:Close()
    self:CheckSave(function()
        self:CsRecord(XSetConfigs.RecordOperationType.Back)
        self.Super.Close(self)
    end)
end

function XUiSet:OnBtnMainUiClick()
    self:CheckSave(function()
        XLuaUiManager.RunMain()
    end)
end

--战斗页签红点（自定义按键冲突）
function XUiSet:OnCheckFightSetNews(count)
    self.BtnFight:ShowReddot(count >= 0)
    self.BtnFight:ShowTag(count >= 0 and not CS.XCustomUi.Instance.IsOpenUiFightCustomRed)
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
--endregion

--region Record
-- 记录埋点
function XUiSet:CsRecord(type)
    if not CS.XFight.IsRunning then return end
    local dict = {}
    local stageId = CS.XFight.Instance.FightData.StageId
    local stageType = XMVCA.XFuben:GetStageType(stageId)
    if stageType then
        if stageType == XDataCenter.FubenManager.StageType.Arena then
            dict["pve_type"] = stageType
            dict["activity_no"] = XMVCA.XArena:GetActivityNo()
            dict["boss_level"] = 0
            dict["challenge_id"] = XMVCA.XArena:GetActivityCurrentChallengeId()
            dict["boss_id"] = 0
            dict["i_group_id"] = XMVCA.XArena:GetCurrentFightEventGroupId()
            dict["i_buff_id"] = XMVCA.XArena:GetCurrentFightBuffId()
            dict["i_area_id"] = XMVCA.XArena:GetCurrentAreaId()
        elseif stageType == XDataCenter.FubenManager.StageType.BossSingle then
            local data = XMVCA.XFubenBossSingle:GetBossSingleData()
            dict["pve_type"] = stageType
            dict["activity_no"] = data and data:GetBossSingleActivityNo() or 0
            dict["boss_level"] = data and data:GetEnterBossLevel() or 0
            dict["challenge_id"] = 0
            dict["boss_id"] = data and data:GetEnterBossId() or 0
            dict["i_feature_id"] = XMVCA.XFubenBossSingle:GetCurrentFeatureId()
        end
    end 
   
    dict["stage_id"] = stageId
    dict["type"] = type
    CS.XRecord.Record(dict, "200015", "FightStopOperation")
end

function XUiSet:AddRecordStr(str)
    if not CS.XFight.Instance then
        return
    end
    local frame = CS.XFight.Instance.Frame
    CS.XFight.Instance.RoleManager:CheckAddRecordStr(string.format("%s\t%s\tFalse\t%s", frame, str, ""))
end
--endregion

function XUiSet:FpsGameSpecialShow()
    if XLuaUiManager.IsUiLoad("UiFpsGameChooseWeapon") then
        self._IsHideFpsGameSetting = true
        self.BtnFpsGame.gameObject:SetActiveEx(true)
        self.BtnFight.gameObject:SetActiveEx(false)
    end
end

return XUiSet
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local ipairs = ipairs
local XUiGridEchelonExp = require("XUi/XUiBfrt/Settle/XUiGridEchelonExp")
---@class XUiBfrtPostWarCount:XLuaUi
local XUiBfrtPostWarCount = XLuaUiManager.Register(XLuaUi, "UiBfrtPostWarCount")
local ANIMATION_OPEN = "AniBfrtPostWarCountBegin"

function XUiBfrtPostWarCount:OnAwake()
    self:InitAutoScript()
end

function XUiBfrtPostWarCount:OnStart(data, isFastPass)
    self._IsFastPass = isFastPass
    self._Data = data
    self:InitComponentState()
    self:ResetDataInfo()
    self:UpdateDataInfo()
    self:PlayAnimation(ANIMATION_OPEN)
end

function XUiBfrtPostWarCount:OnDisable()
    if self._IsFastPass then
        XDataCenter.FunctionEventManager.UnLockFunctionEvent()
    end
end

function XUiBfrtPostWarCount:OnNotify(evt, ...)
    local args = { ... }
    if self._IsFastPass then
        return
    end

    if evt == CS.XEventId.EVENT_UI_ALLOWOPERATE and args[1] == self.Ui then
        XDataCenter.FunctionEventManager.UnLockFunctionEvent()
    end
end

function XUiBfrtPostWarCount:OnGetEvents()
    return { CS.XEventId.EVENT_UI_ALLOWOPERATE }
end

function XUiBfrtPostWarCount:InitComponentState()
    self.GridEchelonExp.gameObject:SetActive(false)
end

function XUiBfrtPostWarCount:ResetDataInfo()
    self.RewardGoodsList = {}
    self.GroupId = nil
    self.GridReward.gameObject:SetActive(false)
    self.GridEchelonExp.gameObject:SetActive(false)
end

function XUiBfrtPostWarCount:UpdateDataInfo()
    self.RewardGoodsList = self._Data.RewardGoodsList
    self.GroupId = XDataCenter.BfrtManager.GetGroupIdByStageId(self._Data.StageId)

    self:UpdatePanelRewardContent()
    self:UpdatePanelEchelonExpContent()
    self:UpdatePanelPlayer()
    self:CtrlBtnNextStageVisible()
end

function XUiBfrtPostWarCount:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiBfrtPostWarCount:AutoInitUi()
    self.PanelRewardContent = self.Transform:Find("SafeAreaContentPane/PaneReward/RewardList/Viewport/PanelRewardContent")
    self.GridReward = self.Transform:Find("SafeAreaContentPane/PaneReward/RewardList/Viewport/PanelRewardContent/GridReward")
    self.PanelEchelonExpContent = self.Transform:Find("SafeAreaContentPane/PaneEchelonExp/EchelonExpList/Viewport/PanelEchelonExpContent")
    self.GridEchelonExp = self.Transform:Find("SafeAreaContentPane/PaneEchelonExp/EchelonExpList/Viewport/PanelEchelonExpContent/GridEchelonExp")
    self.BtnNextStage = self.Transform:Find("SafeAreaContentPane/BtnNextStage"):GetComponent("Button")
    self.BtnExit = self.Transform:Find("SafeAreaContentPane/BtnExit"):GetComponent("Button")
    self.BtnClose = self.Transform:Find("SafeAreaContentPane/BtnClose"):GetComponent("Button")
    self.PanelPlayer = self.Transform:Find("SafeAreaContentPane/PanelPlayer")
    self.ImgExp = self.Transform:Find("SafeAreaContentPane/PanelPlayer/ImgExp"):GetComponent("Image")
    self.TxtAddExp = self.Transform:Find("SafeAreaContentPane/PanelPlayer/TxtAddExp"):GetComponent("Text")
    self.TxtLevelA = self.Transform:Find("SafeAreaContentPane/PanelPlayer/TxtLevel"):GetComponent("Text")
    self.TxtLevelName = self.Transform:Find("SafeAreaContentPane/PanelPlayer/TxtLevelName"):GetComponent("Text")
end

function XUiBfrtPostWarCount:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiBfrtPostWarCount:RegisterListener(uiNode, eventName, func)
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
            XLog.Error("XUiBfrtPostWarCount:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XLuaAudioManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiBfrtPostWarCount:AutoAddListener()
    self.AutoCreateListeners = {}
    self:RegisterClickEvent(self.BtnExit, self.OnBtnExitClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnNextStage, self.OnBtnNextStageClick)
end

function XUiBfrtPostWarCount:OnBtnExitClick()
    self:OnExitOrClose()
end

function XUiBfrtPostWarCount:OnBtnCloseClick()
    self:OnExitOrClose()
end

function XUiBfrtPostWarCount:OnExitOrClose()
    -- 说明进入战斗时的章节与退出时的章节不一致（需要打开对应章节的副本组界面）
    local bfrtChapterId = XDataCenter.BfrtManager.GetChapterIdByStageId(self._Data.StageId)
    if XDataCenter.BfrtManager.CheckSkipChapterByStageId(self._Data.StageId) then
        XDataCenter.BfrtManager.SetHandEnterFightChapterId(0)
        XLuaUiManager.Remove("UiFubenMainLineChapter")
        XLuaUiManager.PopThenOpen("UiFubenMainLineChapter", XDataCenter.BfrtManager.GetChapterCfg(bfrtChapterId), nil, true)
    else
        self:Close()
    end
end

function XUiBfrtPostWarCount:OnBtnNextStageClick()
    if not XDataCenter.BfrtManager.CheckCanQuicklyChallenge(self._Data.StageId) then
        return
    end

    local nextGroupId = XDataCenter.BfrtManager.GetNextGroupIdByBaseStage(self._Data.StageId)
    if nextGroupId == 0 then
        return
    end
    local nextFightTeamList = XDataCenter.BfrtManager.GetFightTeamList(nextGroupId)
    if not nextFightTeamList or next(nextFightTeamList) == nil then
        return
    end
    local nextLogisticsTeamList = XDataCenter.BfrtManager.GetLogisticsTeamList(nextGroupId)
    if not nextLogisticsTeamList then
        return
    end

    local cb = function(errorText)
        if errorText then
            XUiManager.TipMsg(errorText)
            return
        end

        self:Close()
        
        XDataCenter.BfrtManager.EnterFight({
            GroupId = nextGroupId,
            FightTeams = nextFightTeamList,
            GeneralSkills = XDataCenter.BfrtManager.GetTeamGeneralSkillsByGroupId(self.GroupId),
            CgIndexGroup = XDataCenter.BfrtManager.GetCgIndexGroupByGroupId(self.GroupId),
        })
    end

    XDataCenter.BfrtManager.SetTeamAndDoCB(nextGroupId, nextFightTeamList, nextLogisticsTeamList, cb)
end

function XUiBfrtPostWarCount:UpdatePanelRewardContent()
    local rewards = XRewardManager.MergeAndSortRewardGoodsList(self.RewardGoodsList)
    for _, item in ipairs(rewards) do
        local ui = CS.UnityEngine.Object.Instantiate(self.GridReward)
        local grid = XUiGridCommon.New(self, ui)
        grid.Transform:SetParent(self.PanelRewardContent, false)
        grid:Refresh(item, nil, nil, true)
        grid.GameObject:SetActive(true)
    end
end

function XUiBfrtPostWarCount:UpdatePanelEchelonExpContent()
    local data = {
        GroupId = self.GroupId,
        EchelonType = nil,
        EchelonIndex = nil,
        BaseStage = XDataCenter.BfrtManager.GetBaseStage(self.GroupId),
    }

    local fightInfoIdList = XDataCenter.BfrtManager.GetFightInfoIdList(self.GroupId)
    for index, _ in ipairs(fightInfoIdList) do
        data.EchelonIndex = index
        data.EchelonType = XDataCenter.BfrtManager.EchelonType.Fight

        local ui = CS.UnityEngine.Object.Instantiate(self.GridEchelonExp)
        local grid = XUiGridEchelonExp.New(self, ui, data)
        grid.Transform:SetParent(self.PanelEchelonExpContent, false)
        grid.GameObject:SetActive(true)
    end

    local lgoisticsInfoIdList = XDataCenter.BfrtManager.GetLogisticsInfoIdList(self.GroupId)
    for index, _ in ipairs(lgoisticsInfoIdList) do
        data.EchelonIndex = index
        data.EchelonType = XDataCenter.BfrtManager.EchelonType.Logistics

        local ui = CS.UnityEngine.Object.Instantiate(self.GridEchelonExp)
        local grid = XUiGridEchelonExp.New(self, ui, data)
        grid.Transform:SetParent(self.PanelEchelonExpContent, false)
        grid.GameObject:SetActive(true)
    end
end

function XUiBfrtPostWarCount:UpdatePanelPlayer()
    local curLevel = XPlayer.GetLevelOrHonorLevel()
    local curExp = XPlayer.Exp
    local maxExp = XPlayer:GetMaxExp()
    --local baseStageId = XDataCenter.BfrtManager.GetBaseStage(self.GroupId)
    --v2.9减负优化不再给据点关卡给等级经验，直接赋值为0 by ljb
    local teamExp = 0--XDataCenter.FubenManager.GetTeamExp(baseStageId)

    if XPlayer.IsHonorLevelOpen() then
        self.TxtLevelName.text = CS.XTextManager.GetText("HonorLevel")
    end
    self.TxtLevelA.text = curLevel
    self.TxtAddExp.text = "+ " .. teamExp
    self.ImgExp.fillAmount = curExp / maxExp
end

function XUiBfrtPostWarCount:CtrlBtnNextStageVisible()
    if self._IsFastPass then
        self.BtnNextStage.gameObject:SetActiveEx(false)
        return
    end

    self.BtnNextStage.gameObject:SetActiveEx(XDataCenter.BfrtManager.CheckCanQuicklyChallenge(self._Data.StageId))
end
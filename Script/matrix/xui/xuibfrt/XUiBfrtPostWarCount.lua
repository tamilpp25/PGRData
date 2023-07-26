local ipairs = ipairs
local XUiGridEchelonExp = require("XUi/XUiBfrt/XUiGridEchelonExp")
local XUiBfrtPostWarCount = XLuaUiManager.Register(XLuaUi, "UiBfrtPostWarCount")
local ANIMATION_OPEN = "AniBfrtPostWarCountBegin"

function XUiBfrtPostWarCount:OnAwake()
    self:InitAutoScript()
end

function XUiBfrtPostWarCount:OnStart(data)
    self:InitComponentState()
    self:ResetDataInfo()
    self:UpdateDataInfo(data)
    self:PlayAnimation(ANIMATION_OPEN)
end

function XUiBfrtPostWarCount:OnNotify(evt, ...)
    local args = { ... }

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

function XUiBfrtPostWarCount:UpdateDataInfo(data)
    self.RewardGoodsList = data.RewardGoodsList
    self.GroupId = XDataCenter.BfrtManager.GetGroupIdByStageId(data.StageId)

    self:UpdatePanelRewardContent()
    self:UpdatePanelEchelonExpContent()
    self:UpdatePanelPlayer()
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
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
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
end

function XUiBfrtPostWarCount:OnBtnExitClick()
    self:Close()
end

function XUiBfrtPostWarCount:OnBtnCloseClick()
    self:Close()
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
    local baseStageId = XDataCenter.BfrtManager.GetBaseStage(self.GroupId)
    local teamExp = XDataCenter.FubenManager.GetTeamExp(baseStageId)

    if XPlayer.IsHonorLevelOpen() then
        self.TxtLevelName.text = CS.XTextManager.GetText("HonorLevel") 
    end
    self.TxtLevelA.text = curLevel
    self.TxtAddExp.text = "+ " .. teamExp
    self.ImgExp.fillAmount = curExp / maxExp
end
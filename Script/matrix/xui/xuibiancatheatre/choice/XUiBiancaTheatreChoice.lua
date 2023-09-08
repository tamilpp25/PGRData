local XUiChoiceDifficultyPanel = require("XUi/XUiBiancaTheatre/Choice/XUiChoiceDifficultyPanel")
local XUiChoiceTeamPanel = require("XUi/XUiBiancaTheatre/Choice/XUiChoiceTeamPanel")
local XUiChoiceRecruitTicketPanel = require("XUi/XUiBiancaTheatre/Choice/XUiChoiceRecruitTicketPanel")
local XUiChoiceRewardPanel = require("XUi/XUiBiancaTheatre/Choice/XUiChoiceRewardPanel")
local XUiChoiceExRewardPanel = require("XUi/XUiBiancaTheatre/Choice/XUiChoiceExRewardPanel")
local XUiChoiceFightRewardPanel = require("XUi/XUiBiancaTheatre/Choice/XUiChoiceFightRewardPanel")
local XUiBiancaTheatrePanelDown = require("XUi/XUiBiancaTheatre/Common/XUiBiancaTheatrePanelDown")
local XUiPanelItemChange = require("XUi/XUiBiancaTheatre/Common/XUiPanelItemChange")

--不显示“下一步”按钮的UI类型
local NotShowNextBtnUiType = {
    [XBiancaTheatreConfigs.UiChoiceType.Reward] = true,
    [XBiancaTheatreConfigs.UiChoiceType.ExReward] = true,
}
--UI类型对应的标题和小方块下标
local ShowPanelBtUiType = {
    [XBiancaTheatreConfigs.UiChoiceType.Difficulty] = 1,
    [XBiancaTheatreConfigs.UiChoiceType.TeamSelect] = 2,
    [XBiancaTheatreConfigs.UiChoiceType.RecruitTicket] = 3,
    --只有前3个枚举才有小方块
    [XBiancaTheatreConfigs.UiChoiceType.FightReward] = 4,
}
--不显示分队和道具按钮的UI类型
local NotShowBtnDetailsUiType = {
    [XBiancaTheatreConfigs.UiChoiceType.Difficulty] = true,
    [XBiancaTheatreConfigs.UiChoiceType.TeamSelect] = true,
}
--不显示已招募角色列表按钮的UI类型
local NotShowBtnTeamUiType = {
    [XBiancaTheatreConfigs.UiChoiceType.Difficulty] = true,
    [XBiancaTheatreConfigs.UiChoiceType.TeamSelect] = true,
    [XBiancaTheatreConfigs.UiChoiceType.RecruitTicket] = true,
    [XBiancaTheatreConfigs.UiChoiceType.ExReward] = true,
}
--显示奖励背景的UI类型
local ShowRewardBg = {
    [XBiancaTheatreConfigs.UiChoiceType.Reward] = true,
    [XBiancaTheatreConfigs.UiChoiceType.ExReward] = true,
}
--显示资源栏的UI类型
local ShowPanelSpecialToolUiType = {
    [XBiancaTheatreConfigs.UiChoiceType.FightReward] = true,
}
--UI类型对应的UI名（功能引导用）
local UiTypeToChoiceUiName = {
    [XBiancaTheatreConfigs.UiChoiceType.TeamSelect] = "PanelTeamSelect",
    [XBiancaTheatreConfigs.UiChoiceType.RecruitTicket] = "PanelRecruitTicket",
}
--步骤类型转UI类型
local StpeTypeToUiType = {
    [XBiancaTheatreConfigs.XStepType.ExtraItemReward] = XBiancaTheatreConfigs.UiChoiceType.ExReward,
    [XBiancaTheatreConfigs.XStepType.ItemReward] = XBiancaTheatreConfigs.UiChoiceType.Reward,
    [XBiancaTheatreConfigs.XStepType.SelectRecruitTicket] = XBiancaTheatreConfigs.UiChoiceType.RecruitTicket,
    [XBiancaTheatreConfigs.XStepType.FightReward] = XBiancaTheatreConfigs.UiChoiceType.FightReward
}
--小方块的最大数量
local GRID_DOT_MAX_COUTN = 3

--######################## XUiBiancaTheatreChoice 选择难度、其他选择布局合一的界面 ########################
local XUiBiancaTheatreChoice = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreChoice")

function XUiBiancaTheatreChoice:OnAwake()
    self:NewPanel()

    -- XAdventureManager 当前冒险管理器
    self.CurrentAdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    -- XAdventureDifficulty 当前选择的难度
    self.CurrentDifficulty = nil
    -- 灵视特效
    self.EffectVision = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/EffectVision")
    if self.EffectVision then self.EffectVision.gameObject:SetActiveEx(false) end

    self:RegisterUiEvents()
    self:InitItemChange()
    XUiHelper.NewPanelActivityAssetSafe(XDataCenter.BiancaTheatreManager.GetAdventureAssetItemIds(), self.PanelSpecialTool, self, nil, XDataCenter.BiancaTheatreManager.AdventureAssetItemOnBtnClick)
end

function XUiBiancaTheatreChoice:OnStart(data)
    self.UiType = data and data.UiType   --要显示的布局类型 XBiancaTheatreConfigs.UiChoiceType
    self.CurStep = self.CurrentAdventureManager and self.CurrentAdventureManager:GetCurrentChapter():GetCurStep()    --XAdventureStep
    if not self.UiType then
        local curStep = self.CurStep
        local stepType = curStep and curStep:GetStepType()
        self.UiType = StpeTypeToUiType[stepType]
    end
    

    self:InitPanel(self.UiType)
end

function XUiBiancaTheatreChoice:OnEnable()
    XDataCenter.BiancaTheatreManager.CheckBgmPlay()
    self:Refresh()
    XDataCenter.BiancaTheatreManager.UpdateChapterBg(self.BiancaTheatreBg)
    -- 音效滤镜界限恢复
    XDataCenter.BiancaTheatreManager.StartAudioFilter()
    XEventManager.AddEventListener(XEventId.EVENT_BIANCA_THEATRE_SELECT_TEAM_UPGRADE, self.RefreshPanelDown, self)
end

function XUiBiancaTheatreChoice:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_BIANCA_THEATRE_SELECT_TEAM_UPGRADE, self.RefreshPanelDown, self)
end

--######################## 私有方法 ########################

function XUiBiancaTheatreChoice:RegisterUiEvents()
    self.BtnMainUi.CallBack = function() XDataCenter.BiancaTheatreManager.RunMain() end
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
end

function XUiBiancaTheatreChoice:NewPanel()
    --下方通用显示面板
    self.PanelDown = XUiBiancaTheatrePanelDown.New(self.Transform)
    --难度选择
    self.ChoiceDifficultyPanel = XUiChoiceDifficultyPanel.New(self.PanelDifficulty, self)
    --分队选择
    self.ChoiceTeamPanel = XUiChoiceTeamPanel.New(self.PanelChapterLis, self)
    --招募券选择
    self.ChoiceRecruitTicketPanel = XUiChoiceRecruitTicketPanel.New(self.PanelChapterLis, self)
    --奖励选择
    self.ChoiceRewardPanel = XUiChoiceRewardPanel.New(self.PanelReward, self)
    --额外奖励选择
    self.ChoiceExRewardPanel = XUiChoiceExRewardPanel.New(self.PanelReward, self)
    --战斗奖励选择
    self.ChoiceFightRewardPanel = XUiChoiceFightRewardPanel.New(self.PanelChapterLis, self)

    --UiChoiceType 对应的 Panel类对象
    self.PanelClass = {
        [XBiancaTheatreConfigs.UiChoiceType.Difficulty] = self.ChoiceDifficultyPanel,
        [XBiancaTheatreConfigs.UiChoiceType.TeamSelect] = self.ChoiceTeamPanel,
        [XBiancaTheatreConfigs.UiChoiceType.RecruitTicket] = self.ChoiceRecruitTicketPanel,
        [XBiancaTheatreConfigs.UiChoiceType.Reward] = self.ChoiceRewardPanel,
        [XBiancaTheatreConfigs.UiChoiceType.ExReward] = self.ChoiceExRewardPanel,
        [XBiancaTheatreConfigs.UiChoiceType.FightReward] = self.ChoiceFightRewardPanel,
    }
end

function XUiBiancaTheatreChoice:InitPanel(uiChoiceType)
    self.PanelDifficulty.gameObject:SetActiveEx(false)
    self.PanelChapterLis.gameObject:SetActiveEx(false)
    self.PanelReward.gameObject:SetActiveEx(false)
    
    if not uiChoiceType then
        return
    end

    local panelClass = self.PanelClass[uiChoiceType]
    if panelClass and panelClass.Init then
        panelClass:Init()
    end
    
    self:SetPanelNoneActive(false)
    
    --标题和小方块 
    local index = ShowPanelBtUiType[uiChoiceType]
    if index then
        local gridDotNor, gridDotSelect
        self.TextTitle.text = XBiancaTheatreConfigs.GetClientConfig("StartViewTitle", index)
        if index > GRID_DOT_MAX_COUTN then
            self.PanleDot.gameObject:SetActiveEx(false)
        else
            --3个小方块
            for i = 1, GRID_DOT_MAX_COUTN do
                gridDotNor = XUiHelper.TryGetComponent(self["GridDian" .. i], "Nor")
                gridDotSelect = XUiHelper.TryGetComponent(self["GridDian" .. i], "Select")
                if gridDotNor then
                    gridDotNor.gameObject:SetActiveEx(index ~= i)
                end
                if gridDotSelect then
                    gridDotSelect.gameObject:SetActiveEx(index == i)
                end
            end
        end
    end
    self.PanelBt.gameObject:SetActiveEx(index and true or false)
    
    self.PanelLeftInformation.gameObject:SetActiveEx(not NotShowBtnDetailsUiType[uiChoiceType])
    self.PanelTeam.gameObject:SetActiveEx(not NotShowBtnTeamUiType[uiChoiceType])
    self.BtnNextStep.gameObject:SetActiveEx(not NotShowNextBtnUiType[uiChoiceType])
    self.PanelSpecialTool.gameObject:SetActiveEx(ShowPanelSpecialToolUiType[uiChoiceType] or false)
    --背景
    self.PanelRewardBg.gameObject:SetActiveEx(ShowRewardBg[uiChoiceType])
    self.BiancaTheatreBg.gameObject:SetActiveEx(not ShowRewardBg[uiChoiceType])
    --选择的布局节点名
    local uiName = UiTypeToChoiceUiName[uiChoiceType]
    if uiName then
        self.PanelChapterLis.gameObject.name = uiName
    end
end

function XUiBiancaTheatreChoice:Refresh()
    local panelClass = self.PanelClass[self.UiType]
    if panelClass and panelClass.Refresh then
        panelClass:Refresh()
    end
    self:RefreshPanelDown()
    self:UpdateVisionEffect()
    self:RefreshItemChange(not ShowPanelSpecialToolUiType[self.UiType])
end

function XUiBiancaTheatreChoice:RefreshPanelDown()
    self.PanelDown:Refresh()
end

function XUiBiancaTheatreChoice:UpdateVisionEffect()
    if self.EffectVision then
        local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
        local visionValue = adventureManager:GetVisionValue() or 0
        local visionId = XBiancaTheatreConfigs.GetVisionIdByValue(visionValue)
        local isVisionOpen = XDataCenter.BiancaTheatreManager.CheckVisionIsOpen()
        self.EffectVision.gameObject:LoadUiEffect(XBiancaTheatreConfigs.GetVisionUiEffectUrl(visionId))
        self.EffectVision.gameObject:SetActiveEx(isVisionOpen)
    end
end

function XUiBiancaTheatreChoice:InitItemChange()
    local panelEnergyChangeList = {
        self.PanelEnergyChange2,
        self.PanelEnergyChange,
    }
    for index, itemId in ipairs(XDataCenter.BiancaTheatreManager.GetAdventureAssetItemIds()) do
        if panelEnergyChangeList[index] then
            self["ItemChange" .. index] = XUiPanelItemChange.New(panelEnergyChangeList[index], itemId)
        end
    end
end

function XUiBiancaTheatreChoice:RefreshItemChange(isClose)
    for index, _ in ipairs(XDataCenter.BiancaTheatreManager.GetAdventureAssetItemIds()) do
        if self["ItemChange" .. index] then
            self["ItemChange" .. index]:Refresh(isClose)
        end
    end
end

function XUiBiancaTheatreChoice:Close()
    self.Super.Close(self)
end

function XUiBiancaTheatreChoice:SetPanelNoneActive(isActive)
    self.PanelNone.gameObject:SetActiveEx(isActive)
end

return XUiBiancaTheatreChoice
-- 委托终端升级
---@class XUiDormTerminalUpgradeDetail : XLuaUi
local XUiDormTerminalUpgradeDetail = XLuaUiManager.Register(XLuaUi, "UiDormTerminalUpgradeDetail")

function XUiDormTerminalUpgradeDetail:OnAwake()
    self:RegisterUiEvents()

    self.ItemGrids = {}
end

function XUiDormTerminalUpgradeDetail:OnStart(callBack)
    self.CallBack = callBack
    ---@type XDormQuestTerminal
    self.TerminalViewModel = XDataCenter.DormQuestManager.GetCurLevelTerminalViewModel()
    self:InitUiData()
end

function XUiDormTerminalUpgradeDetail:OnEnable()
    local isGoing = self.TerminalViewModel:CheckTerminalOnGoing()
    if isGoing then
        self.FinishTime = self.TerminalViewModel:GetTerminalUpgradeFinishTime()
        self:StartTimer()
    end
end

function XUiDormTerminalUpgradeDetail:OnDisable()
    self:StopTimer()
end

function XUiDormTerminalUpgradeDetail:InitUiData()
    -- 描述
    self.TxtDesc.text = self.TerminalViewModel:GetQuestTerminalDescription()
    -- 等级
    self.TxtLevel.text = self.TerminalViewModel:GetTerminalLvDesc()
    -- 累计完成委托
    local curUpgradeExp, needFinishCount = self.TerminalViewModel:GetTerminalUpgradeQuest()
    self.TxtNum.text = XUiHelper.GetText("DormQuestTerminalFinishQuestCount", curUpgradeExp, needFinishCount)
    self.ImgExpAddBar.fillAmount = curUpgradeExp / needFinishCount
    local isMaxLevel = self.TerminalViewModel:CheckCurMaxLevel()
    -- 效果
    self:InitProperty(isMaxLevel)
    -- 消耗道具
    self:InitPanelItem()
    -- 消耗时间
    local needTime = self.TerminalViewModel:GetQuestTerminalNeedTime()
    self.TxtTime.text = XUiHelper.GetTime(needTime, XUiHelper.TimeFormatType.DEFAULT)
    self:InitBtnConfirmState()
    
    local isGoing = self.TerminalViewModel:CheckTerminalOnGoing()
    
    self.PanelUpCondition.gameObject:SetActiveEx(not isMaxLevel)
    self.TxtTitleUp.gameObject:SetActiveEx(not isMaxLevel)
    self.TxtTitleMax.gameObject:SetActiveEx(isMaxLevel)
    self.MaxLevel.gameObject:SetActiveEx(isMaxLevel)

    self.UpgradeTime.gameObject:SetActiveEx(isGoing)
    self.PanelItemList.gameObject:SetActiveEx(not isMaxLevel and not isGoing)
    self.TxtUpTime.gameObject:SetActiveEx(not isMaxLevel and not isGoing)
end

function XUiDormTerminalUpgradeDetail:InitProperty(isMaxLevel)
    local curLevel, curTeamCount, curQuestCount = self.TerminalViewModel:GetQuestTerminalPropertyData()
    local nextTerminalViewModel = isMaxLevel and self.TerminalViewModel or XDataCenter.DormQuestManager.GetNextLevelTerminalViewModel()
    local nextLevel, nextTeamCount, nextQuestCount = nextTerminalViewModel:GetQuestTerminalPropertyData()
    self:InitPropertyData(self.GridLevelUpgrade, isMaxLevel, curLevel, nextLevel)
    self:InitPropertyData(self.GridTeamUpgrade, isMaxLevel, curTeamCount, nextTeamCount)
    self:InitPropertyData(self.GridQuestUpgrade, isMaxLevel, curQuestCount, nextQuestCount)
end

-- 刷新属性数据
function XUiDormTerminalUpgradeDetail:InitPropertyData(prefab, isMaxLevel, curValue, nextValue)
    local grid = {}
    XTool.InitUiObjectByUi(grid, prefab)
    grid.PanelTxt.gameObject:SetActiveEx(not isMaxLevel)
    grid.TxtMaxValue.gameObject:SetActiveEx(isMaxLevel)
    if isMaxLevel then
        grid.TxtMaxValue.text = curValue
    else
        grid.TxtCurValue.text = curValue
        grid.TxtNewValue.text = nextValue
    end
end

function XUiDormTerminalUpgradeDetail:InitPanelItem()
    local itemData = self.TerminalViewModel:GetQuestTerminalItemData()
    local itemNum = #itemData
    for i = 1, itemNum do
        local grid = self.ItemGrids[i]
        if not grid then
            local go = i == 1 and self.GridItem or XUiHelper.Instantiate(self.GridItem, self.UiContent)
            grid = XUiGridCommon.New(self, go)
            self.ItemGrids[i] = grid
        end
        grid:Refresh(itemData[i])
        grid:SetNeedCount(itemData[i].CostCount)
        grid.GameObject:SetActiveEx(true)
    end
    for i = itemNum + 1, #self.ItemGrids do
        self.ItemGrids[i].GameObject:SetActiveEx(false)
    end
end

function XUiDormTerminalUpgradeDetail:InitBtnConfirmState()
    local isUpgrade = self.TerminalViewModel:CheckTerminalCanUpgrade()
    self.BtnConfirm:SetButtonState(isUpgrade and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
end

function XUiDormTerminalUpgradeDetail:StartTimer()
    if self.Timer then
        self:StopTimer()
    end

    self:UpdateTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTimer()
    end, XScheduleManager.SECOND)
end

function XUiDormTerminalUpgradeDetail:UpdateTimer()
    if XTool.UObjIsNil(self.TxtUpgradeTime) then
        self:StopTimer()
        return
    end

    local endTime = self.FinishTime
    local leftTime = endTime - XTime.GetServerNowTimestamp()
    if leftTime <= 0 then
        self:StopTimer()
        self:OnBtnCloseClick()
        return
    end
    local timeText = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.DEFAULT)
    self.TxtUpgradeTime.text = timeText
end

function XUiDormTerminalUpgradeDetail:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiDormTerminalUpgradeDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBg, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCancel, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnBtnConfirmClick)
end

function XUiDormTerminalUpgradeDetail:OnBtnCloseClick()
    self:Close()
end

function XUiDormTerminalUpgradeDetail:OnBtnConfirmClick()
    -- 是否是最大等级
    local isMaxLevel = self.TerminalViewModel:CheckCurMaxLevel()
    if isMaxLevel then
        XUiManager.TipText("DormQuestTerminalMaxLevel")
        return
    end
    -- 是否正在升级
    local isGoing = self.TerminalViewModel:CheckTerminalOnGoing()
    if isGoing then
        self:OnBtnCloseClick()
        return
    end
    -- 检查升级条件
    local isFinish, desc = self.TerminalViewModel:CheckTerminalFinishUpgradeCondition()
    if not isFinish then
        XUiManager.TipMsg(desc)
        return
    end
    -- 升级
    XDataCenter.DormQuestManager.QuestUpgradeTerminalLvRequest(function()
        XUiManager.TipText("DormQuestTerminalStartUpgrade")
        if self.CallBack then
            self.CallBack()
        end
        self:OnBtnCloseClick()
    end)
end

return XUiDormTerminalUpgradeDetail
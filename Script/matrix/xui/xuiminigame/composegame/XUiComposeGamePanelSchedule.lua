--组合小游戏进度UI控件
local XUiComposeGamePanelSchedule = XClass(nil, "XUiComposeGamePanelSchedule")
local XUiComposeGameTreasureBox = require("XUi/XUiMiniGame/ComposeGame/XUiComposeGameTreasureBox")
--动画时间
local TWEEN_TIME = 2
--================
--构造函数
--================
function XUiComposeGamePanelSchedule:Ctor(rootUi, game, ui)
    self.RootUi = rootUi
    self.Game = game
    XTool.InitUiObjectByUi(self, ui)
    self:RefreshSchedule()
    self:InitTreasureBoxes()
    self:InitPanelEffect()
end
--================
--刷新进度
--================
function XUiComposeGamePanelSchedule:RefreshSchedule()
    self.MaxSchedule = self.Game:GetMaxSchedule()
    self.CurrentSchedule = self.Game:GetCurrentSchedule()
    self.TxtTotalProgress.text = string.format("/%d", self.MaxSchedule)
    self.TxtProgress.text = self.CurrentSchedule
    self:SetScheduleFillAmount(self.CurrentSchedule)
end
--================
--初始化进度宝箱
--================
function XUiComposeGamePanelSchedule:InitTreasureBoxes()
    self.TreasureBoxes = {}
    table.insert(self.TreasureBoxes, XUiComposeGameTreasureBox.New(self.GridTreasure, self.Game:GetGameId()))
    self:RefreshBoxes()
end
--================
--初始化UI特效
--================
function XUiComposeGamePanelSchedule:InitPanelEffect()
    self.PanelEffect.gameObject:SetActiveEx(false)
end
--================
--刷新整个控件
--================
function XUiComposeGamePanelSchedule:UpdateData()
    self:RefreshSchedule()
    self:RefreshBoxes()
end
--================
--接受到进度变化事件时
--================
function XUiComposeGamePanelSchedule:OnScheduleRefresh()
    self:RefreshNewSchedule(self.Game:GetCurrentSchedule())
    self:RefreshBoxes()
end
--================
--刷新进度宝箱
--================
function XUiComposeGamePanelSchedule:RefreshBoxes()
    self.TreasureBoxesData = self.Game:GetTreasureBoxes()
    for i = 1, #self.TreasureBoxesData do
        if not self.TreasureBoxes[i] then
            local box = CS.UnityEngine.GameObject.Instantiate(self.GridTreasure)
            box.transform:SetParent(self.GiftContent.transform, false)
            self.TreasureBoxes[i] = XUiComposeGameTreasureBox.New(box, self.Game:GetGameId())
        end
        self.TreasureBoxes[i].GameObject:SetActiveEx(true)
        self.TreasureBoxes[i]:RefreshData(self.TreasureBoxesData[i])
    end
end
--================
--刷新新的进度
--================
function XUiComposeGamePanelSchedule:RefreshNewSchedule(targetSchedule)
    if not targetSchedule or targetSchedule == self.CurrentSchedule then return end
    local isAdd = targetSchedule > self.CurrentSchedule
    if isAdd then
        self.TargetSchedule = targetSchedule
        self:TweenScheduleFillAmount()
    else
        self:SetScheduleFillAmount(targetSchedule)
    end
end
--================
--设置进度条的图片进度
--================
function XUiComposeGamePanelSchedule:SetScheduleFillAmount(targetSchedule)
    if not self.ScheduleGroup then self:InitScheduleGroup() end
    local targetPercent = self:GetTargetSchedulePercent(targetSchedule)
    self.ImgDaylyActiveProgress.fillAmount = targetPercent
end
--================
--初始化进度管理数据
--================
function XUiComposeGamePanelSchedule:InitScheduleGroup()
    self.ScheduleGroup = {}
    local Schedules = self.Game:GetSchedule()
    self.ScheduleParagraph = 1 / #Schedules
    for i = 1, #Schedules do
        local scheduleGroup = {
                Schedule = Schedules[i], 
                FillAmountPercent = i * self.ScheduleParagraph,
                SchedulePercentValue = self.ScheduleParagraph / (Schedules[i] - (Schedules[i - 1] or 0))
            }
        table.insert(self.ScheduleGroup, scheduleGroup)
    end
end
--================
--根据目标进度值获取现在的进度条百分比
--@param targetSchedule:目标进度值
--================
function XUiComposeGamePanelSchedule:GetTargetSchedulePercent(targetSchedule)
    for i = 1, #self.ScheduleGroup do
        if targetSchedule <= self.ScheduleGroup[i].Schedule then
            local basePercent = self.ScheduleGroup[i - 1] and self.ScheduleGroup[i - 1].FillAmountPercent or 0
            local baseSchedule = self.ScheduleGroup[i - 1] and self.ScheduleGroup[i - 1].Schedule or 0
            return basePercent + ((targetSchedule - baseSchedule) * self.ScheduleGroup[i].SchedulePercentValue)
        end
    end
    return 1
end
--================
--设置进度条填充图片Tween动画
--================
function XUiComposeGamePanelSchedule:TweenScheduleFillAmount()
    local delta = self.TargetSchedule - self.CurrentSchedule
    XLuaUiManager.SetMask(true)
    XUiHelper.Tween(TWEEN_TIME, function(f)
            if XTool.UObjIsNil(self.Transform) then
                return
            end
            -- 现进度
            local currentSchedule = self.CurrentSchedule + math.floor(f * delta)
            self.TxtProgress.text = currentSchedule
            if currentSchedule <= self.MaxSchedule then
                self:SetScheduleFillAmount(currentSchedule)
            end
        end, function()
            if XTool.UObjIsNil(self.Transform) then
                return
            end
            self.CurrentSchedule = self.TargetSchedule
            self.TxtProgress.text = self.CurrentSchedule
            self:SetScheduleFillAmount(self.CurrentSchedule)
            self:SetEffectActive(false)
            XLuaUiManager.SetMask(false)
        end)
end
--================
--设置Tween时特效是否有效
--@param effectActive:是否有效
--================
function XUiComposeGamePanelSchedule:SetEffectActive(effectActive)
    self.PanelEffect.gameObject:SetActiveEx(effectActive)
end

return XUiComposeGamePanelSchedule
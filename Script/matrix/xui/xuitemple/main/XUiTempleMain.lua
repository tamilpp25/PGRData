local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")
local XRedPointConditionTempleTask = require("XRedPoint/XRedPointConditions/XRedPointConditionTempleTask")

---@field _Control XTempleControl
---@class XUiTempleMain:XLuaUi
local XUiTempleMain = XLuaUiManager.Register(XLuaUi, "UiTempleMain")

function XUiTempleMain:Ctor()
    ---@type XTempleUiControl
    self._UiControl = self._Control:GetUiControl()
    self._Timer = false
    self.Items = {}
    self._TimerReward = false
end

function XUiTempleMain:OnAwake()
    self._Control:InstantiateServerData()
    self:BindExitBtns()
    self:BindHelpBtn(nil, self._Control:GetHelpKey())
    self:RegisterClickEvent(self.GridChapter1, self.OnClickChapter1)
    self:RegisterClickEvent(self.GridChapter2, self.OnClickChapter2)
    self:RegisterClickEvent(self.GridChapter3, self.OnClickChapter3)
    self:RegisterClickEvent(self.BtnTask, self.OnClickTask)

    self.PanelNewChapter1.gameObject:SetActiveEx(false)
    self.PanelNewChapter2.gameObject:SetActiveEx(false)
    self.PanelNewChapter3.gameObject:SetActiveEx(false)
    self.Grid256New.gameObject:SetActiveEx(false)
end

function XUiTempleMain:OnStart()
    self:UpdateReward()
end

function XUiTempleMain:OnEnable()
    -- 策划: 暂时不显示时间
    self:UpdateTime()
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateTime()
        end, XScheduleManager.SECOND)
    end
    self:Update()
end

function XUiTempleMain:OnDisable()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
    if self._TimerReward then
        XScheduleManager.UnSchedule(self._TimerReward)
        self._TimerReward = false
    end
end

function XUiTempleMain:Update()
    --self.BtnHelp
    local value1 = self._UiControl:GetChapterStar1()
    self.TxtNum1.text = value1
    if self.TxtNumDisable1 then
        self.TxtNumDisable1.text = value1
    end
    local value2 = self._UiControl:GetChapterPhoto2()
    self.TxtNum2.text = value2
    if self.TxtNumDisable2 then
        self.TxtNumDisable2.text = value2
    end
    local value3 = self._UiControl:GetChapterStar3()
    self.TxtNum3.text = value3
    if self.TxtNumDisable3 then
        self.TxtNumDisable3.text = value3
    end

    self:UpdateChapterDisable()

    self.BtnTask:ShowReddot(XRedPointConditionTempleTask.CheckTask())
end

function XUiTempleMain:OnClickChapter1()
    self._UiControl:OnClickChapter(XTempleEnumConst.CHAPTER.SPRING)
end

function XUiTempleMain:OnClickChapter2()
    self._UiControl:OnClickChapter(XTempleEnumConst.CHAPTER.COUPLE)
end

function XUiTempleMain:OnClickChapter3()
    self._UiControl:OnClickChapter(XTempleEnumConst.CHAPTER.LANTERN)
end

function XUiTempleMain:OnClickTask()
    XLuaUiManager.Open("UiTempleTask")
end

function XUiTempleMain:UpdateTime()
    self.TxtTime.text = self._UiControl:GetRemainTime()
    for chapterId = XTempleEnumConst.CHAPTER.SPRING, XTempleEnumConst.CHAPTER.LANTERN do
        local lockText = self["TextLock" .. chapterId]
        if self._UiControl:IsChapterUnlock(chapterId) then
            if lockText.gameObject.activeInHierarchy then
                self:UpdateChapterDisable()
            end
        else
            local text = self._UiControl:GetChapterUnlockText(chapterId)
            lockText.text = text
        end
    end
end

function XUiTempleMain:UpdateChapterDisable()
    for chapterId = XTempleEnumConst.CHAPTER.SPRING, XTempleEnumConst.CHAPTER.LANTERN do
        ---@type XUiComponent.XUiButton
        local uiButton = self["GridChapter" .. chapterId]
        if self._UiControl:IsChapterUnlock(chapterId) then
            uiButton:SetDisable(false)
            self["PanelNewChapter" .. chapterId].gameObject:SetActiveEx(self._UiControl:IsChapterJustUnlock(chapterId) or XRedPointConditionTempleTask.IsNewStageJustUnlock(chapterId))
            self["PanelStar" .. chapterId].gameObject:SetActiveEx(true)
        else
            self["PanelStar" .. chapterId].gameObject:SetActiveEx(false)
            uiButton:SetDisable(true)
        end
    end
end

function XUiTempleMain:UpdateReward()
    local rewardList = self._Control:GetTaskReward4Show()
    XUiHelper.CreateTemplates(self, self.Items, rewardList, XUiGridCommon.New, self.Grid256New, self.Grid256New.transform.parent, function(grid, data)
        grid:Refresh(data, nil, nil, false)
    end)
    self._TimerReward = XScheduleManager.ScheduleOnce(function()
        self.Grid256New.transform.parent.gameObject:SetActiveEx(false)
    end, 3 * XScheduleManager.SECOND)
end

return XUiTempleMain

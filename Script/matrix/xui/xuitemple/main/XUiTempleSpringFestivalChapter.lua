local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiTempleSpringFestivalChapterGrid = require("XUi/XUiTemple/Main/XUiTempleSpringFestivalChapterGrid")
local XRedPointConditionTempleTask = require("XRedPoint/XRedPointConditions/XRedPointConditionTempleTask")

---@field _Control XTempleControl
---@class XUiTempleSpringFestivalChapter:XLuaUi
local XUiTempleSpringFestivalChapter = XLuaUiManager.Register(XLuaUi, "UiTempleSpringFestivalChapter")

function XUiTempleSpringFestivalChapter:Ctor()
    ---@type XTempleUiControl
    self._UiControl = self._Control:GetUiControl()

    ---@type XUiTempleSpringFestivalChapterGrid[]
    self._StageList = {}

    self.Items = {}

    self._TimerReward = false
end

function XUiTempleSpringFestivalChapter:OnAwake()
    self:BindExitBtns()
    self:BindHelpBtn(nil, self._Control:GetHelpKey())
    self.GridChapter.gameObject:SetActiveEx(false)
    self:RegisterClickEvent(self.BtnMessage, self.OnClickMessage)
    self:RegisterClickEvent(self.BtnTask, self.OnClickTask)
    self.Grid256New.gameObject:SetActiveEx(false)
    self.StarBar = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelTitle/PanelStar/PanelBar/ImgBar", "Image")
end

function XUiTempleSpringFestivalChapter:OnStart()
    self:UpdateReward()
end

function XUiTempleSpringFestivalChapter:OnEnable()
    self._Control:ReleaseGameControl()
    self:Update()
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_UPDATE_STAGE, self.Update, self)
end

function XUiTempleSpringFestivalChapter:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_UPDATE_STAGE, self.Update, self)
    if self._TimerReward then
        XScheduleManager.UnSchedule(self._TimerReward)
        self._TimerReward = false
    end
end

function XUiTempleSpringFestivalChapter:Update()
    self.BtnTask:ShowReddot(XRedPointConditionTempleTask.CheckTask())
    self:UpdateTaskRedPoint()

    ---@type XTempleUiControlStage[]
    local stages, index = self._UiControl:GetCurrentChapterStageList()
    self:UpdateDynamicItem(self._StageList, stages, self.GridChapter, XUiTempleSpringFestivalChapterGrid)

    local grid = self._StageList[index]
    if grid then
        ---@type UnityEngine.UI.ScrollRect
        local listChapter = self.ListChapter
        local worldPosition = grid.Transform:TransformPoint(Vector3.zero)
        local localPosition = listChapter.content.transform:InverseTransformPoint(worldPosition)
        local contentWidth = listChapter.content.transform.rect.width - listChapter.transform.rect.width
        local value = (localPosition.x - listChapter.transform.rect.width / 2) / contentWidth
        value = CS.UnityEngine.Mathf.Clamp(value, 0, 1)
        listChapter.horizontalNormalizedPosition = value
    end

    local value1, value2 = self._UiControl:GetChapterStarAmount()
    self.TxtNum1.text = value1
    self.TxtNum2.text = "/" .. value2
    self.StarBar.fillAmount = value1 / value2
    self.TxtClear.text = self._UiControl:GetMessagePassedStageAmount()

    self:UpdateReward()
end

function XUiTempleSpringFestivalChapter:UpdateDynamicItem(gridArray, dataArray, uiObject, class)
    if #gridArray == 0 then
        uiObject.gameObject:SetActiveEx(false)
    end
    for i = 1, #dataArray do
        local grid = gridArray[i]
        if not grid then
            local parent = self["Chapter" .. i]
            if not parent then
                XLog.Error("[XUiTempleSpringFestivalChapter] uiȱ�ٶ�Ӧ�Ĺؿ��ڵ�:", i)
                return
            end
            local uiObject = CS.UnityEngine.Object.Instantiate(uiObject, parent)
            uiObject.transform.localPosition = Vector3.zero
            grid = class.New(uiObject, self)
            gridArray[i] = grid
        end
        grid:Open()
        grid:Update(dataArray[i], i)
    end
    for i = #dataArray + 1, #gridArray do
        local grid = gridArray[i]
        grid:Close()
    end
end

function XUiTempleSpringFestivalChapter:OnClickMessage()
    XLuaUiManager.Open("UiTempleMessage")
    XMVCA.XTemple:SetAllMessageNotJustUnlock(self._Control:GetChapter())
    self:UpdateTaskRedPoint()
end

function XUiTempleSpringFestivalChapter:OnClickTask()
    XLuaUiManager.Open("UiTempleTask")
end

function XUiTempleSpringFestivalChapter:UpdateTaskRedPoint()
    self.BtnMessage:ShowReddot(XRedPointConditionTempleTask.IsNewMessageJustUnlock(self._Control:GetChapter()))
end

function XUiTempleSpringFestivalChapter:UpdateReward()
    local rewardList = self._Control:GetTaskReward4Show()
    XUiHelper.CreateTemplates(self, self.Items, rewardList, XUiGridCommon.New, self.Grid256New, self.Grid256New.transform.parent, function(grid, data)
        grid:Refresh(data, nil, nil, false)
    end)
    if not self._TimerReward then
        self._TimerReward = XScheduleManager.ScheduleOnce(function()
            self.Grid256New.transform.parent.gameObject:SetActiveEx(false)
        end, 3 * XScheduleManager.SECOND)
    end
end

return XUiTempleSpringFestivalChapter
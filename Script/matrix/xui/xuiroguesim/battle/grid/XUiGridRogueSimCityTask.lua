local XUiGridRogueSimTask = require("XUi/XUiRogueSim/Battle/Grid/XUiGridRogueSimTask")
---@class XUiGridRogueSimCityTask : XUiNode
---@field private _Control XRogueSimControl
---@field Parent XUiRogueSimPopupRoundEnd
local XUiGridRogueSimCityTask = XClass(XUiNode, "XUiGridRogueSimCityTask")

function XUiGridRogueSimCityTask:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnGo, self.OnBtnGoClick, nil, true)
    self.Star.gameObject:SetActiveEx(false)
    self.GridTask.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridStarList = {}
    ---@type XUiGridRogueSimTask[]
    self.GridTaskList = {}
end

---@param id number 城邦自增Id
function XUiGridRogueSimCityTask:Refresh(id)
    self.Id = id
    self.CurLevel = self._Control.MapSubControl:GetCityLevelById(self.Id)
    self:RefreshCityInfo()
    self:RefreshStar()
    self:RefreshCanLevelUp()
    self:RefreshTask()
end

-- 刷新城邦信息
function XUiGridRogueSimCityTask:RefreshCityInfo()
    local cityLevelConfigId = self._Control.MapSubControl:GetCityLevelConfigIdById(self.Id, self.CurLevel)
    -- 标志
    local flagIcon = self._Control.MapSubControl:GetCityLevelFlagIcon(cityLevelConfigId)
    if flagIcon then
        self.ImgTag:SetSprite(flagIcon)
    end
    -- 名称
    self.TxtTitle.text = self._Control.MapSubControl:GetCityLevelName(cityLevelConfigId)
end

-- 刷新星级
function XUiGridRogueSimCityTask:RefreshStar()
    local maxLevel = self._Control.MapSubControl:GetCityMaxLevelById(self.Id)
    for i = 1, maxLevel do
        local grid = self.GridStarList[i]
        if not grid then
            grid = XUiHelper.Instantiate(self.Star, self.ListStar)
            self.GridStarList[i] = grid
        end
        grid.gameObject:SetActiveEx(true)
        local isOn = self.CurLevel >= i
        grid:GetObject("On").gameObject:SetActiveEx(isOn)
        grid:GetObject("Off").gameObject:SetActiveEx(not isOn)
    end
    for i = maxLevel + 1, #self.GridStarList do
        self.GridStarList[i].gameObject:SetActiveEx(false)
    end
end

-- 刷新可升级
function XUiGridRogueSimCityTask:RefreshCanLevelUp()
    local isCanLevelUp = self._Control.MapSubControl:CheckCityCanLevelUp(self.Id)
    self.BtnGo:ShowReddot(isCanLevelUp)
end

-- 刷新任务
function XUiGridRogueSimCityTask:RefreshTask()
    local taskIds = self._Control.MapSubControl:GetCityTaskIdsById(self.Id)
    for index, taskId in pairs(taskIds) do
        local grid = self.GridTaskList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridTask, self.Transform)
            grid = XUiGridRogueSimTask.New(go, self)
            self.GridTaskList[index] = grid
        end
        grid:Open()
        grid:Refresh(taskId)
    end
    for i = #taskIds + 1, #self.GridTaskList do
        self.GridTaskList[i]:Close()
    end
end

function XUiGridRogueSimCityTask:OnBtnGoClick()
    local gridId = self._Control.MapSubControl:GetCityGridIdById(self.Id)
    self.Parent:CloseAndSimulateGridClick(gridId)
end

return XUiGridRogueSimCityTask

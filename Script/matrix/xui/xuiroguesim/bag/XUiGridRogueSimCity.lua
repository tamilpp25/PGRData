local XUiGridRogueSimTask = require("XUi/XUiRogueSim/Battle/Grid/XUiGridRogueSimTask")
---@class XUiGridRogueSimCity : XUiNode
---@field private _Control XRogueSimControl
---@field Parent XUiRogueSimCityBag
---@field BtnGo XUiComponent.XUiButton
local XUiGridRogueSimCity = XClass(XUiNode, "XUiGridRogueSimCity")

function XUiGridRogueSimCity:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnGo, self.OnBtnGoClick, nil, true)
    self.Star.gameObject:SetActiveEx(false)
    self.GridEffect.gameObject:SetActiveEx(false)
    self.GridTask.gameObject:SetActiveEx(false)
    self.GridScore.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridStarList = {}
    ---@type UiObject[]
    self.GridEffectList = {}
    ---@type XUiGridRogueSimTask[]
    self.GridTaskList = {}
    ---@type UiObject[]
    self.GridScoreList = {}
end

---@param id number 城邦自增Id
function XUiGridRogueSimCity:Refresh(id)
    self.Id = id
    self.CurLevel = self._Control.MapSubControl:GetCityLevelById(id)
    self:RefreshCityInfo()
    self:RefreshStar()
    self:RefreshBuffList()
    self:RefreshTaskList()
    self:RefreshScoreList()
    self:RefreshGoBtn()
end

-- 刷新城邦信息
function XUiGridRogueSimCity:RefreshCityInfo()
    local cityLevelConfigId = self._Control.MapSubControl:GetCityLevelConfigIdById(self.Id, self.CurLevel)
    -- 图片
    local icon = self._Control.MapSubControl:GetCityLevelIcon(cityLevelConfigId)
    if icon then
        self.ImgIcon:SetSprite(icon)
    end
    -- 标志
    local flagIcon = self._Control.MapSubControl:GetCityLevelFlagIcon(cityLevelConfigId)
    if flagIcon then
        self.ImgTag:SetSprite(flagIcon)
    end
    -- 名称
    self.TxtTitle.text = self._Control.MapSubControl:GetCityLevelName(cityLevelConfigId)
end

-- 刷新星级
function XUiGridRogueSimCity:RefreshStar()
    local maxLevel = self._Control.MapSubControl:GetCityMaxLevelById(self.Id)
    for i = 1, maxLevel do
        local grid = self.GridStarList[i]
        if not grid then
            grid = XUiHelper.Instantiate(self.Star, self.PanelLv)
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

-- 刷新buff列表
function XUiGridRogueSimCity:RefreshBuffList()
    local cityLevelIdList = self._Control.MapSubControl:GetCityLevelIdListById(self.Id)
    for index, cityLevelId in pairs(cityLevelIdList) do
        local grid = self.GridEffectList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridEffect, self.ListEffect)
            self.GridEffectList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        local configLevel = self._Control.MapSubControl:GetCityLevelConfigLevel(cityLevelId)
        local isOn = configLevel <= self.CurLevel
        grid:GetObject("PanelOn").gameObject:SetActiveEx(isOn)
        grid:GetObject("PanelOff").gameObject:SetActiveEx(not isOn)
        local buffDesc = self._Control.MapSubControl:GetCityLevelBuffDesc(cityLevelId)
        grid:GetObject("TxtDetailOn").text = buffDesc
        grid:GetObject("TxtDetailOff").text = buffDesc
    end
    for i = #cityLevelIdList + 1, #self.GridEffectList do
        self.GridEffectList[i].gameObject:SetActiveEx(false)
    end
end

-- 刷新任务列表
function XUiGridRogueSimCity:RefreshTaskList()
    local taskIds = self._Control.MapSubControl:GetCityTaskIdsById(self.Id)
    self.ListTask.gameObject:SetActiveEx(#taskIds > 0)
    for index, taskId in pairs(taskIds) do
        local grid = self.GridTaskList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridTask, self.ListTask)
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

-- 刷新评分列表
function XUiGridRogueSimCity:RefreshScoreList()
    local index = 1
    local cityLevelConfigId = self._Control.MapSubControl:GetCityLevelConfigIdById(self.Id, self.CurLevel)
    for _, id in pairs(XEnumConst.RogueSim.CommodityIds) do
        local score = self._Control.MapSubControl:GetCityLevelShowScore(cityLevelConfigId, id)
        if score > 0 then
            local grid = self.GridScoreList[index]
            if not grid then
                grid = XUiHelper.Instantiate(self.GridScore, self.ListScore)
                self.GridScoreList[index] = grid
            end
            grid.gameObject:SetActiveEx(true)
            local icon = self._Control.ResourceSubControl:GetCommodityIcon(id)
            grid:GetObject("RImgResource"):SetRawImage(icon)
            grid:GetObject("TxtNum").text = score
            index = index + 1
        end
    end
    for i = index, #self.GridScoreList do
        self.GridScoreList[i].gameObject:SetActiveEx(false)
    end
    self.ListScore.gameObject:SetActiveEx(index > 1)
end

-- 刷新前往按钮
function XUiGridRogueSimCity:RefreshGoBtn()
    local isMaxLevel = self._Control.MapSubControl:CheckCityIsMaxLevel(self.Id)
    if self.PanelMax then
        self.PanelMax.gameObject:SetActiveEx(isMaxLevel)
    end
    if isMaxLevel then
        return
    end
    local isCanLevelUp = self._Control.MapSubControl:CheckCityCanLevelUp(self.Id)
    self.BtnGo:ShowReddot(isCanLevelUp)
end

function XUiGridRogueSimCity:OnBtnGoClick()
    local gridId = self._Control.MapSubControl:GetCityGridIdById(self.Id)
    self._Control:SimulateGridClickBefore(self.Parent.Name, gridId)
end

return XUiGridRogueSimCity

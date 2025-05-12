local XUiGridRogueSimTask = require("XUi/XUiRogueSim/Battle/Grid/XUiGridRogueSimTask")
---@class XUiGridRogueSimCityDetail : XUiNode
---@field private _Control XRogueSimControl
---@field Parent XUiRogueSimPopupCity
local XUiGridRogueSimCityDetail = XClass(XUiNode, "XUiGridRogueSimCityDetail")

function XUiGridRogueSimCityDetail:OnStart()
    if self.BtnUpgrade then
        XUiHelper.RegisterClickEvent(self, self.BtnUpgrade, self.OnBtnUpgradeClick, nil, true)
    end
    if self.BtnBuy then
        XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClick, nil, true)
    end
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

---@param gridId number 格子Id
function XUiGridRogueSimCityDetail:Refresh(gridId)
    ---@type XRogueSimCity
    local cityData = self._Control.MapSubControl:GetCityDataByGridId(gridId)
    if XTool.IsTableEmpty(cityData) then
        return
    end
    self.GridId = gridId
    self.Id = cityData:GetId()
    self.CurLevel = cityData:GetLevel()
    self:RefreshInfo()
    self:RefreshBuffList()
    self:RefreshTaskList()
    self:RefreshScoreList()
    self:RefreshBtnUpgrade()
    self:RefreshBtnBuy()
end

-- 刷新信息
function XUiGridRogueSimCityDetail:RefreshInfo()
    local cityLevelConfigId = self._Control.MapSubControl:GetCityLevelConfigIdById(self.Id, self.CurLevel)
    local icon = self._Control.MapSubControl:GetCityLevelIcon(cityLevelConfigId)
    if icon then
        self.ImgIcon:SetSprite(icon)
    end
    local flagIcon = self._Control.MapSubControl:GetCityLevelFlagIcon(cityLevelConfigId)
    if flagIcon then
        self.ImgTag:SetSprite(flagIcon)
    end
    self.TxtTitle.text = self._Control.MapSubControl:GetCityLevelName(cityLevelConfigId)
    local desc = self._Control.MapSubControl:GetCityLevelDesc(cityLevelConfigId)
    local isShowDesc = not string.IsNilOrEmpty(desc)
    self.TxtDesc.gameObject:SetActiveEx(isShowDesc)
    if isShowDesc then
        self.TxtDesc.text = desc
    end
    self:RefreshLevel()
end

-- 刷新等级
function XUiGridRogueSimCityDetail:RefreshLevel()
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

-- 刷新Buff列表
function XUiGridRogueSimCityDetail:RefreshBuffList()
    local cityLevelIdList = self._Control.MapSubControl:GetCityLevelIdListById(self.Id)
    for i, cityLevelId in ipairs(cityLevelIdList) do
        local grid = self.GridEffectList[i]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridEffect.gameObject, self.ListEffect)
            grid = go:GetComponent("UiObject")
            self.GridEffectList[i] = grid
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
function XUiGridRogueSimCityDetail:RefreshTaskList()
    local taskIds = self._Control.MapSubControl:GetCityTaskIdsById(self.Id)
    local isShowTask = #taskIds > 0
    self.ListTask.gameObject:SetActiveEx(isShowTask)
    if not isShowTask then return end

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
function XUiGridRogueSimCityDetail:RefreshScoreList()
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

-- 刷新升级按钮
function XUiGridRogueSimCityDetail:RefreshBtnUpgrade()
    self.BtnUpgrade.gameObject:SetActiveEx(false)
    self.PanelMax.gameObject:SetActiveEx(false)
    self.PanelExp.gameObject:SetActiveEx(false)
    -- 未购买
    local isExplored = self._Control.MapSubControl:GetCityIsExploredById(self.Id)
    if not isExplored then
        return
    end
    -- 最大级
    local isMaxLevel = self._Control.MapSubControl:CheckCityIsMaxLevel(self.Id)
    if isMaxLevel then
        self.PanelMax.gameObject:SetActiveEx(true)
        return
    end
    -- 下一级经验奖励
    local cityLevelConfigId = self._Control.MapSubControl:GetCityLevelConfigIdById(self.Id, self.CurLevel + 1)
    local rewardExp = self._Control.MapSubControl:GetCityLevelUnlockExpReward(cityLevelConfigId)
    self.PanelExp.gameObject:SetActiveEx(rewardExp > 0)
    if rewardExp > 0 then
        self.TxtExpNum.text = string.format("+%d", rewardExp)
        local expIcon = self._Control.ResourceSubControl:GetResourceIcon(XEnumConst.RogueSim.ResourceId.Exp)
        self.ImgExpIcon:SetSprite(expIcon)
    end
    -- 是否可升级
    self.BtnUpgrade.gameObject:SetActiveEx(true)
    local isCanLevelUp = self._Control.MapSubControl:CheckCityCanLevelUp(self.Id)
    self.BtnUpgrade:SetDisable(not isCanLevelUp)
end

-- 刷新购买按钮
function XUiGridRogueSimCityDetail:RefreshBtnBuy()
    local grid = self._Control:GetGrid(self.GridId)
    local isExplored = grid:GetIsExplored()
    self.BtnBuy.gameObject:SetActiveEx(not isExplored)
    self.PanelBuyExp.gameObject:SetActiveEx(not isExplored)
    if isExplored then
        return
    end
    -- 购买按钮
    local areaId = grid.AreaId
    local cost = self._Control.MapSubControl:GetBuyAreaCostGoldCount(areaId)
    local icon = self._Control.ResourceSubControl:GetResourceIcon(XEnumConst.RogueSim.ResourceId.Gold)
    self.BtnBuy:SetNameByGroup(0, tostring(cost))
    self.BtnBuy:SetRawImage(icon)
    -- 奖励经验
    local exp = self._Control.MapSubControl:GetRogueSimAreaUnlockExpReward(areaId)
    local expIcon = self._Control.ResourceSubControl:GetResourceIcon(XEnumConst.RogueSim.ResourceId.Exp)
    self.ImgBuyExpIcon:SetSprite(expIcon)
    self.TxtBuyExpNum.text = string.format("+%s", exp)
    -- 是否可购买
    local ownGold = self._Control.ResourceSubControl:GetResourceOwnCount(XEnumConst.RogueSim.ResourceId.Gold)
    self.BtnBuy:SetDisable(ownGold < cost)
end

function XUiGridRogueSimCityDetail:OnBtnUpgradeClick()
    local isCanLevelUp, desc = self._Control.MapSubControl:CheckCityCanLevelUp(self.Id)
    if not isCanLevelUp then
        XUiManager.TipMsg(desc)
        return
    end
    self._Control:RogueSimCityLevelUpRequest(self.Id, self.GridId, function()
        self._Control:ClearGridSelectEffect()
        self._Control:CheckNeedShowNextPopup(self.Parent.Name, true)
    end)
end

function XUiGridRogueSimCityDetail:OnBtnBuyClick()
    local grid = self._Control:GetGrid(self.GridId)
    local areaId = grid.AreaId
    local cost = self._Control.MapSubControl:GetBuyAreaCostGoldCount(areaId)
    local own = self._Control.ResourceSubControl:GetResourceOwnCount(XEnumConst.RogueSim.ResourceId.Gold)
    if own < cost then
        XUiManager.TipMsg(self._Control:GetClientConfig("BuildingGoldNotEnough"))
        return
    end

    -- 请求解锁区域
    self._Control:RogueSimUnlockAreaRequest(areaId, function()
        self._Control:ClearGridSelectEffect()
        self._Control:CheckNeedShowNextPopup(self.Parent.Name, true)
    end)
end

return XUiGridRogueSimCityDetail

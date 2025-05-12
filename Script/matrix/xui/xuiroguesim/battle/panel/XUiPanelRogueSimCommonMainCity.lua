local XUiGridRogueSimStarLevel = require("XUi/XUiRogueSim/Battle/Grid/XUiGridRogueSimStarLevel")
---@class XUiPanelRogueSimCommonMainCity : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimCommonMainCity = XClass(XUiNode, "XUiPanelRogueSimCommonMainCity")

function XUiPanelRogueSimCommonMainCity:OnStart()
    self.GridEffect.gameObject:SetActiveEx(false)
    self.PanelBuild.gameObject:SetActiveEx(false)
    self.GridBuild.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridEffectList = {}
    ---@type UiObject[]
    self.GridBuildList = {}
end

function XUiPanelRogueSimCommonMainCity:Refresh()
    self.CurLevel = self._Control:GetCurMainLevel()
    self.CurConfigId = self._Control:GetMainLevelConfigId(self.CurLevel)
    self.IsMaxLevel = self._Control:CheckIsMaxLevel(self.CurLevel)
    self:RefreshMainInfo()
    self:RefreshLevel()
    self:RefreshEffects()
    self:PlayAnimationWithMask("PanelMainCityEnable")
end

-- 刷新等级
function XUiPanelRogueSimCommonMainCity:RefreshLevel()
    if not self.PanelLvUI then
        ---@type XUiGridRogueSimStarLevel
        self.PanelLvUI = XUiGridRogueSimStarLevel.New(self.PanelLv, self)
    end
    self.PanelLvUI:Open()
    self.PanelLvUI:Refresh(self.CurLevel, self.IsMaxLevel)
end

-- 刷新主城信息
function XUiPanelRogueSimCommonMainCity:RefreshMainInfo()
    self.RImgCity:SetRawImage(self._Control:GetMainLevelIcon(self.CurConfigId))
    self.TxtName.text = self._Control:GetMainLevelName(self.CurConfigId)
end

-- 刷新升级效果
function XUiPanelRogueSimCommonMainCity:RefreshEffects()
    self.EffectIndex = 0
    self:RefreshProduceEffect()
    self:RefreshAreaEffect()
    self:RefreshBuildEffect()
    for i = self.EffectIndex + 1, #self.GridEffectList do
        self.GridEffectList[i].gameObject:SetActiveEx(false)
    end
    -- 无提升
    local isNoEffect = self.EffectIndex == 0
    self.TxtNone.gameObject:SetActiveEx(isNoEffect)
    -- 刷新建筑蓝图奖励
    self:RefreshBluePrint()
end

-- 刷新生产力效果
function XUiPanelRogueSimCommonMainCity:RefreshProduceEffect()
    local curValue = self._Control.ResourceSubControl:GetResourceOwnCount(XEnumConst.RogueSim.ResourceId.Population)
    local lastValue = curValue
    local rewardResourceIds = self._Control:GetMainLevelRewardResourceIds(self.CurConfigId)
    local rewardResourceCounts = self._Control:GetMainLevelRewardResourceCounts(self.CurConfigId)
    for index, id in ipairs(rewardResourceIds) do
        if id == XEnumConst.RogueSim.ResourceId.Population then
            lastValue = lastValue - rewardResourceCounts[index] or 0
        end
    end
    local params = self._Control:GetClientConfigParams("MainEffectProduce")
    self:AddEffect(params[1], params[2], lastValue, curValue)
end

-- 刷新区域效果
function XUiPanelRogueSimCommonMainCity:RefreshAreaEffect()
    local curValue = 0
    local mainLevelIds = self._Control:GetMainLevelList()
    for _, id in ipairs(mainLevelIds) do
        local level = self._Control:GetMainLevelConfigLevel(id)
        if level ~= 0 and level <= self.CurLevel then -- 等级0配置的解锁是默认解锁
            local unlockAreaIdxs = self._Control:GetMainLevelUnlockAreaIdxs(id)
            curValue = curValue + #unlockAreaIdxs
        end
    end
    local lastValue = curValue
    local unlockAreaIdxs = self._Control:GetMainLevelUnlockAreaIdxs(self.CurConfigId)
    lastValue = lastValue - #unlockAreaIdxs
    local params = self._Control:GetClientConfigParams("MainEffectArea")
    self:AddEffect(params[1], params[2], lastValue, curValue)
end

-- 刷新可建造建筑地块效果
function XUiPanelRogueSimCommonMainCity:RefreshBuildEffect()
    local lastConfigId = self._Control:GetMainLevelConfigId(self.CurLevel - 1)
    local lastValue = self._Control:GetMainLevelUnlockBuildCount(lastConfigId)
    local curValue = self._Control:GetMainLevelUnlockBuildCount(self.CurConfigId)
    local params = self._Control:GetClientConfigParams("MainEffectBuild")
    self:AddEffect(params[1], params[2], lastValue, curValue)
end

function XUiPanelRogueSimCommonMainCity:AddEffect(desc, icon, value1, value2)
    -- 有变化的才显示
    if value2 == value1 then
        return
    end
    self.EffectIndex = self.EffectIndex + 1
    local grid = self.GridEffectList[self.EffectIndex]
    if not grid then
        grid = XUiHelper.Instantiate(self.GridEffect, self.PanelEffect)
        self.GridEffectList[self.EffectIndex] = grid
    end
    grid.gameObject:SetActiveEx(true)
    grid:GetObject("ImgIcon"):SetSprite(icon)
    grid:GetObject("TxtDetail").text = desc
    grid:GetObject("TxtNow").text = value1
    grid:GetObject("TxtNew").text = value2
    --grid:GetObject("TxtNormal").text = value2
    grid:GetObject("ImgUp").gameObject:SetActiveEx(not self.IsMaxLevel)
    --grid:GetObject("TxtNormal").gameObject:SetActiveEx(not self.IsMaxLevel and value1 >= value2)
    grid:GetObject("TxtNew").gameObject:SetActiveEx(not self.IsMaxLevel and value1 < value2)
end

-- 刷新建筑蓝图奖励
function XUiPanelRogueSimCommonMainCity:RefreshBluePrint()
    local rewardBluePrintIds = self._Control:GetMainLevelRewardBluePrintIds(self.CurConfigId)
    if #rewardBluePrintIds == 0 then
        return
    end
    self.PanelBuild.gameObject:SetActiveEx(true)
    local rewardBluePrintCounts = self._Control:GetMainLevelRewardBluePrintCounts(self.CurConfigId)
    for index, bluePrintId in ipairs(rewardBluePrintIds) do
        local grid = self.GridBuildList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridBuild, self.ListBuild)
            self.GridBuildList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        local icon = self._Control.MapSubControl:GetBuildingBluePrintIcon(bluePrintId)
        grid:GetObject("RawImage"):SetRawImage(icon)
        local count = rewardBluePrintCounts[index] or 0
        grid:GetObject("TxtNum").text = string.format("x%s", count)
        grid:GetObject("BtnBuild").CallBack = function()
            -- TODO 点击建筑蓝图
        end
    end
    for i = #rewardBluePrintIds + 1, #self.GridBuildList do
        self.GridBuildList[i].gameObject:SetActiveEx(false)
    end
end

return XUiPanelRogueSimCommonMainCity

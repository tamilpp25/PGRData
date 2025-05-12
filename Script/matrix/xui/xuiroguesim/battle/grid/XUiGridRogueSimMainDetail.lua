local XUiGridRogueSimStarLevel = require("XUi/XUiRogueSim/Battle/Grid/XUiGridRogueSimStarLevel")
---@class XUiGridRogueSimMainDetail : XUiNode
---@field private _Control XRogueSimControl
---@field Parent XUiRogueSimPopupCity
---@field BtnUpgrade XUiComponent.XUiButton
local XUiGridRogueSimMainDetail = XClass(XUiNode, "XUiGridRogueSimMainDetail")

function XUiGridRogueSimMainDetail:OnStart()
    if self.BtnUpgrade then
        XUiHelper.RegisterClickEvent(self, self.BtnUpgrade, self.OnBtnUpgradeClick, nil, true)
    end
    self.GridEffect.gameObject:SetActiveEx(false)
    self.PanelBuild.gameObject:SetActiveEx(false)
    self.GridBuild.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridEffectList = {}
    ---@type UiObject[]
    self.GridBuildList = {}
end

function XUiGridRogueSimMainDetail:Refresh()
    self:SetLevelData()
    self:RefreshInfo()
    self:RefreshExp()
    self:RefreshEffects()
    self:RefreshBtnUpgrade()
end

function XUiGridRogueSimMainDetail:SetLevelData()
    self.CurLevel = self._Control:GetCurMainLevel()
    self.CurConfigId = self._Control:GetMainLevelConfigId(self.CurLevel)
    self.IsMaxLevel = self._Control:CheckIsMaxLevel(self.CurLevel)
    self.NextConfigId = self.CurConfigId
    if not self.IsMaxLevel then
        self.NextConfigId = self._Control:GetMainLevelConfigId(self.CurLevel + 1)
    end
end

-- 刷新信息
function XUiGridRogueSimMainDetail:RefreshInfo()
    self.ImgIcon:SetSprite(self._Control:GetMainLevelIcon(self.CurConfigId))
    self.TxtTitle.text = self._Control:GetMainLevelName(self.CurConfigId)
    self.TxtDesc.text = self._Control:GetMainLevelDesc(self.CurConfigId)
    self:RefreshLevel()
end

-- 刷新等级
function XUiGridRogueSimMainDetail:RefreshLevel()
    if not self.PanelLvUI then
        ---@type XUiGridRogueSimStarLevel
        self.PanelLvUI = XUiGridRogueSimStarLevel.New(self.PanelLv, self)
    end
    self.PanelLvUI:Open()
    self.PanelLvUI:Refresh(self.CurLevel, self.IsMaxLevel)
end

-- 刷新Exp
function XUiGridRogueSimMainDetail:RefreshExp()
    self.TxtTips.gameObject:SetActiveEx(not self.IsMaxLevel)
    self.TxtMax.gameObject:SetActiveEx(self.IsMaxLevel)
    self.TxtExpNum.gameObject:SetActiveEx(not self.IsMaxLevel)
    if self.IsMaxLevel then
        self.ImgExpBar.fillAmount = 1
    else
        -- 经验图标和数值
        local expIcon = self._Control.ResourceSubControl:GetResourceIcon(XEnumConst.RogueSim.ResourceId.Exp)
        self.ImgExpIcon:SetSprite(expIcon)
        local curExp, upExp = self._Control:GetCurExpAndLevelUpExp(self.CurLevel)
        self.TxtExpNum.text = string.format("%d/%d", curExp, upExp)
        -- 进度条
        self.ImgExpBar.fillAmount = XTool.IsNumberValid(upExp) and curExp / upExp or 1
    end
end

-- 刷新升级效果
function XUiGridRogueSimMainDetail:RefreshEffects()
    self.EffectIndex = 0
    self:RefreshProduceEffect()
    self:RefreshAreaEffect()
    self:RefreshBuildEffect()
    for i = self.EffectIndex + 1, #self.GridEffectList do
        self.GridEffectList[i].gameObject:SetActiveEx(false)
    end
    -- 刷新建筑蓝图奖励
    self:RefreshBluePrint()
end

-- 刷新生产力效果
function XUiGridRogueSimMainDetail:RefreshProduceEffect()
    local curValue = self._Control.ResourceSubControl:GetResourceOwnCount(XEnumConst.RogueSim.ResourceId.Population)
    local nextValue = curValue
    if not self.IsMaxLevel then
        local rewardResourceIds = self._Control:GetMainLevelRewardResourceIds(self.NextConfigId)
        local rewardResourceCounts = self._Control:GetMainLevelRewardResourceCounts(self.NextConfigId)
        for index, id in pairs(rewardResourceIds) do
            if id == XEnumConst.RogueSim.ResourceId.Population then
                nextValue = nextValue + rewardResourceCounts[index] or 0
            end
        end
    end
    local params = self._Control:GetClientConfigParams("MainEffectProduce")
    self:AddEffect(params[1], params[2], curValue, nextValue)
end

-- 刷新区域效果
function XUiGridRogueSimMainDetail:RefreshAreaEffect()
    local curValue = 0
    local mainLevelIds = self._Control:GetMainLevelList()
    for _, id in ipairs(mainLevelIds) do
        local level = self._Control:GetMainLevelConfigLevel(id)
        if level ~= 0 and level <= self.CurLevel then -- 等级0配置的解锁是默认解锁
            local unlockAreaIdxs = self._Control:GetMainLevelUnlockAreaIdxs(id)
            curValue = curValue + #unlockAreaIdxs
        end
    end
    local nextValue = curValue
    if not self.IsMaxLevel then
        local unlockAreaIdxs = self._Control:GetMainLevelUnlockAreaIdxs(self.NextConfigId)
        nextValue = nextValue + #unlockAreaIdxs
    end
    local params = self._Control:GetClientConfigParams("MainEffectArea")
    self:AddEffect(params[1], params[2], curValue, nextValue)
end

-- 刷新可建造建筑地块效果
function XUiGridRogueSimMainDetail:RefreshBuildEffect()
    local curValue = self._Control:GetMainLevelUnlockBuildCount(self.CurConfigId)
    local nextValue = curValue
    if not self.IsMaxLevel then
        nextValue = self._Control:GetMainLevelUnlockBuildCount(self.NextConfigId)
    end
    local params = self._Control:GetClientConfigParams("MainEffectBuild")
    self:AddEffect(params[1], params[2], curValue, nextValue)
end

function XUiGridRogueSimMainDetail:AddEffect(desc, icon, value1, value2)
    -- 两个值都小于等于0则不显示
    if value1 <= 0 and value2 <= 0 then
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
    grid:GetObject("TxtNormal").text = value2
    grid:GetObject("ImgUp").gameObject:SetActiveEx(not self.IsMaxLevel)
    grid:GetObject("TxtNormal").gameObject:SetActiveEx(not self.IsMaxLevel and value1 >= value2)
    grid:GetObject("TxtNew").gameObject:SetActiveEx(not self.IsMaxLevel and value1 < value2)
end

-- 刷新建筑蓝图奖励
function XUiGridRogueSimMainDetail:RefreshBluePrint()
    if self.IsMaxLevel then
        return
    end
    local rewardBluePrintIds = self._Control:GetMainLevelRewardBluePrintIds(self.NextConfigId)
    if #rewardBluePrintIds == 0 then
        return
    end
    self.PanelBuild.gameObject:SetActiveEx(true)
    local rewardBluePrintCounts = self._Control:GetMainLevelRewardBluePrintCounts(self.NextConfigId)
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
        grid:GetObject("TxtNum").text = string.format("x%d", count)
        grid:GetObject("BtnBuild").CallBack = function() self.Parent:OnSelectBuildClick(bluePrintId) end
    end
    for i = #rewardBluePrintIds + 1, #self.GridBuildList do
        self.GridBuildList[i].gameObject:SetActiveEx(false)
    end
end

function XUiGridRogueSimMainDetail:RefreshBtnUpgrade()
    if not self.BtnUpgrade then
        return
    end
    self.BtnUpgrade.gameObject:SetActiveEx(not self.IsMaxLevel)
    if not self.IsMaxLevel then
        -- 刷新金币图标
        local goldIcon = self._Control.ResourceSubControl:GetResourceIcon(XEnumConst.RogueSim.ResourceId.Gold)
        self.BtnUpgrade:SetRawImage(goldIcon)
        -- 刷新金币数量
        local isEnough = self._Control:CheckLevelUpGoldIsEnough(self.CurLevel)
        local discountGoldCount = self._Control:GetCurLevelUpGoldCountWithDiscount(self.CurLevel)
        local color = self._Control:GetClientConfig("MainLevelUpgradeGoldColor", isEnough and 1 or 2)
        self.BtnUpgrade:SetNameAndColorByGroup(1, discountGoldCount, XUiHelper.Hexcolor2Color(color))
        -- 金币不足或者经验不足则按钮置灰
        local curExp, upExp = self._Control:GetCurExpAndLevelUpExp(self.CurLevel)
        self.BtnUpgrade:SetDisable(not isEnough or curExp < upExp)
    end
end

function XUiGridRogueSimMainDetail:OnBtnUpgradeClick()
    local isCanLevelUp, desc = self._Control:CheckMainLevelCanLevelUp()
    if not isCanLevelUp then
        XUiManager.TipMsg(desc)
        return
    end
    self._Control:RogueSimMainLevelUpRequest(function()
        self.Parent:OnCloseCity()
    end)
end

return XUiGridRogueSimMainDetail

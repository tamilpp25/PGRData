local XUiGridTheatre4OutpostBossBuff = require("XUi/XUiTheatre4/Game/Outpost/XUiGridTheatre4OutpostBossBuff")
local XUiGridTheatre4OutpostBossBuffCard = require("XUi/XUiTheatre4/Game/Outpost/XUiGridTheatre4OutpostBossBuffCard")
local XUiGridTheatre4Prop = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Prop")
local XUiGridTheatre4OutpostStar = require("XUi/XUiTheatre4/Game/Outpost/XUiGridTheatre4OutpostStar")
---@class XUiPanelTheatre4OutpostBoss : XUiNode
---@field private _Control XTheatre4Control
---@field Parent XUiTheatre4Outpost
local XUiPanelTheatre4OutpostBoss = XClass(XUiNode, "XUiPanelTheatre4OutpostBoss")

function XUiPanelTheatre4OutpostBoss:OnStart()
    self.GridBuff.gameObject:SetActiveEx(false)
    self.GridBuffCard.gameObject:SetActiveEx(false)
    self.GridProp.gameObject:SetActiveEx(false)
    self.GridStar.gameObject:SetActiveEx(false)
    self.PanelOn.gameObject:SetActiveEx(false)
    self.PanelOff.gameObject:SetActiveEx(false)
    self._Control:RegisterClickEvent(self, self.BtnExplore, self.OnBtnExploreClick)
    self._Control:RegisterClickEvent(self, self.BtnRecruit, self.OnBtnRecruitClick)
    self._Control:RegisterClickEvent(self, self.BtnRedOption, self.OnBtnRedOptionClick)
    ---@type XUiGridTheatre4OutpostBossBuff[]
    self.GridBuffList = {}
    self.CurSelectFightEventId = 0
    ---@type XUiGridTheatre4Prop[]
    self.GridRewardList = {}
    ---@type XUiGridTheatre4OutpostStar[]
    self.GridStarList = {}
end

---@param id number 战斗Id
---@param gridData XTheatre4Grid 格子数据
function XUiPanelTheatre4OutpostBoss:Refresh(id, gridData)
    if not XTool.IsNumberValid(id) then
        XLog.Error("XUiPanelTheatre4OutpostBoss:Refresh error: id: " .. id)
        if gridData then
            XLog.Error(string.format("格子数据 Type:%s, State:%s, ContentGroup:%s, ContentId:%s", gridData:GetGridType(),
                    gridData:GetGridState(), gridData:GetGridContentGroup(), gridData:GetGridContentId()))
        end
        return
    end
    self.Id = id
    self.GridData = gridData
    self:RefreshContent()
    self:RefreshBuff()
    self:RefreshReward()
    self:RefreshStar()
    self:RefreshProsperityAndRecruit()
    self:RefreshEffect411()
end

-- 刷新内容
function XUiPanelTheatre4OutpostBoss:RefreshContent()
    -- 头像
    local headIcon = self._Control:GetFightHeadIcon(self.Id)
    if headIcon then
        self.BossIcon:SetRawImage(headIcon)
    end
    -- 名称
    self.TxtName.text = self._Control:GetFightName(self.Id)
    -- 血量百分比
    local hpPercent = self.GridData:GetGridHpPercent()
    self.TxtNum.text = string.format("%s%%", hpPercent)
    -- 血量进度条
    self.ImgBar.fillAmount = hpPercent / 100
    -- 描述
    self.TxtDetail.text = self._Control:GetFightDesc(self.Id)
end

-- 刷新Buff
function XUiPanelTheatre4OutpostBoss:RefreshBuff()
    local fightEventIds = self.GridData:GetGridFightEvents()
    if XTool.IsTableEmpty(fightEventIds) then
        self.PanelBuff.gameObject:SetActiveEx(false)
        return
    end
    for index, fightEventId in pairs(fightEventIds) do
        local gridBuff = self.GridBuffList[index]
        if not gridBuff then
            local gridBuffGo = XUiHelper.Instantiate(self.GridBuff, self.ListBuff)
            gridBuff = XUiGridTheatre4OutpostBossBuff.New(gridBuffGo, self)
            self.GridBuffList[index] = gridBuff
        end
        gridBuff:Open()
        gridBuff:Refresh(fightEventId)
    end
    for i = #fightEventIds + 1, #self.GridBuffList do
        self.GridBuffList[i]:Close()
    end
end

-- 选择Buff
function XUiPanelTheatre4OutpostBoss:SelectBuff(fightEventId)
    if self.CurSelectFightEventId == fightEventId then
        self:CloseBuffCard()
        return
    end
    self.CurSelectFightEventId = fightEventId
    self:OpenBuffCard(fightEventId)
end

-- 打开Buff卡片
function XUiPanelTheatre4OutpostBoss:OpenBuffCard(fightEventId)
    if not self.BuffCardUi then
        ---@type XUiGridTheatre4OutpostBossBuffCard
        self.BuffCardUi = XUiGridTheatre4OutpostBossBuffCard.New(self.GridBuffCard, self)
    end
    self.BuffCardUi:Open()
    self.BuffCardUi:Refresh(fightEventId)
end

-- 关闭Buff卡片
function XUiPanelTheatre4OutpostBoss:CloseBuffCard()
    if self.BuffCardUi then
        self.BuffCardUi:Close()
    end
    self.CurSelectFightEventId = 0
end

-- 刷新产出
function XUiPanelTheatre4OutpostBoss:RefreshReward()
    local rewards = self.GridData:GetGridFightRewards()
    if XTool.IsTableEmpty(rewards) then
        self.PanelReward.gameObject:SetActiveEx(false)
        return
    end
    local index = 1
    for _, reward in pairs(rewards) do
        if self._Control:CheckShowReward(reward:GetRewardId()) then
            local gridReward = self.GridRewardList[index]
            if not gridReward then
                local gridRewardGo = XUiHelper.Instantiate(self.GridProp, self.ListReward)
                gridReward = XUiGridTheatre4Prop.New(gridRewardGo, self)
                self.GridRewardList[index] = gridReward
            end
            gridReward:Open()
            gridReward:Refresh({ Id = reward:GetId(), Type = reward:GetType(), Count = reward:GetNum() })
            index = index + 1
        end
    end
    for i = index, #self.GridRewardList do
        self.GridRewardList[i]:Close()
    end
end

-- 刷新星级
function XUiPanelTheatre4OutpostBoss:RefreshStar()
    if not self.GridData:IsGridTypeBoss() then
        self.PanelStar.gameObject:SetActiveEx(false)
        return
    end
    local starIds = self._Control:GetDifficultyStarIds()
    if XTool.IsTableEmpty(starIds) then
        self.PanelStar.gameObject:SetActiveEx(false)
        return
    end
    self.PanelStar.gameObject:SetActiveEx(true)
    -- 标题
    self.TxtStarTitle.text = self._Control:GetDifficultyStarTitle(starIds)
    -- 描述
    self.TxtStarDay.text = self._Control:GetDifficultyStarDesc(starIds)
    -- 刷新星级
    for index, starId in ipairs(starIds) do
        local gridStar = self.GridStarList[index]
        if not gridStar then
            local gridStarGo = XUiHelper.Instantiate(self.GridStar, self.ListStar)
            gridStar = XUiGridTheatre4OutpostStar.New(gridStarGo, self)
            self.GridStarList[index] = gridStar
        end
        gridStar:Open()
        gridStar:Refresh(starId)
    end
    for i = #starIds + 1, #self.GridStarList do
        self.GridStarList[i]:Close()
    end
end

-- 刷新效果411
function XUiPanelTheatre4OutpostBoss:RefreshEffect411()
    local isForbiddenFight, forbiddenType = self._Control.EffectSubControl:CheckEffectForbiddenFightType(self.Id, self.Parent.MapId)
    if isForbiddenFight then
        self.BtnExplore.gameObject:SetActiveEx(false)
        if forbiddenType == 1 then
            self:RefreshBtnRecruit()
            self:RefreshBtnRecruitRed()
        elseif forbiddenType == 2 then
            self.BtnRecruit.gameObject:SetActiveEx(false)
            if self.TxtNone then
                self.TxtNone.gameObject:SetActiveEx(true)
            end
        end
        return
    end
    self:RefreshBtnExplore()
    self:RefreshBtnRecruit()
    self:RefreshBtnRecruitRed()
end

-- 刷新繁荣度和招安
function XUiPanelTheatre4OutpostBoss:RefreshProsperityAndRecruit()
    -- 已探索不显示繁荣度限制和招安消耗
    if self.GridData:IsGridStateExplored() then
        self.PanelConsume.gameObject:SetActiveEx(false)
        return
    end
    -- 繁荣度限制
    local prosperityLimit = self:GetProsperityLimit()
    if not XTool.IsNumberValid(prosperityLimit) then
        self.PanelConsume.gameObject:SetActiveEx(false)
        return
    end
    self:RefreshProsperityLimit(prosperityLimit)
    self:RefreshRecruitCost()
end

-- 刷新繁荣度限制
function XUiPanelTheatre4OutpostBoss:RefreshProsperityLimit(prosperityLimit)
    local isProsperityEnough = self:CheckProsperityEnough(true)
    self.PanelOn2.gameObject:SetActiveEx(isProsperityEnough)
    self.PanelOff2.gameObject:SetActiveEx(not isProsperityEnough)
    local curPanelGo = isProsperityEnough and self.PanelOn2 or self.PanelOff2
    local curPanel = XTool.InitUiObjectByUi({}, curPanelGo)
    local prosperityIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Prosperity)
    if prosperityIcon then
        curPanel.Icon:SetRawImage(prosperityIcon)
    end
    curPanel.TxtCosumeNumber.text = prosperityLimit
end

-- 刷新招安消耗
function XUiPanelTheatre4OutpostBoss:RefreshRecruitCost()
    -- 扫荡可用
    local sweepAvailable = self._Control.EffectSubControl:GetEffectMonsterSweepAvailable()
    self.Panel01.gameObject:SetActiveEx(sweepAvailable)
    if not sweepAvailable then
        return
    end
    local isCostEnough = self:CheckRecruitCostEnough(true)
    self.PanelOn.gameObject:SetActiveEx(isCostEnough)
    self.PanelOff.gameObject:SetActiveEx(not isCostEnough)
    local curPanelGo = isCostEnough and self.PanelOn or self.PanelOff
    local curPanel = XTool.InitUiObjectByUi({}, curPanelGo)
    local goldIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Gold)
    if goldIcon then
        curPanel.Icon:SetRawImage(goldIcon)
    end
    curPanel.TxtCosumeNumber.text = self:GetRecruitCost()
end

-- 获取繁荣度限制
function XUiPanelTheatre4OutpostBoss:GetProsperityLimit()
    local fightGroupId = self.GridData:GetGridFightGroupId()
    return self._Control:GetFightGroupProsperityLimit(fightGroupId)
end

-- 检测繁荣度是否足够
function XUiPanelTheatre4OutpostBoss:CheckProsperityEnough(isNotTips)
    -- 繁荣度限制
    local prosperityLimit = self:GetProsperityLimit()
    -- 繁荣度是否足够
    return self._Control.AssetSubControl:CheckAssetEnough(XEnumConst.Theatre4.AssetType.Prosperity, nil, prosperityLimit, isNotTips)
end

-- 获取招安消耗
function XUiPanelTheatre4OutpostBoss:GetRecruitCost()
    local fightGroupId = self.GridData:GetGridFightGroupId()
    local clearCost = self._Control:GetFightGroupClearCost(fightGroupId)
    -- 扫荡(诏安)折扣
    local discount = self._Control.EffectSubControl:GetEffectSweepDiscount()
    return math.floor(clearCost * discount)
end

-- 获取招安消耗
function XUiPanelTheatre4OutpostBoss:GetRecruitRedCost()
    local fightGroupId = self.GridData:GetGridFightGroupId()
    local clearCost = self._Control:GetFightGroupRedClearCost(fightGroupId)
    -- 扫荡(诏安)折扣
    local discount

    -- 如果通过金币扫荡了50%的血量, 那么红色买死值也只需要支付50%
    local hp = self.GridData:GetGridHpPercent()
    if hp < 100 then
        discount = hp / 100
    end
    if discount then
        return math.floor(clearCost * discount)
    end
    return math.floor(clearCost)
end

-- 检测招安消耗是否足够
function XUiPanelTheatre4OutpostBoss:CheckRecruitCostEnough(isNotTips)
    local cost = self:GetRecruitCost()
    local isEffect, assetCount = self._Control.EffectSubControl:GetEffect410OnDailySettleAssetCount()
    local isCostEnough = self._Control.AssetSubControl:CheckAssetEnough(XEnumConst.Theatre4.AssetType.Gold, nil, cost, isNotTips or isEffect)

    if isCostEnough then
        return true
    end

    if isEffect and not isNotTips then
        local tip = self._Control:GetClientConfig("EffectRecruitCostNotEnoughTip", assetCount > 0 and 2 or 1)
        local formattedTip = assetCount > 0 and XUiHelper.FormatText(tip, assetCount) or tip
        self._Control:ShowRightTipPopup(formattedTip)
    end

    return false
end

-- 检测红色买死消耗是否足够
function XUiPanelTheatre4OutpostBoss:CheckRecruitRedCostEnough(isNotTips)
    local cost = self:GetRecruitRedCost()
    local isCostEnough = self._Control.AssetSubControl:CheckAssetEnough(XEnumConst.Theatre4.AssetType.ColorCostPoint, XEnumConst.Theatre4.ColorType.Red, cost, isNotTips)

    if isCostEnough then
        return true
    end

    if not isNotTips then
        local tip = self._Control:GetClientConfig("EffectRecruitRedCostNotEnoughTip", 1)
        self._Control:ShowRightTipPopup(tip)
    end

    return false
end

-- 获取按钮名称
function XUiPanelTheatre4OutpostBoss:GetBtnName(isBtnDisable)
    if self.GridData:IsGridStateExplored() then
        return XUiHelper.GetText("Theatre4EnterBattleBtnName")
    end
    if self.GridData:IsGridStateVisible() then
        return XUiHelper.GetText("Theatre4ExploreVisibleBtnName")
    end
    return isBtnDisable and XUiHelper.GetText("Theatre4NotExploreBtnName") or XUiHelper.GetText("Theatre4ExploreBtnName")
end

-- 探索按钮是否禁用
function XUiPanelTheatre4OutpostBoss:IsBtnExploreDisable()
    if self.GridData:IsGridStateExplored() then
        return false
    end
    if self.GridData:IsGridStateVisible() then
        return true
    end
    -- boss类型不消耗行动点
    if self.GridData:IsGridTypeBoss() then
        return false
    end
    return not self._Control.AssetSubControl:CheckApEnough(true)
end

-- 刷新探索按钮
function XUiPanelTheatre4OutpostBoss:RefreshBtnExplore()
    -- 是否满足繁荣度限制
    local prosperityEnough = self:CheckProsperityEnough(true)
    self.BtnExplore.gameObject:SetActiveEx(prosperityEnough)
    if not prosperityEnough then
        return
    end
    -- 按钮状态
    local isBtnDisable = self:IsBtnExploreDisable()
    self.BtnExplore:SetDisable(isBtnDisable)
    -- 按钮名称
    local btnName = self:GetBtnName(isBtnDisable)
    self.BtnExplore:SetNameByGroup(0, btnName)
    -- 消耗的行动点
    local data = {}
    if not self.GridData:IsGridTypeBoss() and not self.GridData:IsGridStateExplored() then
        data = { { Type = XEnumConst.Theatre4.AssetType.ActionPoint, Cost = XEnumConst.Theatre4.MapExploredCost } }
    end
    self:RefreshCostList(self.BtnExplore, data)
end

-- 招募按钮是否禁用
function XUiPanelTheatre4OutpostBoss:IsBtnRecruitRedDisable()
    --if self.GridData:IsGridStateExplored() then
    --    return not self:CheckRecruitRedCostEnough(true)
    --end
    --if self.GridData:IsGridStateVisible() then
    --    return true
    --end
    --if not self.GridData:IsGridTypeBoss() then
    --    return not self._Control.AssetSubControl:CheckApEnough(true)
    --end
    --return not self:CheckRecruitRedCostEnough(true)
    return false
end

-- 招募按钮是否禁用
function XUiPanelTheatre4OutpostBoss:IsBtnRecruitDisable()
    if self.GridData:IsGridStateExplored() then
        return not self:CheckRecruitCostEnough(true)
    end
    if self.GridData:IsGridStateVisible() then
        return true
    end
    if not self.GridData:IsGridTypeBoss() then
        return not self._Control.AssetSubControl:CheckApEnough(true)
    end
    return not self:CheckRecruitCostEnough(true)
end

-- 刷新招安按钮
function XUiPanelTheatre4OutpostBoss:RefreshBtnRecruit()
    -- 是否满足繁荣度限制
    local prosperityEnough = self:CheckProsperityEnough(true)
    self.BtnRecruit.gameObject:SetActiveEx(prosperityEnough)
    if not prosperityEnough then
        return
    end
    -- 扫荡可用
    local sweepAvailable = self._Control.EffectSubControl:GetEffectMonsterSweepAvailable()
    self.BtnRecruit.gameObject:SetActiveEx(sweepAvailable)
    if not sweepAvailable then
        return
    end
    -- 是否有事件Id 有事件Id时不显示招安按钮
    local eventId = self.GridData:GetGridEventId()
    self.BtnRecruit.gameObject:SetActiveEx(not XTool.IsNumberValid(eventId))
    if XTool.IsNumberValid(eventId) then
        return
    end
    -- 按钮名称
    local btnName = XUiHelper.GetText("Theatre4RecruitBtnName")

    if self._Control.EffectSubControl:GetEffectRedBuyDeadHalfDiscountAvailable() then
        local strHalfDiscount = self._Control:GetClientConfig("EffectRecruitHalfDiscount")
        if strHalfDiscount then
            local value421 = self._Control.EffectSubControl:GetEffectSweepHpDiscount()
            value421 = math.floor(value421 / 100)
            btnName = btnName .. string.format(strHalfDiscount, value421)
        end
    end

    self.BtnRecruit:SetNameByGroup(0, btnName)
    -- 按钮状态
    local isBtnDisable = self:IsBtnRecruitDisable()
    self.BtnRecruit:SetDisable(isBtnDisable)
    -- 消耗的行动点和金币
    local data = { { Type = XEnumConst.Theatre4.AssetType.Gold, Cost = self:GetRecruitCost() } }
    if not self.GridData:IsGridTypeBoss() and not self.GridData:IsGridStateExplored() then
        data[#data + 1] = { Type = XEnumConst.Theatre4.AssetType.ActionPoint, Cost = XEnumConst.Theatre4.MapExploredCost }
    end
    self:RefreshCostList(self.BtnRecruit, data)
end

function XUiPanelTheatre4OutpostBoss:RefreshBtnRecruitRed()
    -- 是否满足繁荣度限制
    local prosperityEnough = self:CheckProsperityEnough(true)
    self.BtnRedOption.gameObject:SetActiveEx(prosperityEnough)
    if not prosperityEnough then
        return
    end
    -- 扫荡可用
    local sweepAvailable = self._Control.EffectSubControl:GetEffectRedBuyDeadAvailable()
    self.BtnRedOption.gameObject:SetActiveEx(sweepAvailable)
    if not sweepAvailable then
        return
    end
    -- 是否有事件Id 有事件Id时不显示招安按钮
    local eventId = self.GridData:GetGridEventId()
    self.BtnRedOption.gameObject:SetActiveEx(not XTool.IsNumberValid(eventId))
    if XTool.IsNumberValid(eventId) then
        return
    end
    -- 按钮名称
    local btnName = XUiHelper.GetText("Theatre4RecruitBtnName")
    self.BtnRedOption:SetNameByGroup(0, btnName)
    -- 按钮状态
    local isBtnDisable = self:IsBtnRecruitRedDisable()
    self.BtnRedOption:SetDisable(isBtnDisable)
    -- 消耗的行动点和金币
    local data = { { Type = XEnumConst.Theatre4.AssetType.ColorCostPoint, Cost = self:GetRecruitRedCost(), AssetId = XEnumConst.Theatre4.ColorType.Red } }
    if not self.GridData:IsGridTypeBoss() and not self.GridData:IsGridStateExplored() then
        data[#data + 1] = { Type = XEnumConst.Theatre4.AssetType.ActionPoint, Cost = XEnumConst.Theatre4.MapExploredCost }
    end
    self:RefreshCostList(self.BtnRedOption, data)
end

-- 刷新消耗列表
---@param btn XUiComponent.XUiButton
---@param data { Type:number, Cost:number }[]
function XUiPanelTheatre4OutpostBoss:RefreshCostList(btn, data)
    local panelBtn = XTool.InitUiObjectByUi({}, btn)
    if XTool.IsTableEmpty(data) then
        panelBtn.PanelItem.gameObject:SetActiveEx(false)
        return
    end
    for i, v in pairs(data) do
        local gridGo = i == 1 and panelBtn.GridIcon or XUiHelper.Instantiate(panelBtn.GridIcon, panelBtn.PanelItem)
        local gridIcon = XTool.InitUiObjectByUi({}, gridGo)
        local icon = self._Control.AssetSubControl:GetAssetIcon(v.Type)
        if icon then
            gridIcon.Icon:SetRawImage(icon)
        end
        gridIcon.Text.text = string.format("-%d", v.Cost)
        -- 刷新消耗文本颜色
        local isEnough = self._Control.AssetSubControl:CheckAssetEnough(v.Type, v.AssetId, v.Cost, true)
        local index = isEnough and 1 or 2
        local color = self._Control:GetClientConfig("AssetNotEnoughTextColor", index)
        if not string.IsNilOrEmpty(color) then
            gridIcon.Text.color = XUiHelper.Hexcolor2Color(color)
        end
    end
end

function XUiPanelTheatre4OutpostBoss:OnBtnExploreClick()
    if not self.GridData then
        return
    end
    if self.GridData:IsGridStateVisible() then
        self._Control:ShowRightTipPopup(XUiHelper.GetText("Theatre4ExploreVisibleTip"))
        return
    end
    local isForbiddenFight = self._Control.EffectSubControl:CheckEffectForbiddenFightType(self.Id, self.Parent.MapId)
    if isForbiddenFight then
        self._Control:ShowRightTipPopup(self._Control:GetClientConfig("EffectForbiddenFight"))
        return
    end
    if self.GridData:IsGridStateDiscover() then
        -- 检查繁荣度是否足够
        if not self:CheckProsperityEnough() then
            return
        end
        -- 检查行动点是否足够 boss类型不消耗行动点
        if not self.GridData:IsGridTypeBoss() and not self._Control.AssetSubControl:CheckApEnough() then
            return
        end
    end
    self.Parent:ExploreGrid()
end

function XUiPanelTheatre4OutpostBoss:OnBtnRecruitClick()
    if not self.GridData then
        return
    end
    if self.GridData:IsGridStateVisible() then
        self._Control:ShowRightTipPopup(XUiHelper.GetText("Theatre4ExploreVisibleTip"))
        return
    end
    local isForbiddenFight, forbiddenType = self._Control.EffectSubControl:CheckEffectForbiddenFightType(self.Id, self.Parent.MapId)
    if isForbiddenFight and forbiddenType == 2 then
        self._Control:ShowRightTipPopup(self._Control:GetClientConfig("EffectForbiddenFight"))
        return
    end
    if self.GridData:IsGridStateDiscover() then
        -- 检查繁荣度是否足够
        if not self:CheckProsperityEnough() then
            return
        end
        -- 检查行动点是否足够 boss类型不消耗行动点
        if not self.GridData:IsGridTypeBoss() and not self._Control.AssetSubControl:CheckApEnough() then
            return
        end
    end
    -- 检查招安消耗是否足够
    if not self:CheckRecruitCostEnough() then
        return
    end
    self.Parent:Recruit()
end

--region 红色买死
function XUiPanelTheatre4OutpostBoss:OnBtnRedOptionClick()
    if not self.GridData then
        return
    end
    if self.GridData:IsGridStateVisible() then
        self._Control:ShowRightTipPopup(XUiHelper.GetText("Theatre4ExploreVisibleTip"))
        return
    end
    local isForbiddenFight, forbiddenType = self._Control.EffectSubControl:CheckEffectForbiddenFightType(self.Id, self.Parent.MapId)
    if isForbiddenFight and forbiddenType == 2 then
        self._Control:ShowRightTipPopup(self._Control:GetClientConfig("EffectForbiddenFight"))
        return
    end
    if self.GridData:IsGridStateDiscover() then
        -- 检查繁荣度是否足够
        if not self:CheckProsperityEnough() then
            return
        end
        -- 检查行动点是否足够 boss类型不消耗行动点
        if not self.GridData:IsGridTypeBoss() and not self._Control.AssetSubControl:CheckApEnough() then
            return
        end
    end
    -- 检查买死值是否足够
    if not self:CheckRecruitRedCostEnough() then
        return
    end
    self.Parent:BuyDieRed()
end

return XUiPanelTheatre4OutpostBoss

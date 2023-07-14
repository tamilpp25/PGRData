local XUiRogueLikeStoryResult = XLuaUiManager.Register(XLuaUi, "UiRogueLikeStoryResult")
local XUiGridBuffInfoItem = require("XUi/XUiFubenRogueLike/XUiGridBuffInfoItem")

function XUiRogueLikeStoryResult:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnConfirm.CallBack = function() self:OnBtnConfirmClick() end

    self.CommonList = {}
    self.BuffList = {}

end

function XUiRogueLikeStoryResult:OnStart(specialEventId, specialEventType)
    self.SpecialEventId = specialEventId
    self.SpecialEventType = specialEventType
    self:HandleSingleSpecialEvent()
    self:HandleMultipleSpecialEvents()
end

function XUiRogueLikeStoryResult:OnEnable()
    XDataCenter.FubenRogueLikeManager.CheckRogueLikeDayResetOnUi("UiRogueLikeStoryResult")
end

-- 单个特殊事件
function XUiRogueLikeStoryResult:HandleSingleSpecialEvent()
    if self.SpecialEventType ~= XFubenRogueLikeConfig.SpecialResultType.SingleEvent then return end
    self.SpecialEventTemplate = XFubenRogueLikeConfig.GetSpecialEventTemplateById(self.SpecialEventId)
    self.SpecialEventConfig = XFubenRogueLikeConfig.GetSpecialEventConfigById(self.SpecialEventId)
    self.SpecialEventType = self.SpecialEventTemplate.Type

    self.TxtResult.text = self.SpecialEventConfig.Description

    self:HandleAddBuff()
    self:HandleRemoveBuff()
    self:HandleAddRobot()
    self:HandleAddHp()
    self:HandleAddActionPoint()
    self:HandleRemoveActionPoint()
    self:HandleGainItem()
    self:HandleExchangeItem()
    self:HandleConsumeItem()
    self:HandleReduceHp()
    self:HandleGainItemRate()
    self:HandleConsumeItemRate()
end

-- 多个特殊事件
function XUiRogueLikeStoryResult:HandleMultipleSpecialEvents()
    if self.SpecialEventType ~= XFubenRogueLikeConfig.SpecialResultType.MultipleEvent then return end
    self.SpecialEventResultInfos = self.SpecialEventId
    local result = ""
    local resultCount = #self.SpecialEventResultInfos

    local commonReward = {}
    local buffReward = {}

    for i = 1, resultCount do
        local resultInfo = self.SpecialEventResultInfos[i]
        local specialEventTemplate = XFubenRogueLikeConfig.GetSpecialEventTemplateById(resultInfo.Id)
        local specialEventConfig = XFubenRogueLikeConfig.GetSpecialEventConfigById(resultInfo.Id)

        local perResult = CS.XTextManager.FormatString(specialEventConfig.Description, resultInfo.Value)
        if specialEventTemplate.Type == XFubenRogueLikeConfig.XRLOtherEventType.AddRobot then
            if XDataCenter.FubenRogueLikeManager.IsAssistRobotFull() then
                perResult = CS.XTextManager.GetText("RogueLikeEventFullRobot")
            end
        end
        if result == "" then
            result = perResult
        else
            result = string.format("%s,%s", result, perResult)
        end

        -- 收集道具、buff奖励
        if specialEventTemplate.Type == XFubenRogueLikeConfig.XRLOtherEventType.ExchangeItem then
            local shopItemId = specialEventTemplate.Param[1]
            local shopItemTemplate = XFubenRogueLikeConfig.GetShopItemTemplateById(shopItemId)
            if shopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Item then
                table.insert(commonReward, {
                    Id = shopItemTemplate.Param[1],
                    Count = shopItemTemplate.Param[2] or 1,
                })
            elseif shopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Buff then
                table.insert(buffReward, shopItemTemplate.Param[1])
            end
        elseif specialEventTemplate.Type == XFubenRogueLikeConfig.XRLOtherEventType.GainItem then
            local paramCount = #specialEventTemplate.Param
            local itemCount = paramCount / 2
            for idx = 1, itemCount do
                table.insert(commonReward, {
                    Id = specialEventTemplate.Param[(idx - 1) * 2 + 1],
                    Count = specialEventTemplate.Param[idx * 2],
                })
            end
        elseif specialEventTemplate.Type == XFubenRogueLikeConfig.XRLOtherEventType.AddBuff then
            for index = 1, #specialEventTemplate.Param do
                table.insert(buffReward, specialEventTemplate.Param[index])
            end
        end

    end
    self.TxtResult.text = result
    -- 展示特殊事件组收集到的奖励
    self:ShowBothTypeReward(commonReward, buffReward)
end

-- 消耗物品百分比
function XUiRogueLikeStoryResult:HandleConsumeItemRate()
    if self.SpecialEventType == XFubenRogueLikeConfig.XRLOtherEventType.ConsumeItemRate then
        self:DontShowReward()
    end
end

-- 获得物品百分比
function XUiRogueLikeStoryResult:HandleGainItemRate()
    if self.SpecialEventType == XFubenRogueLikeConfig.XRLOtherEventType.GainItemRate then
        self:DontShowReward()
    end
end

-- 减少血量
function XUiRogueLikeStoryResult:HandleReduceHp()
    if self.SpecialEventType == XFubenRogueLikeConfig.XRLOtherEventType.ReduceHp then
        self:DontShowReward()
    end
end

-- 消耗物品
function XUiRogueLikeStoryResult:HandleConsumeItem()
    if self.SpecialEventType == XFubenRogueLikeConfig.XRLOtherEventType.ConsumeItem then
        self:DontShowReward()
    end
end

-- 兑换物品
function XUiRogueLikeStoryResult:HandleExchangeItem()
    if self.SpecialEventType == XFubenRogueLikeConfig.XRLOtherEventType.ExchangeItem then
        local shopItemId = self.SpecialEventTemplate.Param[1]
        local shopItemTemplate = XFubenRogueLikeConfig.GetShopItemTemplateById(shopItemId)
        if shopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Item then
            local items = {}
            table.insert(items, {
                Id = shopItemTemplate.Param[1],
                Count = shopItemTemplate.Param[2] or 1,
            })
            self:ShowRewardCommon(items)
        elseif shopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Buff then
            local buffs = {}
            table.insert(buffs, shopItemTemplate.Param[1])
            self:ShowRewardBuff(buffs)

        elseif shopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Robot then
            self:DontShowReward()
        else
            self:DontShowReward()
        end
    end
end

-- 获得物品
function XUiRogueLikeStoryResult:HandleGainItem()
    if self.SpecialEventType == XFubenRogueLikeConfig.XRLOtherEventType.GainItem then
        local items = {}
        local paramCount = #self.SpecialEventTemplate.Param
        local itemCount = paramCount / 2
        for i = 1, itemCount do
            table.insert(items, {
                Id = self.SpecialEventTemplate.Param[(i - 1) * 2 + 1],
                Count = self.SpecialEventTemplate.Param[i * 2],
            })
        end
        self:ShowRewardCommon(items)
    end
end

-- 减少行动点
function XUiRogueLikeStoryResult:HandleRemoveActionPoint()
    if self.SpecialEventType == XFubenRogueLikeConfig.XRLOtherEventType.ActionPoint then
        self:DontShowReward()
    end
end

-- 增加行动点
function XUiRogueLikeStoryResult:HandleAddActionPoint()
    if self.SpecialEventType == XFubenRogueLikeConfig.XRLOtherEventType.AddActionPoint then
        self:DontShowReward()
    end
end

-- 血量恢复
function XUiRogueLikeStoryResult:HandleAddHp()
    if self.SpecialEventType == XFubenRogueLikeConfig.XRLOtherEventType.AddHp then
        self:DontShowReward()
    end
end

-- 获得助战机器人
function XUiRogueLikeStoryResult:HandleAddRobot()
    if self.SpecialEventType == XFubenRogueLikeConfig.XRLOtherEventType.AddRobot then
        self:DontShowReward()
    end
end

-- 移出buff
function XUiRogueLikeStoryResult:HandleRemoveBuff()
    if self.SpecialEventType == XFubenRogueLikeConfig.XRLOtherEventType.RemoveBuff then
        self:DontShowReward()
    end
end

-- 获得buff
function XUiRogueLikeStoryResult:HandleAddBuff()
    if self.SpecialEventType == XFubenRogueLikeConfig.XRLOtherEventType.AddBuff then
        self:ShowRewardBuff(self.SpecialEventTemplate.Param)
    end
end

function XUiRogueLikeStoryResult:DontShowReward()
    self.TextTitle.gameObject:SetActiveEx(false)

    for i = 1, #self.CommonList do
        self.CommonList[i].GameObject:SetActiveEx(false)
    end

    for i = 1, #self.BuffList do
        self.BuffList[i].GameObject:SetActiveEx(false)
    end
end

-- 同时拥有两种奖励
function XUiRogueLikeStoryResult:ShowBothTypeReward(items, buffIds)
    self.TextTitle.gameObject:SetActiveEx(#items > 0 or #buffIds > 0)

    for i = 1, #items do
        if not self.CommonList[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.Grid128)
            ui.transform:SetParent(self.GridReward, false)
            self.CommonList[i] = XUiGridCommon.New(self, ui)
        end
        self.CommonList[i].GameObject:SetActiveEx(true)
        self.CommonList[i]:Refresh(items[i])
    end

    for i = #items + 1, #self.CommonList do
        self.CommonList[i].GameObject:SetActiveEx(false)
    end

    for i = 1, #buffIds do
        if not self.BuffList[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridBuff)
            ui.transform:SetParent(self.GridReward, false)
            self.BuffList[i] = XUiGridBuffInfoItem.New(self, ui)
        end
        self.BuffList[i].GameObject:SetActiveEx(true)
        self.BuffList[i]:SetBuffInfoById(buffIds[i])
    end

    for i = #buffIds + 1, #self.BuffList do
        self.BuffList[i].GameObject:SetActiveEx(false)
    end

end

function XUiRogueLikeStoryResult:ShowRewardBuff(buffIds)
    for i = 1, #self.CommonList do
        self.CommonList[i].GameObject:SetActiveEx(false)
    end
    self.TextTitle.gameObject:SetActiveEx(#buffIds > 0)
    for i = 1, #buffIds do
        if not self.BuffList[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridBuff)
            ui.transform:SetParent(self.GridReward, false)
            self.BuffList[i] = XUiGridBuffInfoItem.New(self, ui)
        end
        self.BuffList[i].GameObject:SetActiveEx(true)
        self.BuffList[i]:SetBuffInfoById(buffIds[i])
    end

    for i = #buffIds + 1, #self.BuffList do
        self.BuffList[i].GameObject:SetActiveEx(false)
    end
end

-- {Id,Count}
function XUiRogueLikeStoryResult:ShowRewardCommon(items)
    for i = 1, #self.BuffList do
        self.BuffList[i].GameObject:SetActiveEx(false)
    end
    self.TextTitle.gameObject:SetActiveEx(#items > 0)
    for i = 1, #items do
        if not self.CommonList[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.Grid128)
            ui.transform:SetParent(self.GridReward, false)
            self.CommonList[i] = XUiGridCommon.New(self, ui)
        end
        self.CommonList[i].GameObject:SetActiveEx(true)
        self.CommonList[i]:Refresh(items[i])
    end

    for i = #items + 1, #self.CommonList do
        self.CommonList[i].GameObject:SetActiveEx(false)
    end
end

function XUiRogueLikeStoryResult:OnBtnBackClick()
    self:Close()
end

function XUiRogueLikeStoryResult:OnBtnConfirmClick()
    self:Close()
end
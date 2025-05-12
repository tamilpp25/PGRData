local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiSpringFestivalSmashEggs = XLuaUiManager.Register(XLua, "UiSpringFestivalSmashEggs")
local XUiGridSpringFestivalSmashEggsReward = require("XUi/XUiSpringFestival/SmashEggs/XUiGridSpringFestivalSmashEggsReward")
local XUiGridSpringFestivalBuffEffectItem = require("XUi/XUiSpringFestival/SmashEggs/XUiGridSpringFestivalBuffEffectItem")
local tableInsert = table.insert
local MODEL_COUNT = 3
local HAMMER_COUNT = 2
local SHOW_TIP_DELAY = 3 * XScheduleManager.SECOND
local SHOW_REWARD_DELAY = 4 * XScheduleManager.SECOND
local HammerPosOffset = {
    x = 0,
    y = 0.1,
    z = 0.2
}

function XUiSpringFestivalSmashEggs:OnStart()
    self:InitSceneRoot()
    self:RegisterButtonClick()
    self.RewardGrid = {}
    self.BuffItemBtn = {}
    self.BuffEffectGrid = {}
    self.CurrentSelectHammer = XDataCenter.SpringFestivalActivityManager.GetCurrHammer()
    self.CurrentSelectBuffItem = XDataCenter.SpringFestivalActivityManager.GetCurrBuffItem()
    self.CurrentSafetyProtect = XDataCenter.SpringFestivalActivityManager.GetCurrSafetyProtect()
    self.SkipAnimation = false
    self.EndTime = XDataCenter.SpringFestivalActivityManager.GetActivityEndTime()
end

function XUiSpringFestivalSmashEggs:OnEnable()
    self:RefreshRemainingTime()
    self:StartTimer()
    local protectId = XSpringFestivalActivityConfigs.GetBuffItemItemId(XSpringFestivalActivityConfigs.BuffItem.Money)
    self.BaodiGrid:SetButtonState(self.CurrentSafetyProtect == 0 and CS.UiButtonState.Normal or CS.UiButtonState.Select)
    self.BaodiGrid:SetRawImage(XDataCenter.ItemManager.GetItemIcon(protectId))
    self.AssetPanel = XUiPanelAsset.New(self, self.BtnShop, XSpringFestivalActivityConfigs.GetScoreConvertItemId())
    local sliverText = self.GridTips01:Find("TxtTips"):GetComponent("Text")
    sliverText.text = XDataCenter.ItemManager.GetItemDescription(XSpringFestivalActivityConfigs.GetBuffItemItemId(XSpringFestivalActivityConfigs.BuffItem.SilverHammer))
    local goldText = self.GridTips02:Find("TxtTips"):GetComponent("Text")
    goldText.text = XDataCenter.ItemManager.GetItemDescription(XSpringFestivalActivityConfigs.GetBuffItemItemId(XSpringFestivalActivityConfigs.BuffItem.GoldHammer))
    self:InitHammerBtnGroup()
    self:InitBuffItemPanel()
    self:Refresh()
    self.BtnHelpCourse.gameObject:SetActiveEx(XSpringFestivalActivityConfigs.GetSmashEggsHelpId() > 0)
    local isShowHelp = XSaveTool.GetData(string.format("%s%s", XSpringFestivalActivityConfigs.SMASH_EGGS_HELP_KEY, XPlayer.Id))
    if not isShowHelp then
        self:ShowHelp()
        XSaveTool.SaveData(string.format("%s%s", XSpringFestivalActivityConfigs.SMASH_EGGS_HELP_KEY, XPlayer.Id), true)
    end
end

function XUiSpringFestivalSmashEggs:OnDisable()
    self:StopTimer()
end

function XUiSpringFestivalSmashEggs:OnDestroy()

end

function XUiSpringFestivalSmashEggs:InitSceneRoot()
    local root = self.UiModelGo.transform
    for i = 1, MODEL_COUNT do
        local model = root:FindTransform("Model" .. i).gameObject
        CS.XShadowHelper.AddShadow(model)
        self["UIMonsterFaint" .. i] = root:FindTransform("UIMonsterFaint" .. i).gameObject
        self["UIMonsterAngry" .. i] = root:FindTransform("UIMonsterAngry" .. i).gameObject
        self["UISuccessed" .. i] = root:FindTransform("UISuccessed" .. i).gameObject
        self["FxUIHammerHit" .. i] = root:FindTransform("FxUIHammerHit" .. i).gameObject
        self["FxHongbao" .. i] = root:FindTransform("FxHongbao" .. i).gameObject
        self["Model" .. i] = model:GetComponent("Animator")
        local inputHandler = model:GetComponent(typeof(CS.XGoInputHandler))
        if not inputHandler then
            inputHandler = model:AddComponent(typeof(CS.XGoInputHandler))
        end
        self["InputHandler" .. i] = inputHandler
    end
    for i = 1, HAMMER_COUNT do
        self["Hammer" .. i] = root:FindTransform("Hammer" .. i):GetComponent("Animator")
        self["Hammer" .. i].gameObject:SetActive(false)
    end
end

function XUiSpringFestivalSmashEggs:OnGetEvents()
    return {
        XEventId.EVENT_SPRING_FESTIVAL_SMASH_EGGS_REFRESH,
    }
end

function XUiSpringFestivalSmashEggs:OnNotify(event, ...)
    if event == XEventId.EVENT_SPRING_FESTIVAL_SMASH_EGGS_REFRESH then
        self:RefreshPanel()
    end
end

function XUiSpringFestivalSmashEggs:RegisterButtonClick()
    self.BtnBack.CallBack = function()
        self:OnClickBackBtn()
    end
    self.BtnMainUi.CallBack = function()
        self:OnClickMainBtn()
    end
    self.BtnSkip.CallBack = function()
        self:OnClickBtnSkipAnimation()
    end
    self.BaodiGrid.CallBack = function()
        self:OnClickBaodiGrid()
    end

    self.BtnExchange.CallBack = function()
        self:OnClickBtnExchange()
    end

    self.BtnShop.CallBack = function()
        self:OnClickBtnShop()
    end

    if self.BtnHelpCourse then
        local template = XHelpCourseConfig.GetHelpCourseTemplateById(XSpringFestivalActivityConfigs.GetSmashEggsHelpId())
        self:BindHelpBtn(self.BtnHelpCourse, template.Function)
    end
    for i = 1, MODEL_COUNT do
        local index = i
        self["InputHandler" .. i]:AddPointerClickListener(function(eventData)
            self:OnClickModel(eventData, index)
        end)
        self["BtnSupply" .. i].CallBack = function()
            self:OnClickBtnSupply(index)
        end
    end
end

function XUiSpringFestivalSmashEggs:OnClickModel(eventData, index)

    if not self:CheckItemCount() then
        XUiManager.TipText("SpringFestivalItemNotEnough")
        return
    end
    if XDataCenter.SpringFestivalActivityManager.CheckIsNeedTip() and self.CurrentSafetyProtect == 0 then
        XUiManager.DialogTip(CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText("SpringFestivalSequenceSuccessTip", XDataCenter.SpringFestivalActivityManager.GetSequenceSuccessCount()), XUiManager.DialogType.Normal, nil, function()
            self:SendSmashRequest(index)
        end)
    else
        self:SendSmashRequest(index)
    end
end

function XUiSpringFestivalSmashEggs:ShowHelp()
    local helpId = XSpringFestivalActivityConfigs.GetSmashEggsHelpId()
    if helpId > 0 then
        local template = XHelpCourseConfig.GetHelpCourseTemplateById(helpId)
        XUiManager.ShowHelpTip(template.Function)
    end
end

function XUiSpringFestivalSmashEggs:SendSmashRequest(index)
    local place = index - 1
    local useItem = {
        Buff = self.CurrentSelectBuffItem,
        Hammer = self.CurrentSelectHammer,
        SafetyProtect = self.CurrentSafetyProtect }
    XDataCenter.SpringFestivalActivityManager.SmashEggRequest(place, useItem, function(isSuccess, rewards, addScore)

        if self.SkipAnimation then
            self:PlaySkipAnimation(index)
        else
            if isSuccess then
                self:PlaySuccessAnimation(index)
            else
                self:PlayFailAnimation(index)
            end
        end
        local tipDelay = not self.SkipAnimation and SHOW_TIP_DELAY or 0
        local rewardDelay = not self.SkipAnimation and SHOW_REWARD_DELAY or 1000
        if not rewards or #rewards == 0 then
            if isSuccess then
                self.TipTimer = XScheduleManager.ScheduleOnce(function ()XUiManager.TipMsg(CsXTextManagerGetText("SpringFestivalSuccessNoItem", addScore))end ,tipDelay)
            else
                if self.CurrentSafetyProtect > 0 then
                    self.TipTimer = XScheduleManager.ScheduleOnce(function()XUiManager.TipMsg(CsXTextManagerGetText("SpringFestivalFailWithProtect"))end,tipDelay)
                else
                    self.TipTimer = XScheduleManager.ScheduleOnce(function()XUiManager.TipMsg(CsXTextManagerGetText("SpringFestivalFailNoItem"))end,tipDelay)
                end
            end
            return
        else
            if isSuccess then
                self.TipTimer = XScheduleManager.ScheduleOnce(function ()XUiManager.TipMsg(CsXTextManagerGetText("SpringFestivalSuccessHasItem", addScore))end ,tipDelay)
            else
                if self.CurrentSafetyProtect > 0 then
                    self.TipTimer = XScheduleManager.ScheduleOnce(function()XUiManager.TipMsg(CsXTextManagerGetText("SpringFestivalFailWithProtectAndItem"))end,tipDelay)
                else
                    self.TipTimer = XScheduleManager.ScheduleOnce(function()XUiManager.TipMsg(CsXTextManagerGetText("SpringFestivalFailHasItem"))end,tipDelay)
                end
            end
            self.RewardTimer = XScheduleManager.ScheduleOnce(function()XUiManager.OpenUiTipReward(rewards,CS.XTextManager.GetText("SpringFestivalGetRewardTitle")) end,rewardDelay)
        end
    end)
end

function XUiSpringFestivalSmashEggs:OnClickBtnSupply(index)
    local list = {}
    for i = 1, MODEL_COUNT do
        tableInsert(list, i - 1)
    end
    XDataCenter.SpringFestivalActivityManager.SmashEggsResetEggsRequest(list, function()
        self:PlayRebornAnimation()
    end)
end

function XUiSpringFestivalSmashEggs:OnClickBaodiGrid()
    local isSelect = self.BaodiGrid:GetToggleState()
    if isSelect then
        self.CurrentSafetyProtect = XSpringFestivalActivityConfigs.BuffItem.Money
    else
        self.CurrentSafetyProtect = 0
    end
    self:RefreshBuffEffectPanel()
end

function XUiSpringFestivalSmashEggs:OnClickBackBtn()
    XLuaUiManager.Close("UiSpringFestivalSmashEggs")
end

function XUiSpringFestivalSmashEggs:OnClickMainBtn()
    XLuaUiManager.RunMain()
end

function XUiSpringFestivalSmashEggs:OnClickBtnExchange()
    XDataCenter.SpringFestivalActivityManager.SmashEggsConvertScoreRequest(function()
        self:PlayAnimation("EffectEnable")
        XUiManager.TipText("SpringFestivalConvertItem")
    end)
end

function XUiSpringFestivalSmashEggs:InitHammerBtnGroup()
    local hammerBtns = {
        self.BtnHammer01,
        self.BtnHammer02,
    }
    self.HammerBtnGroup:Init(hammerBtns, function(index)
        self:OnSelectHammer(index)
    end)
    self.HammerBtnGroup:SelectIndex(self.CurrentSelectHammer)
end

function XUiSpringFestivalSmashEggs:OnSelectHammer(index)
    if index < 0 then
        return
    end
    self:PlayAnimation("GridTipsEnable")
    local hammerList = XSpringFestivalActivityConfigs.GetBuffItemsByType(XSpringFestivalActivityConfigs.BuffType.Hammer)
    self.CurrentSelectHammer = hammerList[index].Id
    self:RefreshBuffEffectPanel()
end

function XUiSpringFestivalSmashEggs:OnClickBtnSkipAnimation()
    self.SkipAnimation = self.BtnSkip:GetToggleState()
end

function XUiSpringFestivalSmashEggs:OnClickBtnShop()
    local skipId = XSpringFestivalActivityConfigs.GetSpringFestivalActivityShopSkipId()
    XFunctionManager.SkipInterface(skipId)
end

function XUiSpringFestivalSmashEggs:Refresh()
    self:RefreshPanel()
    self:RefreshEgg()
end

function XUiSpringFestivalSmashEggs:RefreshPanel()
    self:RefreshRewardList()
    self:RefreshTextInfo()
    self:RefreshBuffItemPanel()
    self:RefreshBuffEffectPanel()
    self:RefreshProtectItem()
    self:RefreshHammerCount()
    self:RefreshProcessBar()
end

function XUiSpringFestivalSmashEggs:RefreshTextInfo()
    local todayScore = XDataCenter.SpringFestivalActivityManager.GetSmashEggsTodayScore()
    if self.TxtDailyActive then
        self.TxtDailyActive.text = todayScore
    end

    local highestScore = XDataCenter.SpringFestivalActivityManager.GetSmashEggsHighestScore()
    if self.TxtIntegralTop then
        self.TxtIntegralTop.text = CS.XTextManager.GetText("SpringFestivalSmashEggsHighestScore", highestScore)
    end

    local currentScore = XDataCenter.SpringFestivalActivityManager.GetSmashEggsCurrentScore()
    if self.TxtIntegral then
        self.TxtIntegral.text = currentScore
    end
end

function XUiSpringFestivalSmashEggs:RefreshEgg()
    local eggList = XDataCenter.SpringFestivalActivityManager.GetSmashEggsEggList()
    local isReborn = true
    for i = 1, #eggList do
        if not eggList[i].IsBroken then
            self:ResetModel(i)
        else
            self["Model" .. i].gameObject:SetActiveEx(false)
            self["BtnSupply" .. i].gameObject:SetActiveEx(true)
        end
        isReborn = isReborn and eggList[i].IsBroken
    end

    if isReborn then
        local list = {}
        for i = 1, MODEL_COUNT do
            tableInsert(list, i - 1)
        end
        XDataCenter.SpringFestivalActivityManager.SmashEggsResetEggsRequest(list, function()
            self:RefreshEgg()
            self:PlayRebornAnimation()
        end)
    end
end

function XUiSpringFestivalSmashEggs:RefreshProtectItem()
    local itemId = XSpringFestivalActivityConfigs.GetBuffItemItemId(XSpringFestivalActivityConfigs.BuffItem.Money)
    local itemCount = XDataCenter.ItemManager.GetCount(itemId)
    self.BaodiGrid:SetName(itemCount)
end

function XUiSpringFestivalSmashEggs:RefreshBuffEffectPanel()
    local buffList = {
        self.CurrentSelectBuffItem,
        self.CurrentSafetyProtect
    }
    local isEmpty = true
    for i = 1, #buffList do
        local grid = self.BuffEffectGrid[i]
        if not grid then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridEffect, self.Content)
            grid = XUiGridSpringFestivalBuffEffectItem.New(obj)
            self.BuffEffectGrid[i] = grid
        end
        grid:Refresh(buffList[i])
        isEmpty = buffList[i] == 0 and isEmpty
    end
    self.ImgEmpty.gameObject:SetActiveEx(isEmpty)
end

function XUiSpringFestivalSmashEggs:InitBuffItemPanel()
    local buffItems = XSpringFestivalActivityConfigs.GetBuffItemsByType(XSpringFestivalActivityConfigs.BuffType.Additive)
    local defaultSelect = -1
    for i = 1, #buffItems do
        local buffItemsButton = self.BuffItemBtn[i]
        if not buffItemsButton then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridProp, self.PanelProp)
            obj.gameObject:SetActiveEx(true)
            buffItemsButton = obj:GetComponent("XUiButton")
            local itemIcon = XDataCenter.ItemManager.GetItemIcon(buffItems[i].ItemId)
            buffItemsButton:SetRawImage(itemIcon)
            local itemCount = XDataCenter.ItemManager.GetCount(buffItems[i].ItemId)
            buffItemsButton:SetName(itemCount)
            tableInsert(self.BuffItemBtn, buffItemsButton)
        end
        if buffItems[i].Id == self.CurrentSelectBuffItem then
            defaultSelect = i
        end
    end
    self.BuffItemBtnGroup:Init(self.BuffItemBtn, function(index)
        self:OnSelectBuffItem(index)
    end)
    if self.BuffItemBtnGroup.CurSelectId ~= defaultSelect then
        if defaultSelect == -1 then
            self.BuffItemBtnGroup:CancelSelect()
            self.CurrentSelectBuffItem = 0
        else
            self.BuffItemBtnGroup:SelectIndex(defaultSelect)
        end
    end
end

function XUiSpringFestivalSmashEggs:RefreshBuffItemPanel()
    local buffItems = XSpringFestivalActivityConfigs.GetBuffItemsByType(XSpringFestivalActivityConfigs.BuffType.Additive)
    for i = 1, #self.BuffItemBtn do
        local itemCount = XDataCenter.ItemManager.GetCount(buffItems[i].ItemId)
        self.BuffItemBtn[i]:SetName(itemCount)
    end
end

function XUiSpringFestivalSmashEggs:RefreshHammerCount()
    local silverHammer = XSpringFestivalActivityConfigs.GetBuffItemItemId(XSpringFestivalActivityConfigs.BuffItem.SilverHammer)
    local goldHammer = XSpringFestivalActivityConfigs.GetBuffItemItemId(XSpringFestivalActivityConfigs.BuffItem.GoldHammer)
    local silverCount = XDataCenter.ItemManager.GetCount(silverHammer)
    local goldCount = XDataCenter.ItemManager.GetCount(goldHammer)
    self.BtnHammer01:SetNameByGroup(1, silverCount)
    self.BtnHammer02:SetNameByGroup(1, goldCount)
end

function XUiSpringFestivalSmashEggs:RefreshProcessBar()
    local today = XDataCenter.SpringFestivalActivityManager.GetSmashEggsTodayScore()
    local day = XDataCenter.SpringFestivalActivityManager.GetSmashEggsActivityDay()
    local rewardList = XSpringFestivalActivityConfigs.GetSmashRewardTemplateByNowDay(day)
    table.sort(rewardList, function(a, b)
        return a.Index < b.Index
    end)
    --分段计算实际进度条，适配不按比例的目标分数
    local process = 0
    local preValue = 0
    for i = 1, #rewardList do
        if today <= 0 then
            break
        end
        local offset = rewardList[i].TargetScore - preValue
        local pow = 1 / (#rewardList * offset)
        if today < offset then
            process = process + today * pow
        else
            process = process + offset * pow
        end
        preValue = rewardList[i].TargetScore
        today = today - offset
    end

    self.ImgDailyActiveProgress.fillAmount = process / 1
end

function XUiSpringFestivalSmashEggs:OnSelectBuffItem(index)
    local buffItems = XSpringFestivalActivityConfigs.GetBuffItemsByType(XSpringFestivalActivityConfigs.BuffType.Additive)
    local isSelect = self.BuffItemBtn[index]:GetToggleState()
    if isSelect then
        self.CurrentSelectBuffItem = buffItems[index].Id
    else
        self.CurrentSelectBuffItem = 0
    end
    self:RefreshBuffEffectPanel()
end

function XUiSpringFestivalSmashEggs:RefreshRewardList()
    local day = XDataCenter.SpringFestivalActivityManager.GetSmashEggsActivityDay()
    local rewardList = XSpringFestivalActivityConfigs.GetSmashRewardTemplateByNowDay(day)
    table.sort(rewardList, function(a, b)
        return a.Index > b.Index
    end)
    for i = 1, #rewardList do
        local grid = self.RewardGrid[i]
        if not grid then
            local obj = CS.UnityEngine.Object.Instantiate(self.PanelActive, self.PanelGift)
            obj.gameObject:SetActiveEx(true)
            grid = XUiGridSpringFestivalSmashEggsReward.New(obj, function()
                self:RefreshPanel()
            end)
            self.RewardGrid[i] = grid
        end
        grid:Refresh(rewardList[i])
    end
end

function XUiSpringFestivalSmashEggs:PlaySuccessAnimation(index)
    local modelAnimator = self["Model" .. index]
    local hammerAnimator = self["Hammer" .. self.CurrentSelectHammer]
    local faintEffect = self["UIMonsterFaint" .. index]
    local successEffect = self["UISuccessed" .. index]
    local effect = self["FxUIHammerHit" .. index]
    local hongbaoEffect = self["FxHongbao" .. index]
    local modelPos = modelAnimator.transform.position
    hammerAnimator.transform.position = CS.UnityEngine.Vector3(modelPos.x + HammerPosOffset.x, modelPos.y + HammerPosOffset.y, modelPos.z + HammerPosOffset.z)
    XLuaUiManager.SetMask(true)
    XScheduleManager.ScheduleOnce(function()
        hammerAnimator.gameObject:SetActive(true)
        hammerAnimator:Play("Break")
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XSpringFestivalActivityConfigs.SmashSoundId.HammerSuccess)
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XSpringFestivalActivityConfigs.SmashSoundId.EggSuccess)
        effect:SetActiveEx(true)
    end, 100)
    XScheduleManager.ScheduleOnce(function()
        hammerAnimator.gameObject:SetActive(false)
    end,1000)
    XScheduleManager.ScheduleOnce(function()
        self["BtnSupply" .. index].gameObject:SetActiveEx(true)
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XSpringFestivalActivityConfigs.SmashSoundId.SuccessEffectSound)
        successEffect:SetActiveEx(true)
        hongbaoEffect:SetActiveEx(true)
        modelAnimator.gameObject:SetActiveEx(false)
    end, 3000)
    faintEffect:SetActiveEx(true)
    modelAnimator:Play("UIFaint")

    XScheduleManager.ScheduleOnce(function()
        XLuaUiManager.SetMask(false)
        self:RefreshEgg()
    end, 4000)
end

function XUiSpringFestivalSmashEggs:PlayFailAnimation(index)
    local modelAnimator = self["Model" .. index]
    local hammerAnimator = self["Hammer" .. self.CurrentSelectHammer]
    local angryEffect = self["UIMonsterAngry" .. index]
    local modelPos = modelAnimator.transform.position
    hammerAnimator.transform.position = CS.UnityEngine.Vector3(modelPos.x + HammerPosOffset.x, modelPos.y + HammerPosOffset.y, modelPos.z + HammerPosOffset.z)
    XLuaUiManager.SetMask(true)
    XScheduleManager.ScheduleOnce(function()
        hammerAnimator.gameObject:SetActive(true)
        hammerAnimator:Play("Break")
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XSpringFestivalActivityConfigs.SmashSoundId.HammerFail)
    end, 200)
    XScheduleManager.ScheduleOnce(function()
        hammerAnimator.gameObject:SetActive(false)
    end,1000)
    XScheduleManager.ScheduleOnce(function()
        modelAnimator.gameObject:SetActiveEx(false)
        self["BtnSupply" .. index].gameObject:SetActiveEx(true)
    end, 3000)
    angryEffect:SetActiveEx(true)
    modelAnimator:Play("UIGainst")
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XSpringFestivalActivityConfigs.SmashSoundId.EggFail)
    XScheduleManager.ScheduleOnce(function()
        XLuaUiManager.SetMask(false)
        self:RefreshEgg()
    end, 4000)
end

function XUiSpringFestivalSmashEggs:PlayRebornAnimation()
    for i = 1, MODEL_COUNT do
        self:ResetModel(i)
    end
end

function XUiSpringFestivalSmashEggs:ResetModel(i)
    self["UIMonsterFaint" .. i]:SetActiveEx(false)
    self["UIMonsterAngry" .. i]:SetActiveEx(false)
    self["UISuccessed" .. i]:SetActiveEx(false)
    self["FxUIHammerHit" .. i]:SetActiveEx(false)
    self["FxHongbao" .. i]:SetActiveEx(false)
    self["Model" .. i].gameObject:SetActiveEx(true)
    self["BtnSupply" .. i].gameObject:SetActiveEx(false)
end

function XUiSpringFestivalSmashEggs:PlaySkipAnimation(index)
    self["Model" .. index].gameObject:SetActiveEx(false)
    self["BtnSupply" .. index].gameObject:SetActiveEx(true)
    self:RefreshEgg()
end

function XUiSpringFestivalSmashEggs:StartTimer()
    if self.Timer then
        self:StopTimer()
    end
    self.Timer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.TxtTime) then
            self:StopTimer()
            return
        end
        local currentTime = XTime.GetServerNowTimestamp()
        if currentTime > self.EndTime then
            XDataCenter.SpringFestivalActivityManager.OnActivityEnd()
            return
        end
        self:RefreshRemainingTime()
    end, XScheduleManager.SECOND)
end

function XUiSpringFestivalSmashEggs:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
    if self.TipTimer then
        XScheduleManager.UnSchedule(self.TipTimer)
        self.TipTimer = nil
    end
    if self.RewardTimer then
        XScheduleManager.UnSchedule(self.RewardTimer)
        self.RewardTimer = nil
    end
end

function XUiSpringFestivalSmashEggs:RefreshRemainingTime()
    local endTime = XDataCenter.SpringFestivalActivityManager.GetActivityEndTime()
    local startTime = XDataCenter.SpringFestivalActivityManager.GetActivityStartTime()
    local now = XTime.GetServerNowTimestamp()
    local offset = XMath.Clamp(endTime - now, 0, endTime - startTime)
    self.TxtTime.text = XUiHelper.GetTime(offset, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiSpringFestivalSmashEggs:CheckItemCount()
    local buffCount = self.CurrentSelectBuffItem == 0 and 0 or XDataCenter.ItemManager.GetCount(XSpringFestivalActivityConfigs.GetBuffItemItemId(self.CurrentSelectBuffItem))
    local protectCount = self.CurrentSafetyProtect == 0 and 0 or XDataCenter.ItemManager.GetCount(XSpringFestivalActivityConfigs.GetBuffItemItemId(self.CurrentSafetyProtect))
    local hammerCount = self.CurrentSelectHammer == 0 and 0 or XDataCenter.ItemManager.GetCount(XSpringFestivalActivityConfigs.GetBuffItemItemId(self.CurrentSelectHammer))

    return (self.CurrentSelectBuffItem == 0 or buffCount > 0) and (self.CurrentSafetyProtect == 0 or protectCount > 0) and (self.CurrentSelectHammer == 0 or
            hammerCount > 0)
end

return XUiSpringFestivalSmashEggs
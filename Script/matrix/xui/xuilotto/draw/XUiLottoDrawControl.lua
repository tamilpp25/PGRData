local characterRecord = require("XUi/XUiDraw/XUiDrawTools/XUiDrawCharacterRecord")
---@class XUiLottoDrawControl:XUiNode
local XUiLottoDrawControl = XClass(XUiNode, "XUiLottoDrawControl")

---@param lottoGroupData XLottoGroupEntity
function XUiLottoDrawControl:OnStart(lottoGroupData)
    --self._RewardList = {
    --    [1] = {
    --        ["ConvertFrom"] = 0,
    --        ["RewardType"] = 1,
    --        ["TemplateId"] = 6002306,
    --        ["SpecialDrawEffectGroupId"] = 16,
    --        ["Quality"] = 0,
    --        ["Breakthrough"] = 0,
    --        ["Id"] = 0,
    --        ["Grade"] = 0,
    --        ["Count"] = 120,
    --        ["Level"] = 0,
    --    },
    --}

    --self._ExtraRewardList = {
    --    [1] = {
    --        ["ConvertFrom"] = 0,
    --        ["RewardType"] = 10,
    --        ["TemplateId"] = 9010253,
    --        ["Quality"] = 0,
    --        ["Breakthrough"] = 0,
    --        ["Id"] = 0,
    --        ["Grade"] = 0,
    --        ["Count"] = 1,
    --        ["Level"] = 0,
    --    },
    --}
    self._IsCanDraw = true
    ---@type XLottoGroupEntity
    self._LottoGroupData = lottoGroupData
    self._IsAfterDrawAim = false
    self._IsAfterShowDrawResult = false
end

--region Record
function XUiLottoDrawControl:_DrawRecord()
    characterRecord.Record()
end
--endregion

--region Draw
---@return boolean 是否抽奖成功
function XUiLottoDrawControl:OnBtnDrawClick()
    if self:_CheckCanDraw() then
        self:_OnDraw()
        return true
    end
    return false
end

function XUiLottoDrawControl:_CheckCanDraw()
    if XMVCA.XEquip:CheckBoxOverLimitOfDraw() then
        return false
    end
    local drawData = self._LottoGroupData:GetDrawData()
    if drawData:IsLottoCountFinish() then
        return false
    end
    local curItemCount = XDataCenter.ItemManager.GetItem(drawData:GetConsumeId()).Count
    local needItemCount = drawData:GetConsumeCount()
    if needItemCount > curItemCount then
        XLuaUiManager.Open("UiLottoTanchuang", drawData)
        return false
    end
    return true
end

function XUiLottoDrawControl:GetLottoId()
    return self._LottoGroupData:GetDrawData():GetId()
end

function XUiLottoDrawControl:_OnDraw()
    self:_DrawRecord()
    local drawData = self._LottoGroupData:GetDrawData()
    XDataCenter.LottoManager.DoLotto(drawData:GetId(), function(rewardList, extraRewardList, lottoRewardId)
        XDataCenter.AntiAddictionManager.BeginDrawCardAction()
        local lottoRewardEntity = self._LottoGroupData:GetDrawData():GetRewardDataById(lottoRewardId)
        self._LottoRewardId = lottoRewardId
        self._ExtraRewardList = extraRewardList
        self._RewardList = XDataCenter.LottoManager.HandleDrawShowRewardEffect(rewardList, lottoRewardEntity:GetShowEffectId())
        XEventManager.DispatchEvent(XEventId.EVENT_LOTTO_DRAW_ON_START, lottoRewardEntity:GetShowTimeLineName())
    end, function()
        XLog.Error("[Error]XUiLottoDrawControl:_OnDraw():抽卡失败")
    end)
end
--endregion

--region DrawResult
function XUiLottoDrawControl:GetShowResult()
    return self._RewardList
end

function XUiLottoDrawControl:GetShowResultLottoRewardId()
    return self._LottoRewardId
end

function XUiLottoDrawControl:ShowDrawResult()
    if XTool.IsTableEmpty(self._RewardList) then
        return
    end
    local drawData = self._LottoGroupData:GetDrawData()
    if self._IsAfterDrawAim then
        return
    end
    self._IsAfterDrawAim = true
    XLuaUiManager.Open("UiDrawShowNew", drawData, self._RewardList, nil, 1, function()
        self._IsAfterShowDrawResult = true
        self._IsAfterDrawAim = false
    end)
end

function XUiLottoDrawControl:ShowRewardDialog(panelType)
    if self._IsAfterShowDrawResult then
        local asynOpen = asynTask(XLuaUiManager.Open)
        RunAsyn(function()
            self:_OnShowFashionRewardList(asynOpen, panelType)
            self:_OnShowExtraRewardList(asynOpen, panelType)
        end)
        self._IsAfterShowDrawResult = false
    end
end

function XUiLottoDrawControl:_OnShowFashionRewardList(asynOpen, panelType)
    if XTool.IsTableEmpty(self._RewardList) then
        return
    end
    local drawData = self._LottoGroupData:GetDrawData()
    local lottoRewardEntity = drawData:GetRewardDataById(self._LottoRewardId)
    local rewardId = drawData:GetCoreRewardTemplateId()
    local isSame = false
    for _, v in pairs(self._RewardList) do
        if v.TemplateId == rewardId then
            if panelType == XEnumConst.Lotto.Karenina then
                asynOpen("UiLottoKareninaPassport", v)
            elseif panelType == XEnumConst.Lotto.Luna then
                asynOpen("UiLottoLunaPassport", v)
            elseif panelType == XEnumConst.Lotto.Lifu then
                asynOpen("UiLottoLifuPassport", v)
            elseif panelType == XEnumConst.Lotto.Vera then
                asynOpen("UiLottoVeraPassport", v)
            else
                XLog.Error("快速使用角色涂装弹框未接入. PanelType=" .. panelType)
            end
        end
        if XDataCenter.ItemManager.IsWeaponFashion(v.TemplateId) then
            if panelType == XEnumConst.Lotto.Karenina then
                asynOpen("UiLottoKareninaQuickWear", v.TemplateId)
            elseif panelType == XEnumConst.Lotto.Luna then
                asynOpen("UiLottoLunaQuickWear", v.TemplateId)
            elseif panelType == XEnumConst.Lotto.Lifu then
                asynOpen("UiLottoLifuQuickWear", v.TemplateId)
            elseif panelType == XEnumConst.Lotto.Vera then
                asynOpen("UiLottoVeraQuickWear", v.TemplateId)
            else
                XLog.Error("快速使用弹框未接入. PanelType=" .. panelType)
            end
        end
        if v.TemplateId == lottoRewardEntity:GetTemplateId() then
            isSame = true
        end
    end
    if not isSame then
        asynOpen("UiObtain", self._RewardList, nil) -- UiObtain的第三个参数是closeBack
    end
    self._RewardList = nil
    self._LottoRewardId = nil
end

function XUiLottoDrawControl:_OnShowExtraRewardList(asynOpen, panelType)
    if XTool.IsTableEmpty(self._ExtraRewardList) then
        return
    end
    -- 使用头像弹框
    for _, v in pairs(self._ExtraRewardList) do
        if XDataCenter.HeadPortraitManager.IsHeadPortraitValid(v.TemplateId) then
            if panelType == XEnumConst.Lotto.Karenina then
                asynOpen("UiLottoKareninaQuickWear", v.TemplateId)
            elseif panelType == XEnumConst.Lotto.Luna then
                asynOpen("UiLottoLunaQuickWear", v.TemplateId)
            elseif panelType == XEnumConst.Lotto.Lifu then
                asynOpen("UiLottoLifuQuickWear", v.TemplateId)
            elseif panelType == XEnumConst.Lotto.Vera then
                asynOpen("UiLottoVeraQuickWear", v.TemplateId)
            else
                XLog.Error("快速使用弹框未接入. PanelType=" .. panelType)
            end
            self._ExtraRewardList = nil
            return
        end
    end
    asynOpen("UiObtain", self._ExtraRewardList, nil)
    self._ExtraRewardList = nil
end
--endregion

return XUiLottoDrawControl
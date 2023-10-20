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
    self._IsAfterShowDrawResult = false
end

--region Record
function XUiLottoDrawControl:_DrawRecord()
    characterRecord.Record()
end
--endregion

--region Draw
function XUiLottoDrawControl:OnBtnDrawClick()
    if self:_CheckCanDraw() then
        self:_OnDraw()
    end
end

function XUiLottoDrawControl:_CheckCanDraw()
    if XDataCenter.EquipManager.CheckBoxOverLimitOfDraw() then
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

function XUiLottoDrawControl:_OnDraw()
    self:_DrawRecord()
    local drawData = self._LottoGroupData:GetDrawData()
    XDataCenter.LottoManager.DoLotto(drawData:GetId(), function(rewardList, extraRewardList, lottoRewardId)
        XDataCenter.AntiAddictionManager.BeginDrawCardAction()
        local lottoRewardEntity = self._LottoGroupData:GetDrawData():GetRewardDataById(lottoRewardId)
        self._ExtraRewardList = extraRewardList
        self._RewardList = XDataCenter.LottoManager.HandleDrawShowRewardEffect(rewardList, lottoRewardEntity:GetShowEffectId())
        XEventManager.DispatchEvent(XEventId.EVENT_LOTTO_DRAW_ON_START, lottoRewardEntity:GetShowTimeLineName())
    end, function()
        XLog.Error("[Error]XUiLottoDrawControl:_OnDraw():抽卡失败")
    end)
end
--endregion

--region DrawResult
function XUiLottoDrawControl:ShowDrawResult()
    if XTool.IsTableEmpty(self._RewardList) then
        return
    end
    local drawData = self._LottoGroupData:GetDrawData()
    XLuaUiManager.Open("UiDrawShowNew", drawData, self._RewardList, nil, 1, function()
        self._IsAfterShowDrawResult = true
    end)
end

function XUiLottoDrawControl:ShowRewardDialog()
    if self._IsAfterShowDrawResult then
        self:_OnShowFashionRewardList()
        self:_OnShowExtraRewardList()
        self._IsAfterShowDrawResult = false
    end
end

function XUiLottoDrawControl:_OnShowFashionRewardList()
    if XTool.IsTableEmpty(self._RewardList) then
        return
    end
    local drawData = self._LottoGroupData:GetDrawData()
    local rewardId = drawData:GetCoreRewardTemplateId()
    for _, v in pairs(self._RewardList) do
        if v.TemplateId == rewardId then
            XDataCenter.UiQueueManager.Open("UiEpicFashionGachaQuickWear", rewardId, XUiHelper.GetText("LottoKareninaFashionTip"))
            self._RewardList = nil
        end
    end
end

function XUiLottoDrawControl:_OnShowExtraRewardList()
    if XTool.IsTableEmpty(self._ExtraRewardList) then
        return
    end
    XDataCenter.UiQueueManager.CallFunc("UiObtain", XUiManager.OpenUiObtain, self._ExtraRewardList)
    self._ExtraRewardList = nil
end
--endregion

return XUiLottoDrawControl
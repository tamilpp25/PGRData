local handler = handler
local CSXTextManagerGetText = CS.XTextManager.GetText
local Lerp = CS.UnityEngine.Mathf.Lerp
local mathFloor = math.floor
local CSXScheduleManagerUnSchedule = XScheduleManager.UnSchedule

local SCORE_ANIM_DURATION = 0.5--分数滚动动画时间
local CONDITION_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("59f5ffff"),
    [false] = XUiHelper.Hexcolor2Color("0E70BDFF"),
}

local stringGsub = string.gsub

local XUiGridTRPGTestRole = XClass(nil, "XUiGridTRPGTestRole")

function XUiGridTRPGTestRole:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self.BtnClick.CallBack = clickCb
    self.BtnReset.CallBack = handler(self, self.OnClickBtnReset)
end

function XUiGridTRPGTestRole:Refresh(roleId, actionId, addAttribute, needScoreChangeAnim, needEffect)
    self.RoleId = roleId
    self.ActionId = actionId

    local score = XDataCenter.TRPGManager.GetCurExamineRoleScore(roleId)
    if score == 0 then
        self.TxtAttributeNumber.gameObject:SetActiveEx(false)
        self.TxtDoubt.gameObject:SetActiveEx(true)
    else
        self.TxtDoubt.gameObject:SetActiveEx(false)
        self.TxtAttributeNumber.gameObject:SetActiveEx(true)
        if needScoreChangeAnim then
            local startScore = tonumber(self.TxtAttributeNumber.text) or 0
            self:LetScoreRoll(startScore, score)
        else
            self.TxtAttributeNumber.text = score
        end
    end

    local roleIcon = XTRPGConfigs.GetRoleHeadIcon(roleId)
    self.RImgRole:SetRawImage(roleIcon)

    local icon = XTRPGConfigs.GetExamineActionIcon(actionId)
    self.BtnClick:SetRawImage(icon)

    local attributeType = XTRPGConfigs.GetExamineActionNeedAttrType(actionId)
    local minValue = XDataCenter.TRPGManager.GetRoleAttributeMinRollValue(roleId, attributeType)
    local maxValue = XDataCenter.TRPGManager.GetRoleAttributeMaxRollValue(roleId, attributeType)
    if addAttribute > 0 then
        minValue = minValue + addAttribute
        maxValue = maxValue + addAttribute
    end
    local rangeStr = minValue .. "~" .. maxValue
    local passCondition = addAttribute and addAttribute > 0 or false
    local color = CONDITION_COLOR[passCondition]
    self.BtnClick:SetNameAndColorByGroup(0, rangeStr, color)

    local isRolled = XDataCenter.TRPGManager.IsExamineRoleAlreadyRolled(roleId)
    self.BtnReset.gameObject:SetActiveEx(isRolled)

    if needEffect then
        self.Effect.gameObject:SetActiveEx(false)
        self.Effect.gameObject:SetActiveEx(true)
    end
end

function XUiGridTRPGTestRole:OnClickBtnReset()
    local roleId = self.RoleId
    local actionId = self.ActionId

    local costItemId, costItemCount = XTRPGConfigs.GetExamineActionResetCostItemInfo(actionId)
    if not XDataCenter.ItemManager.CheckItemCountById(costItemId, costItemCount) then
        XUiManager.TipText("TRPGExploreExmaineResetLackItem")
        return
    end

    local curRoleScore = XDataCenter.TRPGManager.GetCurExamineRoleScore(roleId)
    if curRoleScore == 0 then
        XUiManager.TipText("TRPGExploreExmaineResetDoNotNeed")
        return
    end

    local itemName = XDataCenter.ItemManager.GetItemName(costItemId)
    local itemCount = XDataCenter.ItemManager.GetCount(costItemId)
    local title = CSXTextManagerGetText("TRPGExploreExmaineResetTipsTitle")
    local content = CSXTextManagerGetText("TRPGExploreExmaineResetTipsContent", itemName, costItemCount, itemCount)
    content = stringGsub(content, "\\n", "\n")
    local callFunc = function()
        XDataCenter.TRPGManager.TRPGExamineCharacterResetRequest(roleId)
        
    end
    XUiManager.SystemDialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
end

function XUiGridTRPGTestRole:SetSelect(value)
    if self._IsDisable then return end
    self._IsSelect = value

    self.BtnClick:SetButtonState(value and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiGridTRPGTestRole:IsDisable()
    return self._IsDisable or false
end

function XUiGridTRPGTestRole:SetDisable(value)
    self._IsDisable = value

    local originStatus = self._IsSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal
    self.BtnClick:SetButtonState(value and CS.UiButtonState.Disable or originStatus)

    self.RImgRole.gameObject:SetActiveEx(not value)
end

function XUiGridTRPGTestRole:LetScoreRoll(startScore, targetScore)
    if not startScore or not targetScore then return end

    local onRefreshFunc = function(time)
        if XTool.UObjIsNil(self.TxtAttributeNumber) then
            self:DestroyTimer()
            return true
        end

        if startScore == targetScore then
            return true
        end

        self.TxtAttributeNumber.text = mathFloor(Lerp(startScore, targetScore, time))
    end

    self:DestroyTimer()
    self.Timer = XUiHelper.Tween(SCORE_ANIM_DURATION, onRefreshFunc)
end

function XUiGridTRPGTestRole:DestroyTimer()
    if self.Timer then
        CSXScheduleManagerUnSchedule(self.Timer)
        self.Timer = nil
    end
end

return XUiGridTRPGTestRole
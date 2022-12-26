local XUiGridTRPGTestItem = require("XUi/XUiTRPG/XUiGridTRPGTestItem")
local XUiGridTRPGTestRole = require("XUi/XUiTRPG/XUiGridTRPGTestRole")
local XUiGridTRPGRoleDetail = require("XUi/XUiTRPG/XUiGridTRPGRoleDetail")

local CSXTextManagerGetText = CS.XTextManager.GetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local stringGsub = string.gsub
local Lerp = CS.UnityEngine.Mathf.Lerp
local mathFloor = math.floor
local tonumber = tonumber
local CSXScheduleManagerUnSchedule = XScheduleManager.UnSchedule
local CSXScheduleManagerScheduleOnce = XScheduleManager.ScheduleOnce

local MAX_ROLE_NUM = 4
local SCORE_ANIM_DURATION = 1

local XUiTRPGTest = XLuaUiManager.Register(XLuaUi, "UiTRPGTest")

function XUiTRPGTest:OnAwake()
    self:AutoAddListener()
    self.GridChoose.gameObject:SetActiveEx(false)
    self.GridRoleAttribute.gameObject:SetActiveEx(false)
    self.GridTrackRole.gameObject:SetActiveEx(false)
end

function XUiTRPGTest:OnStart(examineId)
    self.SelectRoleIndex = 1
    self.RoleGrids = {}
    self.TrackRoleGrids = {}

    self:InitUi()
end

function XUiTRPGTest:OnEnable()
    self:UpdateUi()
end

function XUiTRPGTest:OnDisable()
    self:DestroyTimer()
    self:DestroyEffectTimer()
end

function XUiTRPGTest:OnDestroy()
    XDataCenter.TRPGManager.FinishExamine()
end

function XUiTRPGTest:OnGetEvents()
    return {
        XEventId.EVENT_TRPG_EXAMINE_DATA_CHANGE
        , XEventId.EVENT_TRPG_ROLES_DATA_CHANGE
        , XEventId.EVENT_TRPG_EXAMINE_ROUND_CHANGE
        , XEventId.EVENT_TRPG_EXAMINE_RESULT_SYN
    }
end

function XUiTRPGTest:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_TRPG_EXAMINE_DATA_CHANGE then
        self.SelectRoleIndex = self:GetNextRoleIndex()
        self.NeedScoreChangeAnim = true
        self:UpdateUi()
    elseif evt == XEventId.EVENT_TRPG_ROLES_DATA_CHANGE then
        self:UpdateTrackRoles()
    elseif evt == XEventId.EVENT_TRPG_EXAMINE_ROUND_CHANGE then
        self.SelectRoleIndex = 1
        self:UpdateUi()
    elseif evt == XEventId.EVENT_TRPG_EXAMINE_RESULT_SYN then
        self:UpdateUi()
    end
end

function XUiTRPGTest:GetNextRoleIndex()
    local paramIndex = self.SelectRoleIndex

    for index, roleId in ipairs(self.RoleIds) do
        if not XDataCenter.TRPGManager.IsExamineRoleAlreadyRolled(roleId) then
            paramIndex = index
            break
        end
    end

    return paramIndex
end

function XUiTRPGTest:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelChoose)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridTRPGTestItem)
end

function XUiTRPGTest:UpdateUi()
    local examineId = XDataCenter.TRPGManager.GetCurExamineId()
    self.ExamineId = examineId

    local actionId = XDataCenter.TRPGManager.GetCurExamineActionId()
    self.ActionId = actionId

    local icon = XTRPGConfigs.GetExamineActionIcon(actionId)
    self.RImgAttributeIcon:SetRawImage(icon)

    local des = XTRPGConfigs.GetExamineActionTypeDesc(actionId)
    self.TxtAttribute.text = des

    local desEn = XTRPGConfigs.GetExamineActionTypeDescEn(actionId)
    self.TxtAttribute2.text = desEn

    local curScore, reqScore = XDataCenter.TRPGManager.GetCurExamineCurAndReqScore()
    local fillAmount = reqScore == 0 and 1 or curScore / reqScore
    local targetScore = curScore > reqScore and reqScore or curScore
    if self.NeedScoreChangeAnim then
        self:LetScoreRoll(targetScore, fillAmount)
    else
        self.TxtJdNumber.text = targetScore
        self.ImgJd.fillAmount = fillAmount
    end
    self.TxtJd.text = "/" .. reqScore

    local isPassed = XDataCenter.TRPGManager.IsExaminePassed()
    self.ImgJdSuc.gameObject:SetActiveEx(isPassed)
    self.ImgJdFail.gameObject:SetActiveEx(not isPassed)

    local curRound = XDataCenter.TRPGManager.GetCurExamineCurRound()
    local maxRound = XTRPGConfigs.GetExamineActionRound(actionId)
    self.TxtRound.text = curRound .. "/" .. maxRound

    local resetItemId = XTRPGConfigs.GetExamineActionResetCostItemInfo(actionId)
    local icon = XItemConfigs.GetItemIconById(resetItemId)
    self.RImgIconResetItem:SetRawImage(icon)
    local haveCount = XDataCenter.ItemManager.GetCount(resetItemId)
    self.TxtResetItemNum.text = haveCount
    local name = XItemConfigs.GetItemNameById(resetItemId)
    self.TxtResetItemName.text = name

    if XDataCenter.TRPGManager.CheckExamineStatus(XTRPGConfigs.ExmaineStatus.Normal) then
        self:UpdateNormalUi()
    elseif XDataCenter.TRPGManager.CheckExamineStatus(XTRPGConfigs.ExmaineStatus.Suc) then
        self:UpdateSucUi()
    elseif XDataCenter.TRPGManager.CheckExamineStatus(XTRPGConfigs.ExmaineStatus.Fail) then
        self:UpdateFailUi()
    end
end

function XUiTRPGTest:UpdateNormalUi()
    local actionId = self.ActionId
    self.ItemIds = XTRPGConfigs.GetExamineBuffItemIds(actionId)

    local defaultItemIndex = #self.ItemIds
    local itemIndex = self.SelectItemIndex or defaultItemIndex
    if itemIndex ~= defaultItemIndex then
        local itemCount = XDataCenter.ItemManager.GetCount(self.ItemIds[itemIndex])
        if itemCount <= 0 then
            itemIndex = defaultItemIndex
        end
    end
    self.SelectItemIndex = itemIndex

    self.DynamicTable:SetDataSource(self.ItemIds)
    self.DynamicTable:ReloadDataSync()
    self:OnSelectItem(self.SelectItemIndex)
    self:OnSelectRole(self.SelectRoleIndex)

    local showBtnNext = XDataCenter.TRPGManager.IsExamineCanEnterNextRound()
    self.BtnNext:SetDisable(not showBtnNext)

    local isLastRound = XDataCenter.TRPGManager.IsExamineLastRound()
    self.BtnNext.gameObject:SetActiveEx(not isLastRound)
    self.BtnFinish.gameObject:SetActiveEx(isLastRound)

    self.PanelRight.gameObject:SetActiveEx(true)
    self.PanelSuc.gameObject:SetActiveEx(false)
    self.PanelFail.gameObject:SetActiveEx(false)

    self.NeedScoreChangeAnim = nil
end

function XUiTRPGTest:UpdateSucUi()
    local examineId = self.ExamineId
    local actionId = self.ActionId

    local sucDesc = XTRPGConfigs.GetExamineSucDesc(examineId)
    self.TxtDescribeSuc.text = sucDesc

    if XTRPGConfigs.CheckExamineActionType(actionId, XTRPGConfigs.TRPGExamineActionType.ConsumeItem) then
        self.TxtRound.text = "0/0"
        self.TxtJdNumber.text = 0
        self.TxtJd.text = "/0"
        self.ImgJd.fillAmount = 1
        self.ImgJdSuc.gameObject:SetActiveEx(true)
        self.ImgJdFail.gameObject:SetActiveEx(false)
    end

    self.PanelRight.gameObject:SetActiveEx(false)
    self.PanelSuc.gameObject:SetActiveEx(true)
    self.PanelFail.gameObject:SetActiveEx(false)

    self:PlayAnimation("PanelSucEnable")
end

function XUiTRPGTest:UpdateFailUi()
    local punishId = XDataCenter.TRPGManager.GetCurExaminePunishId()
    if punishId > 0 then

        if XTRPGConfigs.CheckPunishType(punishId, XTRPGConfigs.PunishType.DeBuff) then
            self:UpdateTrackRoles()
        end
        local failDesc = XTRPGConfigs.GetPunishDesc(punishId)
        self.TxtDescribeFail.text = failDesc

    else

        local examineId = self.ExamineId
        local failDesc = XTRPGConfigs.GetExamineFailDesc(examineId)
        self.TxtDescribeFail.text = failDesc
        for _, grid in pairs(self.TrackRoleGrids) do
            grid.GameObject:SetActiveEx(false)
        end

    end

    self.PanelRight.gameObject:SetActiveEx(false)
    self.PanelSuc.gameObject:SetActiveEx(false)
    self.PanelFail.gameObject:SetActiveEx(true)

    self:PlayAnimation("PanelFailEnable")
end

function XUiTRPGTest:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local actionId = self.ActionId

        local itemId = self.ItemIds[index]
        grid:Refresh(itemId, actionId)

        local isSelect = index == self.SelectItemIndex
        if isSelect then
            self.LastSelectItemGrid = grid
            grid:SetSelect(true)
        else
            grid:SetSelect(false)
        end

        local clickCb = function()
            local paramindex = index

            local itemId = self.ItemIds[index]
            if not XTRPGConfigs.CheckDefaultEffectItemId(itemId) and XDataCenter.ItemManager.GetCount(itemId) <= 0 then
                return
            end

            if self.LastSelectItemGrid then
                self.LastSelectItemGrid:SetSelect(false)
            end
            self.LastSelectItemGrid = grid
            grid:SetSelect(true)

            self:OnSelectItem(index)

            self.NeedEffect = true
        end
        grid:InitClickCb(clickCb)
    end
end

function XUiTRPGTest:OnSelectItem(index)
    self.SelectItemIndex = index
    self:UpdateRoles()
end

function XUiTRPGTest:UpdateRoles()
    local actionId = self.ActionId
    local totalMinValue, totalMaxValue = XDataCenter.TRPGManager.GetExamineActionTotalCallRollValue(actionId)

    local addAttribute = 0
    if self.SelectItemIndex then
        local itemId = self.ItemIds[self.SelectItemIndex]
        addAttribute = XTRPGConfigs.GetItemAddAttribute(itemId)
    end

    local roleIds = XDataCenter.TRPGManager.GetOwnRoleIds()
    self.RoleIds = roleIds
    for index = 1, MAX_ROLE_NUM do

        local grid = self.RoleGrids[index]
        if not grid then
            local ui = index == 1 and self.GridRoleAttribute or CSUnityEngineObjectInstantiate(self.GridRoleAttribute, self.PanelRoleContent)
            local clickCb = function() self:OnSelectRole(index) end
            grid = XUiGridTRPGTestRole.New(ui, clickCb)
            self.RoleGrids[index] = grid
        end

        local roleId = roleIds[index]
        if roleId then
            grid:Refresh(roleId, actionId, addAttribute, self.NeedScoreChangeAnim, self.NeedEffect)
            grid.GameObject:SetActiveEx(true)
            grid:SetDisable(false)
        else
            grid.TxtDoubt.gameObject:SetActiveEx(false)
            grid:SetDisable(true)
        end

    end

    self.NeedEffect = nil
end

function XUiTRPGTest:UpdateTrackRoles()
    local roleIds = self.RoleIds
    for index, roleId in ipairs(roleIds) do
        local grid = self.TrackRoleGrids[index]
        if not grid then
            local ui = index == 1 and self.GridTrackRole or CSUnityEngineObjectInstantiate(self.GridTrackRole, self.PanelTrackContent)
            grid = XUiGridTRPGRoleDetail.New(ui, self)
            self.TrackRoleGrids[index] = grid
        end

        local showBuffEffect = true
        grid:Refresh(roleId, showBuffEffect)
        grid.GameObject:SetActiveEx(true)
    end

    for index = #roleIds + 1, #self.TrackRoleGrids do
        local grid = self.TrackRoleGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end
end

function XUiTRPGTest:OnSelectRole(index)
    if self.RoleGrids[index]:IsDisable() then
        return
    end

    self.SelectRoleIndex = index

    for index, grid in pairs(self.RoleGrids) do
        grid:SetSelect(index == self.SelectRoleIndex)
    end

    local roleId = self.SelectRoleIndex
    local isRolled = XDataCenter.TRPGManager.IsExamineRoleAlreadyRolled(roleId)
    self.BtnStart:SetDisable(isRolled)
end

function XUiTRPGTest:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnConfirm, self.OnClickBtnConfirm)
    self:RegisterClickEvent(self.BtnFinish, self.OnClickBtnFinish)
    self:RegisterClickEvent(self.BtnFail, self.OnClickBtnFail)
    self:RegisterClickEvent(self.BtnNext, self.OnClickBtnNext)
    self:RegisterClickEvent(self.BtnStart, self.OnClickBtnStart)
    self:RegisterClickEvent(self.BtnResetItem, self.OnClickBtnResetItem)
end

function XUiTRPGTest:OnBtnBackClick()
    local examineId = self.ExamineId

    if XDataCenter.TRPGManager.CheckExamineStatus(XTRPGConfigs.ExmaineStatus.Normal) then
        local title = CSXTextManagerGetText("TRPGExploreExmaineBackTipsTitle")
        local content = CSXTextManagerGetText("TRPGExploreExmaineBackTipsContent")
        content = stringGsub(content, "\\n", "\n")
        local callFunc = function()
            XDataCenter.TRPGManager.RequestExamineResult(examineId)
        end
        XUiManager.SystemDialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
    else
        XDataCenter.TRPGManager.EnterExaminePunish()
        self:Close()
    end
end

function XUiTRPGTest:OnClickBtnConfirm()
    self:Close()
end

function XUiTRPGTest:OnClickBtnFail()
    XDataCenter.TRPGManager.EnterExaminePunish()
    XLuaUiManager.Remove("UiTRPGTest")
end

function XUiTRPGTest:OnClickBtnFinish()
    if not XDataCenter.TRPGManager.IsExamineCanEnterNextRound() then
        XUiManager.TipText("TRPGExploreExmaineCantEnterNextRound")
        return
    end

    local examineId = self.ExamineId
    XDataCenter.TRPGManager.RequestExamineResult(examineId)
end

function XUiTRPGTest:OnClickBtnNext()
    if not XDataCenter.TRPGManager.IsExamineCanEnterNextRound() then
        XUiManager.TipText("TRPGExploreExmaineCantEnterNextRound")
        return
    end

    XDataCenter.TRPGManager.TRPGExamineChangeRoundRequest()

    self:PlayAnimation("PanelRightEnable")
end

function XUiTRPGTest:OnClickBtnStart()
    local roleId = self.SelectRoleIndex
    if XDataCenter.TRPGManager.IsExamineRoleAlreadyRolled(roleId) then
        XUiManager.TipText("TRPGExploreExmaineRoleAlreadyRolled")
        return
    end

    local examineId = self.ExamineId
    local actionId = self.ActionId
    local useItemId = self.SelectItemIndex and self.ItemIds[self.SelectItemIndex]
    XDataCenter.TRPGManager.RequestExamineCharacterSend(examineId, actionId, roleId, useItemId)
end

function XUiTRPGTest:OnClickBtnResetItem()
    local actionId = self.ActionId
    local resetItemId = XTRPGConfigs.GetExamineActionResetCostItemInfo(actionId)
    -- XLuaUiManager.Open("UiTip", resetItemId)--UI层级不符，暂时不要
end

function XUiTRPGTest:LetScoreRoll(targetScore, targetFillAmount)
    if not targetScore then return end
    local startScore = tonumber(self.TxtJdNumber.text) or 0

    local onRefreshFunc = function(time)
        if XTool.UObjIsNil(self.TxtJdNumber)
        or XTool.UObjIsNil(self.ImgJd)
        then
            self:DestroyTimer()
            return true
        end

        if startScore == targetScore then
            return true
        end
        self.TxtJdNumber.text = mathFloor(Lerp(startScore, targetScore, time))

        local startFillAmount = self.ImgJd.fillAmount
        self.ImgJd.fillAmount = Lerp(startFillAmount, targetFillAmount, time)

    end

    XLuaUiManager.SetMask(true)
    local finishCb = function()
        XLuaUiManager.SetMask(false)
    end
    self:DestroyTimer()
    self.Timer = XUiHelper.Tween(SCORE_ANIM_DURATION, onRefreshFunc, finishCb)

    self.Effect1.gameObject:SetActiveEx(true)
    self:DestroyEffectTimer()
    self.EffectTimer = CSXScheduleManagerScheduleOnce(function()
        if XTool.UObjIsNil(self.Effect1.gameObject) then return end
        self.Effect1.gameObject:SetActiveEx(false)

    end, SCORE_ANIM_DURATION * XScheduleManager.SECOND)
end

function XUiTRPGTest:DestroyEffectTimer()
    if self.EffectTimer then
        CSXScheduleManagerUnSchedule(self.EffectTimer)
        self.EffectTimer = nil
    end
end

function XUiTRPGTest:DestroyTimer()
    if self.Timer then
        CSXScheduleManagerUnSchedule(self.Timer)
        self.Timer = nil
    end
end
local XUiGridTRPGTestAction = require("XUi/XUiTRPG/XUiGridTRPGTestAction")
local XUiGridTRPGRoleDetail = require("XUi/XUiTRPG/XUiGridTRPGRoleDetail")

local CSXTextManagerGetText = CS.XTextManager.GetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local CONDITION_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("0E70BDFF"),
    [false] = CS.UnityEngine.Color.red,
}

local XUiTRPGTestDetailsTips = XLuaUiManager.Register(XLuaUi, "UiTRPGTestDetailsTips")

function XUiTRPGTestDetailsTips:OnAwake()
    self:AutoAddListener()
    self.GridExamine.gameObject:SetActiveEx(false)
    self.GridExamineRole.gameObject:SetActiveEx(false)
end

function XUiTRPGTestDetailsTips:OnStart(examineId)
    self.ExamineId = examineId
    self.SelectActionIndex = 1
    self.RoleGrids = {}

    self:InitUi()
end

function XUiTRPGTestDetailsTips:OnEnable()
    self:UpdateUi()
end

function XUiTRPGTestDetailsTips:InitUi()
    local examineId = self.ExamineId

    local costEndurance = XTRPGConfigs.GetExamineCostEndurance(examineId)
    if costEndurance > 0 then
        self.TxtTips.text = CSXTextManagerGetText("TRPGExploreExamineCostEnduranceTips", costEndurance)
        self.TxtTips.gameObject:SetActiveEx(true)
    else
        self.TxtTips.gameObject:SetActiveEx(false)
    end

    local desc = XTRPGConfigs.GetExamineDescription(examineId)
    self.TxtDescribe.text = desc

    local title = XTRPGConfigs.GetExamineTitle(examineId)
    if not string.IsNilOrEmpty(title) then
        self.TxtTitle = self.Transform:FindTransformWithSplit("Tanchuang01/Text"):GetComponent("Text")
        self.TxtTitle.text = title
    end

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTestList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridTRPGTestAction)
end

function XUiTRPGTestDetailsTips:UpdateUi()
    local examineId = self.ExamineId

    local curEndurance = XDataCenter.TRPGManager.GetExploreCurEndurance()
    local maxEndurance = XDataCenter.TRPGManager.GetExploreMaxEndurance()
    self.TxtEndurance.text = CSXTextManagerGetText("TRPGExploreEnduranceValue", curEndurance, maxEndurance)

    self.ActionIds = XTRPGConfigs.GetExamineActionIds(examineId)
    self.DynamicTable:SetDataSource(self.ActionIds)
    self.DynamicTable:ReloadDataSync()

    self:OnSelectAction(self.SelectActionIndex)
end

function XUiTRPGTestDetailsTips:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local actionId = self.ActionIds[index]
        grid:Refresh(actionId)

        local isSelect = index == self.SelectActionIndex
        if isSelect then
            self.LastSelectActionGrid = grid
            grid:SetSelect(true)
        else
            grid:SetSelect(false)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.LastSelectActionGrid then
            self.LastSelectActionGrid:SetSelect(false)
        end
        self.LastSelectActionGrid = grid
        grid:SetSelect(true)

        self:OnSelectAction(index)
    end
end

function XUiTRPGTestDetailsTips:OnSelectAction(index)
    self.SelectActionIndex = index
    self:UpdateCurAction()
end

function XUiTRPGTestDetailsTips:UpdateCurAction()
    local actionId = self.ActionIds[self.SelectActionIndex]

    if XTRPGConfigs.CheckExamineActionType(actionId, XTRPGConfigs.TRPGExamineActionType.ConsumeItem) then
        local itemName = XTRPGConfigs.GetExamineActionItemName(actionId)
        local tips = CSXTextManagerGetText("TRPGExploreExmaineCostItemTips", itemName)
        self.TxtItemTips.text = tips

        self.TxtItemTips.gameObject:SetActiveEx(true)
        self.PanelAttribute.gameObject:SetActiveEx(false)
    else
        local icon = XTRPGConfigs.GetExamineActionIcon(actionId)
        self.RImgAttributeIcon:SetRawImage(icon)

        local rangeDesc = XTRPGConfigs.GetExamineActionTypeRangeDesc(actionId)
        self.TxtRange.text = rangeDesc

        local rangeDesc = XTRPGConfigs.GetExamineActionTypeAttrDesc(actionId)
        self.TxtAttrDesc.text = rangeDesc

        local totalMinValue, totalMaxValue = XDataCenter.TRPGManager.GetExamineActionTotalCallRollValue(actionId)
        self.TxtNumber.text = totalMinValue .. "~" .. totalMaxValue

        local reqPoints = XTRPGConfigs.GetExamineActionNeedValue(actionId)
        local passCondition = totalMaxValue >= reqPoints
        self.TxtNumber.color = CONDITION_COLOR[passCondition]

        local roleIds = XDataCenter.TRPGManager.GetOwnRoleIds()
        for index, roleId in ipairs(roleIds) do
            local grid = self.RoleGrids[index]
            if not grid then
                local ui = index == 1 and self.GridExamineRole or CSUnityEngineObjectInstantiate(self.GridExamineRole, self.PanelRoleContent)
                grid = XUiGridTRPGRoleDetail.New(ui, self)
                self.RoleGrids[index] = grid
            end

            grid:Refresh(roleId)
            grid.GameObject:SetActiveEx(true)
        end

        for index = #roleIds + 1, #self.RoleGrids do
            local grid = self.RoleGrids[index]
            if grid then
                grid.GameObject:SetActiveEx(false)
            end
        end

        self.TxtItemTips.gameObject:SetActiveEx(false)
        self.PanelAttribute.gameObject:SetActiveEx(true)
    end
end

function XUiTRPGTestDetailsTips:AutoAddListener()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnConfirm, self.OnClickBtnConfirm)
end

function XUiTRPGTestDetailsTips:OnBtnBackClick()
    self:Close()
    XDataCenter.MovieManager.StopMovie()
end

function XUiTRPGTestDetailsTips:OnClickBtnConfirm()
    local examineId = self.ExamineId
    if not XDataCenter.TRPGManager.CheckExamineCostEnduranceEnough(examineId) then
        XUiManager.TipText("TRPGExploreExmaineLackEndurance")
        return
    end

    local actionId = self.ActionIds[self.SelectActionIndex]
    local cb = function()
        self:Close()
    end
    XDataCenter.TRPGManager.RequestExamineSend(examineId, actionId, cb)
end
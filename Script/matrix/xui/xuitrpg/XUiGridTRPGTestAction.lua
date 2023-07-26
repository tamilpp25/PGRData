local CSXTextManagerGetText = CS.XTextManager.GetText

local CONDITION_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("59F5FFFF"),
    [false] = CS.UnityEngine.Color.red,
}

local XUiGridTRPGTestAction = XClass(nil, "XUiGridTRPGTestAction")

function XUiGridTRPGTestAction:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:SetSelect(false)
end

function XUiGridTRPGTestAction:Refresh(actionId)
    self.ActionId = actionId

    local desc = XTRPGConfigs.GetExamineActionDesc(actionId)
    self.TxtName.text = desc

    local icon = XTRPGConfigs.GetExamineActionIcon(actionId)
    self.RImgAttributeIcon:SetRawImage(icon)

    if XTRPGConfigs.CheckExamineActionType(actionId, XTRPGConfigs.TRPGExamineActionType.ConsumeItem) then
        self.TxtDifficulty.gameObject:SetActiveEx(false)
        self.TxtRound.transform.parent.gameObject:SetActiveEx(false)


        local itemId = XTRPGConfigs.GetExamineActionItemId(actionId)
        local itemCount = 1
        local pass = XDataCenter.ItemManager.CheckItemCountById(itemId, itemCount) 
        local desc = pass and CSXTextManagerGetText("TRPGExploreExmaineUseItemReqValue") or CSXTextManagerGetText("TRPGExploreExmaineUseItemReqValueDeny")
        self.TxtReqPoints.text = desc
        self.TxtReqPoints.color = CONDITION_COLOR[pass]

    else
        local difficulty = XDataCenter.TRPGManager.GetExamineActionDifficult(actionId)
        local difficultyDes = XTRPGConfigs.GetExamineActionDifficultDesc(difficulty)
        self.TxtDifficulty.text = difficultyDes
        self.TxtDifficulty.gameObject:SetActiveEx(true)

        local reqPoints = XTRPGConfigs.GetExamineActionNeedValue(actionId)
        self.TxtReqPoints.text = reqPoints

        local totalRound = XTRPGConfigs.GetExamineActionRound(actionId)
        self.TxtRound.text = CSXTextManagerGetText("TRPGExploreExmaineTotalRound", totalRound)
        self.TxtRound.transform.parent.gameObject:SetActiveEx(true)
    end

    local desc = XTRPGConfigs.GetExamineActionTypeDesc(actionId)
    self.TxtAttribute.text = desc
end

function XUiGridTRPGTestAction:SetSelect(value)
    self.ImgSelect.gameObject:SetActiveEx(value)
end

return XUiGridTRPGTestAction
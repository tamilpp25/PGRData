local XUiGridAssignStage = XClass(nil, "XUiGridAssignStage")

function XUiGridAssignStage:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiGridAssignStage:InitComponent()
    self.GridAssignStage.CallBack = function() self:OnClick() end
end

function XUiGridAssignStage:Refresh(chapterId, groupId)
    self.ChapterId = chapterId
    self.GroupId = groupId
    local data = XDataCenter.FubenAssignManager.GetGroupDataById(groupId)
    self.GroupData = data

    local icon = data:GetIcon()
    self.RImgStageNormal:SetRawImage(icon)
    self.RImgStageSelect:SetRawImage(icon)
    -- self.RImgStageDisable:SetRawImage(icon) -- 未解锁显示默认白色
    local name = data:GetName()
    self.TextNameNormal.text = name
    self.TextNameSelect.text = name
    self.TextNameDisable.text = name

    local needTeamNum = #data:GetTeamInfoId()
    self.TextTeamNumNormal.text = needTeamNum
    self.TextTeamNumSelect.text = needTeamNum

    self.ImgFubenEnd.gameObject:SetActiveEx(data:IsPass() and not data:GetIsPerfect())
    self.ImgFubenPerfect.gameObject:SetActiveEx(data:IsPass() and data:GetIsPerfect())
    self.GridAssignStage:SetButtonState(data:IsUnlock() and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
end

function XUiGridAssignStage:OnClick()
    if not self.GroupData then
        return
    end
    if not self.GroupData:IsUnlock() then
        XUiManager.TipMsg(CS.XTextManager.GetText("AssignStageUnlock")) -- "请先通关前置关卡"
        return
    end
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_ASSIGN_STAGE_CLICK, self)
end

return XUiGridAssignStage
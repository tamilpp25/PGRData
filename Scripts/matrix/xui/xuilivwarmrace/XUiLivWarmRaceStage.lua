local XUiLivWarmRaceStage = XClass(nil, "XUiLivWarmRaceStage")

function XUiLivWarmRaceStage:Ctor(ui, stageId, groupId, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.StageId = stageId
    self.GroupId = groupId
    self.ClickCb = clickCb
    CsXUiHelper.RegisterClickEvent(self.BtnClick, function() self:OnClickBtnClick() end)

    self:InitStar()
end

function XUiLivWarmRaceStage:InitStar()
    self.StarList = {}
    self.StarActiveImgList = {}
    for i = 1, XLivWarmRaceConfigs.MaxStarCount do
        self.StarList[i] = i == 1 and self.IconStar or CS.UnityEngine.Object.Instantiate(self.IconStar, self.PanelStar)
        self.StarActiveImgList[i] = XUiHelper.TryGetComponent(self.StarList[i].transform, "Img")
    end
end

function XUiLivWarmRaceStage:Refresh()
    self:SetSelect(false)
    local stageId = self:GetStageId()
    local groupId = self:GetGroupId()

    local isClear = XDataCenter.LivWarmRaceManager.IsStageClear(stageId)
    self.CommonFuBenClear.gameObject:SetActiveEx(isClear)

    local isOpen = XDataCenter.LivWarmRaceManager.IsStageOpen(stageId)
    self.PanelNotOpen.gameObject:SetActiveEx(not isOpen)
    self.PanelNormal.gameObject:SetActiveEx(isOpen)
    if isOpen then
        local roleHead = XLivWarmRaceConfigs.GetGroupRoleHead(groupId)
        self.RImgIcon:SetRawImage(roleHead)

        local monsterHead = XLivWarmRaceConfigs.GetStageMonsterHead(stageId)
        self.RImgBossIcon:SetRawImage(monsterHead)

        self.TxtName.text = XLivWarmRaceConfigs.GetGroupRoleName(groupId)
        self.TxtOrder.text = XFubenConfigs.GetStageName(stageId)
    else
        self.TxtName.text = ""
        self.TxtOrder.text = XLivWarmRaceConfigs.GetStageNotOpenName(stageId)
    end

    local starDesc = XFubenConfigs.GetStarDesc(stageId)
    local _, count = XDataCenter.LivWarmRaceManager.GetStarMap(stageId)
    for i = 1, XLivWarmRaceConfigs.MaxStarCount do
        self.StarActiveImgList[i].gameObject:SetActiveEx(count >= i)
        self.StarList[i].gameObject:SetActiveEx(true)
    end
    for i = #starDesc + 1, XLivWarmRaceConfigs.MaxStarCount do
        self.StarList[i].gameObject:SetActiveEx(false)
    end
end

function XUiLivWarmRaceStage:OnClickBtnClick()
    local stageId = self:GetStageId()
    local tips = XDataCenter.LivWarmRaceManager.GetOpenTips(stageId)
    if not string.IsNilOrEmpty(tips) then
        XUiManager.TipMsg(tips)
        return
    end

    if self.ClickCb then
        self.ClickCb(self)
    end
end

function XUiLivWarmRaceStage:SetSelect(isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end

function XUiLivWarmRaceStage:GetStageId()
    return self.StageId
end

function XUiLivWarmRaceStage:GetGroupId()
    return self.GroupId
end

return XUiLivWarmRaceStage
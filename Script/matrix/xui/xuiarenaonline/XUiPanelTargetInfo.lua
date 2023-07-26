local XUiPanelTargetInfo = XClass(nil, "XUiPanelTargetInfo")

function XUiPanelTargetInfo:Ctor(uiRoot,parent, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.Parent = parent
    self.GridSkillList = {}
    self.GridBuffList = {}

    XTool.InitUiObject(self)
    self.GridSkill.gameObject:SetActiveEx(false)
    self.GridBuff.gameObject:SetActiveEx(false)
end

function XUiPanelTargetInfo:Show(stageId)
    if self.StageId == stageId then
        self.CanvasGroup.alpha = 0
        self.GameObject:SetActiveEx(true)
        self.UiRoot:PlayAnimation("TargetInfoQieHuan")
        return
    end

    self.StageId = stageId
    self.ArenaStageCfg = XArenaOnlineConfigs.GetStageById(stageId)
    self:Refresh()
    self.CanvasGroup.alpha = 0
    self.GameObject:SetActiveEx(true)
    self.UiRoot:PlayAnimation("TargetInfoQieHuan")
end

function XUiPanelTargetInfo:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelTargetInfo:Refresh()
    self.TxtCondition.text = self.ArenaStageCfg.ConditionDesc
    self:SetSkillInfo()
    self:SetBuffInfo()
end

function XUiPanelTargetInfo:SetSkillInfo()
    local titles = self.ArenaStageCfg.SkillTitle
    local descs = self.ArenaStageCfg.SkillDesc
    for _, v in ipairs(self.GridSkillList) do
        v.gameObject:SetActive(false)
    end

    if not titles or #titles <= 0 then
        return
    end

    for index, title in ipairs(titles) do
        local grid = self.GridSkillList[index]
        if not grid then
            local go = CS.UnityEngine.GameObject.Instantiate(self.GridSkill.gameObject)
            grid = go.transform
            grid:SetParent(self.PanelSkillContent, false)
            table.insert(self.GridSkillList, grid)
        end
        grid.gameObject:SetActive(true)

        local textTitle = XUiHelper.TryGetComponent(grid.transform, "TxtTitle", "Text")
        local textDesc = XUiHelper.TryGetComponent(grid.transform, "TxtDesc", "Text")
        textTitle.text = title
        textDesc.text = descs[index]
    end
end

function XUiPanelTargetInfo:SetBuffInfo()
    local t = XDataCenter.ArenaOnlineManager.GetArenaOnlineStageInfo(self.StageId)
    local buffIds = t.BuffIds
    for _, v in ipairs(self.GridBuffList) do
        v.gameObject:SetActive(false)
    end

    if not buffIds or #buffIds <= 0 then
        return
    end

    for index, buffId in ipairs(buffIds) do
        local grid = self.GridBuffList[index]
        if not grid then
            local go = CS.UnityEngine.GameObject.Instantiate(self.GridBuff.gameObject)
            grid = go.transform
            grid:SetParent(self.PanelBuffContent, false)
            table.insert(self.GridBuffList, grid)
        end
        grid.gameObject:SetActive(true)

        local icon = XUiHelper.TryGetComponent(grid.transform, "RImgIcon", "RawImage")
        local btn = XUiHelper.TryGetComponent(grid.transform, "BtnClick", "Button")

        local cfg = XArenaOnlineConfigs.GetNpcAffixById(buffId)
        icon:SetRawImage(cfg.Icon)
        btn.CallBack = function()
            self.Parent:BuffDetailShow(self.StageId)
        end
    end
end

return XUiPanelTargetInfo
local XUiPanelBuffDetail = XClass(nil, "XUiPanelBuffDetail")

function XUiPanelBuffDetail:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.GridBuffList = {}
    XTool.InitUiObject(self)
    self:AutoAddListener()
    self.GirdBuff.gameObject:SetActiveEx(false)
end

function XUiPanelBuffDetail:AutoAddListener()
    self.BtnClose.CallBack = function() self:Hide() end
end

function XUiPanelBuffDetail:Show(stageId)
    if self.StageId == stageId then
        self.GameObject:SetActiveEx(true)
        return
    end

    self.StageId = stageId
    self:Refresh()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelBuffDetail:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelBuffDetail:Refresh()
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
            local go = CS.UnityEngine.GameObject.Instantiate(self.GirdBuff.gameObject)
            grid = go.transform
            grid:SetParent(self.PanelContent, false)
            table.insert(self.GridBuffList, grid)
        end
        grid.gameObject:SetActive(true)

        local icon = XUiHelper.TryGetComponent(grid.transform, "RImgIcon", "RawImage")
        local name = XUiHelper.TryGetComponent(grid.transform, "TxtName", "Text")
        local desc = XUiHelper.TryGetComponent(grid.transform, "TxtDesc", "Text")

        local cfg = XArenaOnlineConfigs.GetNpcAffixById(buffId)
        icon:SetRawImage(cfg.Icon)
        name.text = cfg.Name
        desc.text = cfg.Description
    end
end

return XUiPanelBuffDetail
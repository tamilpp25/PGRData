local XUiGridZone = XClass(nil, "XUiGridZone")

function XUiGridZone:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:AutoAddListener()

    self.LordList = {}
    for i = 1, 3 do
        table.insert(self.LordList, self["GridLord" .. i])
    end
end

function XUiGridZone:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridZone:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridZone:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridZone:AutoAddListener()
    self:RegisterClickEvent(self.BtnZone, self.OnBtnZoneClick)
end

function XUiGridZone:OnBtnZoneClick()
    if not self.AreaData then
        XUiManager.TipError(CS.XTextManager.GetText("ArenaActivityAreaIsNotOpen"))
        return
    end

    if self.AreaData.Lock == 1 then
        --解锁区域
        local areaStageCfg = XArenaConfigs.GetArenaAreaStageCfgByAreaId(self.AreaData.AreaId)
        local remainCount = XDataCenter.ArenaManager.GetUnlockArenaAreaCount()

        local unlockStr = CS.XTextManager.GetText("ArenaActivityConfirmUnlockArea", areaStageCfg.Name, remainCount)
        XUiManager.DialogTip(CS.XTextManager.GetText("TipTitle"), unlockStr, XUiManager.DialogType.Normal, nil, function()
            XDataCenter.ArenaManager.RequestUnlockArea(self.AreaData.AreaId, function()
                self:SetMetaData(self.AreaData.AreaId)
            end)
        end)
        return
    end

    -- 进入关卡界面
    XLuaUiManager.Open("UiArenaStage", self.AreaData.AreaId)
end

function XUiGridZone:SetMetaData(areaId)
    if not areaId then
        -- 没有开启，就不显示
        self.GameObject:SetActive(false)
        self.AreaData = nil
        return
    end

    self.AreaData = XDataCenter.ArenaManager.GetArenaAreaDataByAreaId(areaId)
    local areaStageCfg = XArenaConfigs.GetArenaAreaStageCfgByAreaId(areaId)

    self.PanelClose.gameObject:SetActive(self.AreaData == nil)
    self.PanelOpen.gameObject:SetActive(self.AreaData ~= nil)

    self.TxtName.text = areaStageCfg.Name
    self.TxtOpenName.text = areaStageCfg.Name
    self.TxtLockName.text = areaStageCfg.Name

    if not self.AreaData then
        return
    end

    self.TxtPoint.text = CS.XTextManager.GetText("ArenaActivityPoint", self.AreaData.Point)
    self.PanelLock.gameObject:SetActive(self.AreaData.Lock == 1)
    self.PanelUnlock.gameObject:SetActive(self.AreaData.Lock == 0)

    for i, grid in ipairs(self.LordList) do
        local head = XUiHelper.TryGetComponent(grid, "Head")
        local rank = XUiHelper.TryGetComponent(grid, "TxtRank", "Text")

        local info = self.AreaData.LordList[i]
        if info then
            rank.text = i
            XUiPLayerHead.InitPortrait(info.CurrHeadPortraitId, info.CurrHeadFrameId, head)
        else
            rank.text = ""
            XUiPLayerHead.Hide(head)
        end
    end
end

return XUiGridZone
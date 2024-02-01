---@class XUiPanelRogueSimFindCity : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimFindCity = XClass(XUiNode, "XUiPanelRogueSimFindCity")

function XUiPanelRogueSimFindCity:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self.GridBuff.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridCityBuffList = {}
end

---@param id number 自增Id
function XUiPanelRogueSimFindCity:Refresh(id)
    self.Id = id
    self.CityId = self._Control.MapSubControl:GetCityConfigIdById(id)
    self:RefreshView()
    self:RefreshBuff()
    self:RefreshTask()
    -- 引导
    self._Control:TriggerGuide()
end

function XUiPanelRogueSimFindCity:RefreshView()
    -- 图片
    self.RImgCity:SetRawImage(self._Control.MapSubControl:GetCityIcon(self.CityId))
    -- 名称
    self.TxtName.text = self._Control.MapSubControl:GetCityName(self.CityId)
    -- 标志
    local tagIcon = self._Control.MapSubControl:GetCityTag(self.CityId)
    self.ImgTag:SetSprite(tagIcon)
end

function XUiPanelRogueSimFindCity:RefreshBuff()
    local buffIds = self._Control.MapSubControl:GetCityBuffIds(self.CityId)
    for index, buffId in pairs(buffIds) do
        local grid = self.GridCityBuffList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridBuff, self.ListBuff)
            self.GridCityBuffList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("RawImage"):SetRawImage(self._Control.BuffSubControl:GetBuffIcon(buffId))
        grid:GetObject("TxtBuffDesc").text = self._Control.BuffSubControl:GetBuffDesc(buffId)
    end
    for i = #buffIds + 1, #self.GridCityBuffList do
        self.GridCityBuffList[i].gameObject:SetActiveEx(false)
    end
end

function XUiPanelRogueSimFindCity:RefreshTask()
    local taskId = self._Control.MapSubControl:GetCityTaskIdById(self.Id)
    local isFinishTask = self._Control:CheckTaskIsFinished(taskId)
    self.PanelTaskOn.gameObject:SetActiveEx(isFinishTask)
    self.PanelTaskOff.gameObject:SetActiveEx(not isFinishTask)
    local configId = self._Control:GetTaskConfigIdById(taskId)
    local gridBuff = isFinishTask and self.PanelTaskOn:GetObject("GridBuff") or self.PanelTaskOff:GetObject("GridBuff")
    -- 刷新buff
    self:RefreshTaskBuff(configId, gridBuff)
    if not isFinishTask then
        -- 刷新任务
        local panelTask = self.PanelTaskOff:GetObject("PanelTask")
        panelTask.gameObject:SetActiveEx(true)
        panelTask:GetObject("TxtDetail").text = self._Control:GetTaskDesc(configId)
        -- 完成数、总数
        local schedule, totalNum = self._Control:GetTaskScheduleAndTotalNum(taskId, configId)
        panelTask:GetObject("TxtNum").text = string.format("%d/%d", schedule, totalNum)
        panelTask:GetObject("ImgBar").fillAmount = XTool.IsNumberValid(totalNum) and schedule / totalNum or 1
    end
end

function XUiPanelRogueSimFindCity:RefreshTaskBuff(configId, gridBuff)
    local taskBuffIds = self._Control:GetTaskBuffIds(configId)
    -- 默认只有一个BuffId
    local buffId = taskBuffIds[1]
    gridBuff.gameObject:SetActiveEx(true)
    gridBuff:GetObject("RawImage"):SetRawImage(self._Control.BuffSubControl:GetBuffIcon(buffId))
    gridBuff:GetObject("TxtBuffDesc").text = self._Control.BuffSubControl:GetBuffDesc(buffId)
end

function XUiPanelRogueSimFindCity:OnBtnCloseClick()
    self:Close()
    local type = self._Control:GetHasPopupDataType()
    if type == XEnumConst.RogueSim.PopupType.None then
        return
    end
    -- 弹出下一个弹框
    self._Control:ShowPopup(type)
end

return XUiPanelRogueSimFindCity

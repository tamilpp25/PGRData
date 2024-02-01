---@class XUiPanelRogueSimTaskSuccess : XUiNode
---@field private _Control XRogueSimControl
---@field private GridBuff UiObject
---@field private PanelTask UiObject
local XUiPanelRogueSimTaskSuccess = XClass(XUiNode, "XUiPanelRogueSimTaskSuccess")

function XUiPanelRogueSimTaskSuccess:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
end

---@param id number 任务自增Id
function XUiPanelRogueSimTaskSuccess:Refresh(id)
    self.Id = id
    local configId = self._Control:GetTaskConfigIdById(id)
    local taskName = self._Control:GetTaskName(configId)
    -- 完成描述
    self.TxtAttribute.text = string.format(self._Control:GetClientConfig("CityTaskSuccessContent", 1), taskName)
    -- buff
    self:RefreshTaskBuff(configId)
    -- 任务描述
    self.PanelTask:GetObject("TxtDetail").text = self._Control:GetTaskDesc(configId)
    -- 任务完成数、总数
    local schedule, totalNum = self._Control:GetTaskScheduleAndTotalNum(id, configId)
    self.PanelTask:GetObject("TxtNum").text = string.format("%d/%d", 0, totalNum)
    self.PanelTask:GetObject("ImgBar").fillAmount = 0
    -- 播放进入动画
    self:PlayAnimationWithMask("TaskSuccessEnable", function()
        self:PlayTaskProgressAnim(schedule, totalNum)
    end)
end

-- 播放任务进度动画
function XUiPanelRogueSimTaskSuccess:PlayTaskProgressAnim(schedule, totalNum)
    -- 时长
    local time = tonumber(self._Control:GetClientConfig("CityTaskSuccessAnimTime", 1))
    XLuaUiManager.SetMask(true)
    XUiHelper.Tween(time, function(f)
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        local curSchedule = XMath.ToMinInt(f * schedule)
        self.PanelTask:GetObject("TxtNum").text = string.format("%d/%d", curSchedule, totalNum)
        self.PanelTask:GetObject("ImgBar").fillAmount = XTool.IsNumberValid(totalNum) and curSchedule / totalNum or 1
    end, function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        XLuaUiManager.SetMask(false)
    end)
end

function XUiPanelRogueSimTaskSuccess:RefreshTaskBuff(configId)
    local taskBuffIds = self._Control:GetTaskBuffIds(configId)
    -- 默认只有一个buffId
    local buffId = taskBuffIds[1]
    self.GridBuff:GetObject("RawImage"):SetRawImage(self._Control.BuffSubControl:GetBuffIcon(buffId))
    self.GridBuff:GetObject("TxtBuffDesc").text = self._Control.BuffSubControl:GetBuffDesc(buffId)
end

function XUiPanelRogueSimTaskSuccess:OnBtnCloseClick()
    self:Close()
    local type = self._Control:GetHasPopupDataType()
    if type == XEnumConst.RogueSim.PopupType.None then
        return
    end
    -- 弹出下一个弹框
    self._Control:ShowPopup(type)
end

return XUiPanelRogueSimTaskSuccess

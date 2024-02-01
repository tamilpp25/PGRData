---@class XUiRogueSimOutpost : XLuaUi
---@field private _Control XRogueSimControl
---@field BtnOptionGroup XUiButtonGroup
local XUiRogueSimOutpost = XLuaUiManager.Register(XLuaUi, "UiRogueSimOutpost")

function XUiRogueSimOutpost:OnAwake()
    self:RegisterUiEvents()
    self.BtnOption.gameObject:SetActiveEx(false)
    ---@type XUiGridRogueSimEventOption[]
    self.GridOptionList = {}
    self.OptionIds = {}
    self.CurSelectOptionId = 0
end

---@param id number 自增Id
function XUiRogueSimOutpost:OnStart(id)
    self.Id = id
    self:Refresh()
end

function XUiRogueSimOutpost:Refresh()
    self.EventId = self._Control.MapSubControl:GetEventConfigIdById(self.Id)
    self:RefreshView()
    self:RefreshOption()
    self:RefreshBtnOk()
end

function XUiRogueSimOutpost:RefreshView()
    -- 标题
    self.TxtTitle.text = self._Control.MapSubControl:GetEventName(self.EventId)
    -- 存在回合数
    local isShow = self._Control.MapSubControl:CheckIsEventDuration(self.EventId)
    self.TxtTitleContent.gameObject:SetActiveEx(isShow)
    if isShow then
        local desc = self._Control:GetClientConfig("EventTurnNumberDesc", 1)
        local remainingDuration = self._Control.MapSubControl:GetEventRemainingDuration(self.Id)
        self.TxtTitleContent.text = string.format(desc, remainingDuration)
    end
    -- 内容
    self.Desc.text = self._Control.MapSubControl:GetEventText(self.EventId)
end

function XUiRogueSimOutpost:RefreshOption()
    self.OptionIds = self._Control.MapSubControl:GetEventOptionIds(self.EventId)
    local btnTags = {}
    for index, id in ipairs(self.OptionIds) do
        local grid = self.GridOptionList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.BtnOption, self.BtnOptionGroup.transform)
            grid = require("XUi/XUiRogueSim/Event/XUiGridRogueSimEventOption").New(go, self)
            self.GridOptionList[index] = grid
        end
        grid:Open()
        grid:Refresh(id)
        btnTags[index] = grid:GetBtn()
    end
    for index = #self.OptionIds + 1, #self.GridOptionList do
        self.GridOptionList[index]:Close()
    end
    self.BtnOptionGroup:Init(btnTags, function(index) self:OnBtnOptionClick(index) end)
end

function XUiRogueSimOutpost:RefreshBtnOk()
    self.BtnOK:SetDisable(not XTool.IsNumberValid(self.CurSelectOptionId))
end

function XUiRogueSimOutpost:OnBtnOptionClick(index)
    if self.CurSelectIndex == index then
        return
    end
    -- 检查是否满足条件
    local optionId = self.OptionIds[index]
    local result, desc = self._Control.MapSubControl:CheckEventOptionCondition(optionId)
    if not result then
        XUiManager.TipMsg(desc)
        return
    end
    self.CurSelectIndex = index
    self.CurSelectOptionId = optionId
    self:RefreshBtnOk()
end

-- 清理数据
function XUiRogueSimOutpost:OnClearData()
    self.OptionIds = {}
    self.CurSelectOptionId = 0
    self.CurSelectIndex = 0
end

function XUiRogueSimOutpost:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnOK, self.OnBtnOKClick)
end

function XUiRogueSimOutpost:OnBtnBackClick()
    local type = self._Control:GetHasPopupDataType()
    if type == XEnumConst.RogueSim.PopupType.None then
        self:Close()
        return
    end
    -- 弹出下一个弹框(做一下兼容，避免事件链结束前给了奖励)
    self._Control:ShowNextPopup(self.Name, type)
end

function XUiRogueSimOutpost:OnBtnOKClick()
    if not XTool.IsNumberValid(self.CurSelectOptionId) then
        return
    end
    -- 选择选项
    self._Control:RogueSimEventSelectOptionRequest(self.Id, self.CurSelectOptionId, function(newEventId)
        if XTool.IsNumberValid(newEventId) then
            -- 自增Id不变直接刷新信息
            self:OnClearData()
            self:Refresh()
            return
        end
        -- 通过效果表给的资源和货物直接读取配置然后弹框
        local effectInfos = self._Control.MapSubControl:GetEventOptionEffectInfos(self.CurSelectOptionId)
        if not XTool.IsTableEmpty(effectInfos) then
            self._Control:ShowEventEffectPopup(self.Name, effectInfos)
            return
        end
        local type = self._Control:GetHasPopupDataType()
        if type == XEnumConst.RogueSim.PopupType.None then
            self:Close()
            return
        end
        -- 是否是道具选择
        if type == XEnumConst.RogueSim.PopupType.PropSelect then
            local gridId = self._Control.MapSubControl:GetEventGridIdById(self.Id)
            self._Control:ShowNextPopup(self.Name, type, gridId, XEnumConst.RogueSim.SourceType.Event)
        else
            -- 显示下一个弹框
            self._Control:ShowNextPopup(self.Name, type)
        end
    end)
end

return XUiRogueSimOutpost

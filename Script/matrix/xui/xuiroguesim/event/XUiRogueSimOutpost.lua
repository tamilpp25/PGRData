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
    local eventType = self._Control.MapSubControl:GetEventType(self.EventId)
    if eventType == XEnumConst.RogueSim.EventType.Auction then
        self.PanelNormal.gameObject:SetActiveEx(false)
        local rewardId = self._Control.MapSubControl:GetEventRewardIdById(self.Id)
        self:OpenAuctionView(rewardId)
    else
        self.PanelNormal.gameObject:SetActiveEx(true)
        self:RefreshNormalView()
        self:CloseAuctionView()
    end
    self:RefreshOption()
    self:RefreshBtnOk()
end

function XUiRogueSimOutpost:RefreshNormalView()
    -- 标题
    self.TxtTitle.text = self._Control.MapSubControl:GetEventName(self.EventId)
    -- 存在回合数
    self:RefreshRemainingDuration(self.TxtContent)
    -- 内容
    self.TxtDesc.text = self._Control.MapSubControl:GetEventText(self.EventId)
end

-- 刷新剩余回合数
---@param textContent UnityEngine.UI.Text
function XUiRogueSimOutpost:RefreshRemainingDuration(textContent)
    local isShow = self._Control.MapSubControl:CheckIsEventDuration(self.EventId)
    if textContent then
        textContent.gameObject:SetActiveEx(isShow)
    end
    if isShow then
        local desc = self._Control:GetClientConfig("EventTurnNumberDesc", 1)
        local remainingDuration = self._Control.MapSubControl:GetEventRemainingDuration(self.Id)
        if remainingDuration < 1 then
            XLog.Error("RogueSim Event RemainingDuration Error: " .. remainingDuration)
            -- 修正为1
            remainingDuration = 1
        end
        if textContent then
            textContent.text = string.format(desc, remainingDuration)
        end
    end
end

function XUiRogueSimOutpost:OpenAuctionView(rewardId)
    if not self.PanelAuctionUi then
        ---@type XUiPanelRogueSimEventAuction
        self.PanelAuctionUi = require("XUi/XUiRogueSim/Event/XUiPanelRogueSimEventAuction").New(self.PanelAuction, self)
    end
    self.PanelAuctionUi:Open()
    self.PanelAuctionUi:Refresh(self.EventId, rewardId)
end

function XUiRogueSimOutpost:CloseAuctionView()
    if self.PanelAuctionUi then
        self.PanelAuctionUi:Close()
    end
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
    XUiHelper.RegisterClickEvent(self, self.BtnOK, self.OnBtnOKClick, nil, true)
end

function XUiRogueSimOutpost:OnBtnBackClick()
    self._Control:ClearNextTargetPopupType()
    self._Control:CheckNeedShowNextPopup(self.Name, true)
end

function XUiRogueSimOutpost:OnBtnOKClick()
    if not XTool.IsNumberValid(self.CurSelectOptionId) then
        return
    end
    -- 选择选项
    self._Control:RogueSimEventSelectOptionRequest(self.Id, self.CurSelectOptionId, function(newEventId)
        local effectInfos = self._Control.MapSubControl:GetEventOptionEffectInfos(self.CurSelectOptionId)
        if XTool.IsNumberValid(newEventId) then
            -- 自增Id不变直接刷新信息
            self:OnClearData()
            self:Refresh()
            self:PlayAnimation("QieHuan")
            self._Control:SetNextTargetPopupType(XEnumConst.RogueSim.PopupType.Reward)
            if self:CheckIsShowEventEffectPopup(nil, effectInfos) then
                return
            end
            self._Control:CheckNeedShowNextPopup()
            return
        end
        self._Control:ClearNextTargetPopupType()
        if self:CheckIsShowEventEffectPopup(self.Name, effectInfos) then
            return
        end
        local typeData = {
            NextType = nil,
            ArgType = XEnumConst.RogueSim.PopupType.PropSelect,
        }
        local gridId = self._Control.MapSubControl:GetEventGridIdById(self.Id)
        self._Control:CheckNeedShowNextPopup(self.Name, true, typeData, gridId, XEnumConst.RogueSim.SourceType.Event)
    end)
end

-- 通过效果表给的资源、货物、建筑蓝图直接读取配置然后弹框
function XUiRogueSimOutpost:CheckIsShowEventEffectPopup(name, effectInfos)
    if not XTool.IsTableEmpty(effectInfos) then
        self._Control:ShowEventEffectPopup(name, effectInfos)
        return true
    end
    return false
end

return XUiRogueSimOutpost

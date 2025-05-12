local XUiSimulatedCombatBuffTip = XLuaUiManager.Register(XLuaUi, "UiSimulatedCombatBuffTip")

function XUiSimulatedCombatBuffTip:OnAwake()
    self.SpecialSoundMap = {}
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnOk, self.OnBtnOkClick)
end

function XUiSimulatedCombatBuffTip:OnStart(additionId)
    local musicKey = self:GetAutoKey(self.BtnBack, "onClick")
    self.SpecialSoundMap[musicKey] = XLuaAudioManager.UiBasicsMusic.Return
    self.Data = XFubenSimulatedCombatConfig.GetAdditionById(additionId)
    self:PlayAnimation("AnimStart")
end

function XUiSimulatedCombatBuffTip:OnEnable()
    self:Refresh(self.Data)
end

function XUiSimulatedCombatBuffTip:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

-- auto
function XUiSimulatedCombatBuffTip:OnBtnBackClick()
    self:Close()
end

function XUiSimulatedCombatBuffTip:OnBtnOkClick()
    self:Close()
end

function XUiSimulatedCombatBuffTip:Refresh(data)
    self.Data = data
    if not data then
        XLog.Error("XUiSimulatedCombatBuffTip:Refresh错误: 参数data不能为空")
        return
    end
     
    -- 名称
    self.TxtName.text = data.Name

    -- 图标
    self.RImgIcon:SetRawImage(data.Icon)

    -- 星级
    self.TxtStarCount.text = data.Star

    -- 描述
    self.TxtDescription.text = CS.XTextManager.GetText("SimulatedCombatBuffTipPrefix")..data.Description
end
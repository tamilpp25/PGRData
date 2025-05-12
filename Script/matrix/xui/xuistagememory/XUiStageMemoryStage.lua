---@class XUiStageMemoryStage : XUiNode
---@field _Control XStageMemoryControl
local XUiStageMemoryStage = XClass(XUiNode, "XUiStageMemoryStage")

function XUiStageMemoryStage:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnTongBlue, self.OnClickEnter)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnClickTip)
end

---@param data XStageMemoryControlStage
function XUiStageMemoryStage:Update(data)
    self._Data = data
    self.TxtStageTitle.text = data.Name
    self.TxtDec.text = data.Desc
    if data.IsUnlock then
        self.BtnTongBlue:SetButtonState(CS.UiButtonState.Normal)
    else
        self.BtnTongBlue:SetButtonState(CS.UiButtonState.Disable)
    end
    if self.Clear then
        if data.IsPassed then
            self.Clear.gameObject:SetActiveEx(true)
        else
            self.Clear.gameObject:SetActiveEx(false)
        end
    end
end

function XUiStageMemoryStage:OnClickTip()
    XUiManager.DialogTip(self._Data.Name, self._Data.DescDetail)
end

function XUiStageMemoryStage:OnClickEnter()
    self._Control:EnterFight(self._Data)
end

return XUiStageMemoryStage
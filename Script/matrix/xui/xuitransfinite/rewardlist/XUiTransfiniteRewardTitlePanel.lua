---@class XUiTransfiniteRewardTitlePanel
local XUiTransfiniteRewardTitlePanel = XClass(nil, "XUiTransfiniteRewardTitlePanel")

function XUiTransfiniteRewardTitlePanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    
    self._Data = nil
end

function XUiTransfiniteRewardTitlePanel:SetData(data)
    self._Data = data
end

function XUiTransfiniteRewardTitlePanel:Refresh()
    local data = self._Data

    if self.SeniorLock then
        self.SeniorLock.gameObject:SetActiveEx(not data.IsUnlock)
    end
    if self.TxtNormalLvTitle then
        self.TxtNormalLvTitle.text = data.NormalTitle
    end
    if self.TxtSeniorLvTitle then
        self.TxtSeniorLvTitle.text = data.SeniorTitle
    end
    if self.TxtSeniorLv then
        self.TxtSeniorLv.text = data.SeniorLv
    end
    if self.ImgNormal then
        self.ImgNormal:SetRawImage(data.NormalIconLv)
    end
    if self.ImgSenior then
        self.ImgSenior:SetRawImage(data.SeniorIconLv)
    end
    if self.TxtPointNum then
        self.TxtPointNum.text = data.TxtProgress
    end
    if self.ImgProgress then
        self.ImgProgress.fillAmount = data.Progress
    end
end

return XUiTransfiniteRewardTitlePanel
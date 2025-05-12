---@class XUiPhotographCapturePanel
---@field ImagePhoto UnityEngine.UI.Image
local XUiPhotographCapturePanel = XClass(nil, "XUiPhotographCapturePanel")

function XUiPhotographCapturePanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiPhotographCapturePanel:Init()
    self:AutoRegisterBtn()
end

function XUiPhotographCapturePanel:AutoRegisterBtn()
    self.BtnClose.CallBack = function () self:OnBtnCloseClick() end
end

function XUiPhotographCapturePanel:OnBtnCloseClick()
    self.RootUi:ChangeState(XPhotographConfigs.PhotographViewState.Normal)
    if not XTool.UObjIsNil(self.ImagePhoto.mainTexture) and self.ImagePhoto.mainTexture.name ~= "UnityWhite" then -- 销毁texture2d (UnityWhite为默认的texture2d)
        CS.UnityEngine.Object.Destroy(self.ImagePhoto.mainTexture)
    end
end

-- #108081
function XUiPhotographCapturePanel:Show()
    self.GameObject:SetActiveEx(true)
    XDataCenter.UiPcManager.OnUiEnable(self, "OnBtnCloseClick")
end

function XUiPhotographCapturePanel:Hide()
    self.GameObject:SetActiveEx(false)
    XDataCenter.UiPcManager.OnUiDisableAbandoned(true, self)
end

return XUiPhotographCapturePanel
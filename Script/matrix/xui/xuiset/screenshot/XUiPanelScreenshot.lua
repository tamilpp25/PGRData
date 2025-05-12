---@class XUiPanelScreenshot : XUiNode 布局方案预览
local XUiPanelScreenshot = XClass(XUiNode, "XUiPanelScreenshot")
local XUiPanelFrame = require("XUi/XUiSet/Screenshot/XUiPanelFrame")
local XCustomUi = CS.XCustomUi

function XUiPanelScreenshot:OnStart()
    XTool.InitUiObject(self)
    self.PanelFrameDic = {
        [XCustomUi.UiVersion.Old] = XUiPanelFrame.New(self.PanelFrameOld, self),
        [XCustomUi.UiVersion.V30] = XUiPanelFrame.New(self.PanelFrameNew, self)
    }
    self.BgPathDic = {
        [XCustomUi.UiVersion.Old] = CS.XFight.ClientConfig:GetString("CustomUiBg"),
        [XCustomUi.UiVersion.V30] = CS.XFight.ClientConfig:GetString("CustomUiBgV30")
    }
end

function XUiPanelScreenshot:OnEnable()
    self:Refresh()
end

function XUiPanelScreenshot:Refresh()
    -- 设置背景
    local curScheme = XUiFightButtonDefaultStyleConfig.GetCurSchemeStyle()
    local curUiVersion = CS.XCustomUi.SchemeIndex.__CastFrom(curScheme) == CS.XCustomUi.SchemeIndex.OldNoUiMode and XCustomUi.UiVersion.V30 or XCustomUi.Instance:GetCurUseUiVersion()
    self.Bg:SetRawImage(self.BgPathDic[curUiVersion])
    self.Bg.transform:GetComponent("RectTransform").sizeDelta = Vector2(CS.XUiManager.RealScreenWidth, CS.XUiManager.RealScreenHeight)
    -- 刷新组件面板
    for uiVersion, panel in pairs(self.PanelFrameDic) do
        if curUiVersion == uiVersion then
            panel:Open()
            panel:Refresh()
        else
            panel:Close()
        end
    end
end

return XUiPanelScreenshot
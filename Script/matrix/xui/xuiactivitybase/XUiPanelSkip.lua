
local XUiPanelSkip = XClass(nil, "XUiPanelSkip")

function XUiPanelSkip:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiPanelSkip:Refresh(activityCfg)
    if not activityCfg then return end

    self.TxtContentTimeNotice.text = XActivityConfigs.GetActivityTimeStr(activityCfg.Id)
    self.TxtContentTitleNotice.text = string.gsub(activityCfg.ActivityTitle, "\\n", "\n")
    self.TxtContentNotice.text = string.gsub(activityCfg.ActivityDes, "\\n", "\n")

    local skipId = activityCfg.Params[1]
    CsXUiHelper.RegisterClickEvent(self.BtnGo, function()
        if not XMVCA.XSubPackage:CheckSubpackage() then
            return
        end
        XFunctionManager.SkipInterface(skipId)
    end, true, true)
end

return XUiPanelSkip
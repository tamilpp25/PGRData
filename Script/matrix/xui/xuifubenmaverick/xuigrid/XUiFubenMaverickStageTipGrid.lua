local XUiFubenMaverickStageTipGrid = XClass(nil, "XUiFubenMaverickStageTipGrid")

function XUiFubenMaverickStageTipGrid:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiFubenMaverickStageTipGrid:Refresh(tip)
    self.TxtTip.text = tip
end

return XUiFubenMaverickStageTipGrid
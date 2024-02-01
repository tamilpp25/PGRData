local XUiGridKotodamaTask=XClass(XDynamicGridTask,'XUiGridKotodamaTask')

function XUiGridKotodamaTask:Ctor()
    self.BtnReceiveHave = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/BtnReceiveHave", nil)
end

function XUiGridKotodamaTask:SetRoot(root)
    self.Parent=root
end

function XUiGridKotodamaTask:OpenUiObtain(data)
    XUiManager.OpenUiObtain(data,nil,function()
    self.Parent:RefreshTaskList()
    end)
end

return XUiGridKotodamaTask
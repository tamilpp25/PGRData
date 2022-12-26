local XChessPursuitModel = XClass(nil, "XChessPursuitModel")

function XChessPursuitModel:AddClick(func)
    --避免重复注册
    if self.Func then
       return 
    end

    self.Func = func
    self.CSXChessPursuitModel:AddPointerClickListener(function() 
        func() 
    end)
end

function XChessPursuitModel:GetCSXChessPursuitModel()
    return self.CSXChessPursuitModel
end

-- 设置半透明+高亮，并且不可点击
function XChessPursuitModel:SetTransparent()
    if self.GameObject then
        self.CSXChessPursuitModel:SetTransparent(0.5)
        self.CSXChessPursuitModel:EnableClick(false)
    end
end

function XChessPursuitModel:HighLight()
    if self.GameObject then
        self.CSXChessPursuitModel:HighLight()
        self.CSXChessPursuitModel:EnableClick(true)
    end
end

function XChessPursuitModel:EnableClick()
    if self.GameObject then
        self.CSXChessPursuitModel:Revert()
        self.CSXChessPursuitModel:EnableClick(true)
    end
end

function XChessPursuitModel:None()
    if self.GameObject then
        self.CSXChessPursuitModel:Revert()
        self.CSXChessPursuitModel:EnableClick(false)
    end
end

function XChessPursuitModel:Default()
    if self.GameObject then
        self.CSXChessPursuitModel:Revert()
        self.CSXChessPursuitModel:EnableClick(true)
    end
end

return XChessPursuitModel
local XUiGridTemplateDetail = XClass(nil, "XUiGridTemplateDetail")

function XUiGridTemplateDetail:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridTemplateDetail:Init(rootUi)
    self.RootUi = rootUi
end

function XUiGridTemplateDetail:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridTemplateDetail:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridTemplateDetail:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridTemplateDetail:AutoAddListener()
    self:RegisterClickEvent(self.BtnClick, self.OnBtnClick)
end

function XUiGridTemplateDetail:OnBtnClick()
    self.RootUi:OpenRefitQuick(self.Frunitrue)
end

function XUiGridTemplateDetail:Refresh(frunitrue)
    self.Frunitrue = frunitrue
    local furnitureCfg = XFurnitureConfigs.GetFurnitureTemplateById(self.Frunitrue.ConfigId)
    self.TxtName.text = furnitureCfg.Name
    self.RImgIcon:SetRawImage(furnitureCfg.Icon)

    if frunitrue.ConnectDormId > 0 then
        if self.Frunitrue.Count > self.Frunitrue.TargetCount then
            self.TxtNum.text = CS.XTextManager.GetText("DormTemplateCountNotEnough", self.Frunitrue.TargetCount, self.Frunitrue.Count)
        else
            self.TxtNum.text = CS.XTextManager.GetText("DormTemplateCountEnough", self.Frunitrue.TargetCount, self.Frunitrue.Count)
        end

        self.PanelComplete.gameObject:SetActiveEx(self.Frunitrue.Count <= self.Frunitrue.TargetCount)
    else
        self.TxtNum.text = tostring(self.Frunitrue.Count)
        self.PanelComplete.gameObject:SetActiveEx(false)
    end
end

return XUiGridTemplateDetail
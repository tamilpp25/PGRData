XUiGridStageStar = XClass(nil, "XUiGridStageStar")

function XUiGridStageStar:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:InitAutoScript()
end

function XUiGridStageStar:Refresh(desc, active, descEventId)
    self.TxtUnActive.text = desc
    self.TxtActive.text = desc
    local isDescNotEmpty = desc == nil or desc == ""
    if isDescNotEmpty then
        self.PanelUnActive.gameObject:SetActive(false)
        self.PanelActive.gameObject:SetActive(false)
    else
        self.PanelUnActive.gameObject:SetActive(not active)
        self.PanelActive.gameObject:SetActive(active)
    end
    
    if XTool.IsNumberValid(descEventId) then
        local isUnlockEventId = XDataCenter.FubenManager.GetUnlockHideStageById(descEventId)
        if not isUnlockEventId then
            self.TxtUnActive.text = "???"
            self.PanelUnActive.gameObject:SetActive(true)
            self.PanelActive.gameObject:SetActive(false)
        end
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiGridStageStar:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiGridStageStar:AutoInitUi()
    self.PanelUnActive = self.Transform:Find("PanelUnActive")
    self.TxtUnActive = self.Transform:Find("PanelUnActive/TxtUnActive"):GetComponent("Text")
    self.PanelActive = self.Transform:Find("PanelActive")
    self.TxtActive = self.Transform:Find("PanelActive/TxtActive"):GetComponent("Text")
end

function XUiGridStageStar:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridStageStar:RegisterClickEvent函数错误, 参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridStageStar:RegisterClickEvent函数错误, 参数func需要是function类型")
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridStageStar:AutoAddListener()
end
-- auto
return XUiGridStageStar
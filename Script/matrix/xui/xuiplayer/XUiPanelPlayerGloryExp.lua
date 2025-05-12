local XUiPanelPlayerGloryExp = XClass(nil, "XUiPanelPlayerGloryExp")

function XUiPanelPlayerGloryExp:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:InitAutoScript()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelPlayerGloryExp:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPanelPlayerGloryExp:AutoInitUi()
    self.ImgExpCircle = self.Transform:Find("ImgExpCircle"):GetComponent("Image")
    self.ImgExpCircleFill1 = self.Transform:Find("ImgExpCircle/ImgExpCircleFill1"):GetComponent("Image")
    self.ImgExpCircleFill2 = self.Transform:Find("ImgExpCircle/ImgExpCircleFill2"):GetComponent("Image")
    self.ImgExpCircleFill3 = self.Transform:Find("ImgExpCircle/ImgExpCircleFill3"):GetComponent("Image")
    self.TxtLevelNum = self.Transform:Find("TxtLevelNum"):GetComponent("Text")
    self.TxtExpNum = self.Transform:Find("PanelExp/TxtExpNum"):GetComponent("Text")
end

function XUiPanelPlayerGloryExp:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelPlayerGloryExp:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelPlayerGloryExp:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelPlayerGloryExp:AutoAddListener()
end
-- auto

function XUiPanelPlayerGloryExp:UpdatePlayerLevelInfo()
    local curExp = XPlayer.Exp
    local maxExp= XPlayer.GetMaxExp()
    local fillAmount = curExp / maxExp
    XUiHelper.Tween(1, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end

        local fill = math.floor(f * curExp)

        self.ImgExpCircleFill1.fillAmount = fill / maxExp
        self.ImgExpCircleFill2.fillAmount = fill / maxExp
        self.ImgExpCircleFill3.fillAmount = fill / maxExp
    end)

    self.ImgExpCircle.fillAmount = 1.0-fillAmount
    self.TxtLevelNum.text = XPlayer.GetHonorLevel()
    self.TxtExpNum.text = "<color=#0e70bd><size=47>" .. curExp .. "</size></color>" .. "/" ..maxExp
end

return XUiPanelPlayerGloryExp
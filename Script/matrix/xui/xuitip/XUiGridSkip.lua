XUiGridSkip = XClass(nil, "XUiGridSkip")

function XUiGridSkip:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self:InitAutoScript()
end

function XUiGridSkip:InitAutoScript()
    XTool.InitUiObject(self)
    self.BtnSkip.CallBack = function()
        XFunctionManager.SkipInterface(self.SkipId, self.Args)
        if self.SkipCb then
            self.SkipCb()
        end
    end
end

function XUiGridSkip:Refresh(skipId, hideSkipBtn, skipCb, ...)
    if not skipId then
        self.GameObject:SetActive(false)
        return
    end
    self.GameObject:SetActive(true)

    self.SkipId = skipId
    self.SkipCb = skipCb
    self.Args = {...}

    local canSkip = XFunctionManager.IsCanSkip(skipId)
    local template = XFunctionConfig.GetSkipList(skipId)
    self.TxtNameOn.text = template.Explain
    if hideSkipBtn then
        self.BtnSkip.gameObject:SetActive(false)
    else
        self.BtnSkip.gameObject:SetActive(true)
        self.BtnSkip:SetDisable(not canSkip)
    end
end
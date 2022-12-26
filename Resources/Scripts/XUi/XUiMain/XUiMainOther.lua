local XUiPanelSignBoard = require("XUi/XUiMain/XUiChildView/XUiPanelSignBoard")

XUiMainOther = XClass(nil, "XUiMainOther")

function XUiMainOther:Ctor(rootUi)
    self.Transform = rootUi.PanelOther.gameObject.transform
    XTool.InitUiObject(self)
    self.RootUi = rootUi
    self.SignBoard = XUiPanelSignBoard.New(self.PanelSignBoard, self.RootUi, XUiPanelSignBoard.SignBoardOpenType.MAIN)

    --ClickEvent
    self.BtnScreenShot.CallBack = function() self:OnBtnScreenShot() end
    --RedPoint
end

function XUiMainOther:OnEnable()
    self.BtnScreenShot.gameObject:SetActiveEx(not XUiManager.IsHideFunc)

    if self.SignBoard then
        local displayCharacterId = XDataCenter.DisplayManager.GetDisplayChar().Id
        self.SignBoard:SetDisplayCharacterId(displayCharacterId)
        self.SignBoard:OnEnable()
    end
end

function XUiMainOther:OnDisable()
    if self.SignBoard then
        self.SignBoard:OnDisable()
    end
end

function XUiMainOther:OnDestroy()
    if self.SignBoard then
        self.SignBoard:OnDestroy()
    end
end

--拍照分享按钮
function XUiMainOther:OnBtnScreenShot()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Photograph) then
        XLuaUiManager.Open("UiPhotograph")
    end
end
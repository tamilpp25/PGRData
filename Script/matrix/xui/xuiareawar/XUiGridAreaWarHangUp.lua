local XUiGridAreaWarHangUp = XClass(nil, "XUiGridAreaWarHangUp")

function XUiGridAreaWarHangUp:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    if self.BtnClick then
        self.BtnClick.CallBack = clickCb
    end

    self.ImgJiantou = self.Transform:FindTransform("ImgJiantou")
end

function XUiGridAreaWarHangUp:Refresh(id, curLevel)
    self.TxtLevel.text = id

    local isReach = curLevel >= id
    self.PanelReach.gameObject:SetActiveEx(isReach)
    self.PanelUnReach.gameObject:SetActiveEx(not isReach)

    local amount = XAreaWarConfigs.GetHangUpUnlockAmount(id)
    self.TxtCount.text = amount .. "/h"

    if self.RImgIcon then
        self.RImgIcon:SetRawImage(XDataCenter.AreaWarManager.GetCoinItemIcon())
    end

    self.ImgJiantou.gameObject:SetActiveEx(curLevel == id)
end

return XUiGridAreaWarHangUp

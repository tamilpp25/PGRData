local XUiGridAreaWarHangUp = XClass(nil, "XUiGridAreaWarHangUp")

function XUiGridAreaWarHangUp:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    if self.BtnClick then
        self.BtnClick.CallBack = clickCb
    end

end

function XUiGridAreaWarHangUp:Refresh(id, curLevel)
    local level = string.format("%2d", id)
    self.TxtLevelN.text = level
    self.TxtLevelS.text = level

    local isReach = curLevel >= id
    self.Normal.gameObject:SetActiveEx(not isReach)
    self.Select.gameObject:SetActiveEx(isReach)

    local amount = XAreaWarConfigs.GetHangUpUnlockAmount(id)
    self.TxtCount.text = amount .. "/h"

    if self.RImgIcon then
        self.RImgIcon:SetRawImage(XDataCenter.AreaWarManager.GetCoinItemIcon())
    end
end

return XUiGridAreaWarHangUp

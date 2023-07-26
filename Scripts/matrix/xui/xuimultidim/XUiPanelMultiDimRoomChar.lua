local XUiPanelMultiDimRoomChar = XClass(nil, "XUiPanelMultiDimRoomChar")

---@param transform UnityEngine.RectTransform
function XUiPanelMultiDimRoomChar:Ctor(transform,career,index)
    self.Transform = transform
    self.GameObject = transform.gameObject
    self.Index = index
    XTool.InitUiObject(self)
    self.BtnSwitch.CallBack = function() 
        self:OnClickBtnSwitch()
    end
end

function XUiPanelMultiDimRoomChar:Refresh(career)
    self.Career = career
    local icon = XMultiDimConfig.GetMultiDimCareerIcon(self.Career)
    local name = XMultiDimConfig.GetMultiDimCareerName(self.Career)
    self.RImgIcon:SetRawImage(icon)
    self.TxtType.text = name
end

function XUiPanelMultiDimRoomChar:OnClickBtnSwitch()
    if self:IsLeader() then
        XLuaUiManager.Open("UiMultiDimSwitchTypeTip", self.Career, self.Index, function(career)
            self:Refresh(career)
        end)
    end
end

function XUiPanelMultiDimRoomChar:IsLeader()
    local roomData = XDataCenter.RoomManager.RoomData
    for _, v in pairs(roomData.PlayerDataList) do
        if v.Leader and v.Id == XPlayer.Id then
            return true
        end
    end
    return false
end

return XUiPanelMultiDimRoomChar